import { randomUUID } from "node:crypto";
import { tmpdir } from "node:os";
import { constants } from "node:fs";
import { open, realpath, stat, unlink } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { FileHandle } from "node:fs/promises";
import { scanWritableRoot, LaunchPreflightError } from "./launch_preflight.js";
import { checkFolder, type LaunchProject } from "./launch_store.js";

export interface SandboxPlan { command: string; args: string[]; env: NodeJS.ProcessEnv; fds: number[]; close(): Promise<void> }
/** Entire Pi runs inside a private mount/PID/user namespace. Network is deliberately
 * shared for model/Relay access: this is filesystem isolation, not a network policy. */
export async function launchSandbox(project: LaunchProject, extension: string, piArgs: string[], name: string): Promise<SandboxPlan> {
  if (process.platform !== "linux") throw new Error("Secure launching requires Linux bubblewrap");
  await checkFolder(project.cwd);
  const handles: FileHandle[] = [];
  const budget = { entries: 0, deadline: Date.now() + 5000 };
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(process.env.HOME ?? "", ".pi", "agent");
  const args = ["--die-with-parent", "--new-session", "--unshare-user", "--disable-userns", "--unshare-pid", "--unshare-ipc", "--unshare-uts", "--cap-drop", "ALL", "--proc", "/proc", "--dev", "/dev", "--tmpfs", "/tmp", "--tmpfs", "/home", "--dir", "/home/pi", "--dir", "/home/pi/.pi", "--dir", "/home/pi/.pi/agent"];
  const pin = async (path: string, destination: string, writable: boolean) => {
    const fd = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW);
    handles.push(fd);
    args.push(writable ? "--bind" : "--ro-bind", `/proc/self/fd/${handles.length + 3}`, destination);
    return fd;
  };
  try {
    for (const path of ["/usr", "/bin", "/lib", "/lib64", "/etc/ssl", "/etc/resolv.conf", "/etc/hosts", "/etc/nsswitch.conf"]) {
      try { const canonical = await realpath(path); await pin(canonical, path, false); } catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
    }
    const node = await realpath(process.execPath);
    await pin(node, node, false);
    const piEntry = fileURLToPath(import.meta.resolve("@earendil-works/pi-coding-agent"));
    // Installed package tree and this extension's dependency tree are explicit runtime RO allowances.
    const piRoot = resolve(dirname(piEntry), "..");
    const extensionRoot = resolve(dirname(extension), "..");
    const dependencies = await realpath(join(extensionRoot, "node_modules"));
    await pin(piRoot, piRoot, false);
    await pin(extensionRoot, extensionRoot, false);
    await pin(dependencies, dependencies, false);
    for (const folder of project.folders) {
      await checkFolder(folder);
      if ([piRoot, extensionRoot, dependencies, dirname(node), "/home/pi", resolve(agentDir)].some(p => folder.path === p || folder.path.startsWith(p + "/") || p.startsWith(folder.path + "/"))) throw new Error("Project overlaps protected runtime");
      const fd = await pin(folder.path, folder.path, true);
      const s = await fd.stat({ bigint: true });
      if (String(s.dev) !== folder.dev || String(s.ino) !== folder.ino) throw new Error("Registered directory changed during launch");
      await checkFolder(folder);
      await scanWritableRoot(fd, folder.path, 100_000, 5000, budget);
    }
    // Pin the exact cwd as well, even when it is below an allowed root.
    const cwdFd = await pin(project.cwd.path, project.cwd.path, true);
    const cwdStat = await cwdFd.stat({ bigint: true });
    if (String(cwdStat.dev) !== project.cwd.dev || String(cwdStat.ino) !== project.cwd.ino) throw new Error("Registered project was replaced");
    await checkFolder(project.cwd);
    // Credentials are copied through a read-only descriptor into private tmpfs,
    // never mount host HOME or remote identity, settings, history, or sockets.
    try {
      const source = await open(join(agentDir, "auth.json"), constants.O_RDONLY | constants.O_NOFOLLOW);
      let credentials: Record<string, unknown>;
      try {
        const s = await source.stat();
        if (!s.isFile() || s.size > 131072 || s.uid !== process.getuid?.() || (s.mode & 0o077) !== 0) throw new Error("Model credentials must be a private 0600 file");
        credentials = JSON.parse(await source.readFile("utf8")) as Record<string, unknown>;
        if (!credentials || typeof credentials !== "object" || Array.isArray(credentials)) throw new Error("Invalid model credentials");
      } finally { await source.close(); }
      let defaults: { defaultProvider?: string; defaultModel?: string } = {};
      try {
        const settings = await open(join(agentDir, "settings.json"), constants.O_RDONLY | constants.O_NOFOLLOW);
        try {
          if ((await settings.stat()).size > 131072) throw new Error("Model settings too large");
          const value = JSON.parse(await settings.readFile("utf8")) as Record<string, unknown>;
          if (typeof value.defaultProvider === "string" && /^[a-z0-9_-]{1,128}$/.test(value.defaultProvider)) defaults.defaultProvider = value.defaultProvider;
          if (typeof value.defaultModel === "string" && value.defaultModel.length <= 256 && !/[\x00-\x1f]/.test(value.defaultModel)) defaults.defaultModel = value.defaultModel;
        } finally { await settings.close(); }
      } catch (error) { if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error; }
      const providers = Object.keys(credentials).filter(p => /^[a-z0-9_-]{1,128}$/.test(p)).sort();
      const provider = defaults.defaultProvider ?? providers[0];
      if (!provider || !credentials[provider] || typeof credentials[provider] !== "object") throw new LaunchPreflightError("Configure stored credentials for the selected model provider locally");
      const credential = credentials[provider] as Record<string, unknown>;
      if (credential.type === "api_key" ? typeof credential.key !== "string" || !credential.key || credential.key.startsWith("!") : credential.type !== "oauth" || typeof credential.access !== "string" || !credential.access || typeof credential.refresh !== "string") throw new LaunchPreflightError("Secure launch requires a stored literal API key or OAuth credential; host credential commands are not exposed");
      defaults = { defaultProvider: provider, ...(defaults.defaultModel ? { defaultModel: defaults.defaultModel } : {}) };
      const copiedFile = async (data: unknown, destination: string) => {
        const path = join(tmpdir(), "remote-pi-launch-" + randomUUID());
        const fd = await open(path, "wx+", 0o600);
        try {
          await unlink(path); // No named file ever contains credential plaintext.
          const bytes = Buffer.from(JSON.stringify(data));
          try { await fd.write(bytes, 0, bytes.length, 0); } finally { bytes.fill(0); }
          handles.push(fd);
          args.push("--perms", "0600", "--file", String(handles.length + 3), destination);
        } catch (error) { await fd.close(); await unlink(path).catch(() => {}); throw error; }
      };
      await copiedFile({ [provider]: credentials[provider] }, "/home/pi/.pi/agent/auth.json");
      await copiedFile(defaults, "/home/pi/.pi/agent/settings.json");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") throw new LaunchPreflightError("Configure a stored Pi model credential locally before launching (auth.json); environment-only credentials are not exposed");
      throw error;
    }
    const cli = join(piRoot, "dist", "cli.js");
    await stat(cli);
    args.push("--chdir", project.cwd.path, "--", node, "--import", join(extensionRoot, "dist", "session", "managed_preload.js"), cli, ...piArgs, "--no-approve", "--no-extensions", "--no-skills", "--no-prompt-templates", "--no-themes", "--session-dir", "/home/pi/.pi/agent/sessions");
    // No inherited parent secrets/config/worker identities. Provider credentials
    // from auth.json remain exposed to this sandbox's project code, by design.
    const env: NodeJS.ProcessEnv = { HOME: "/home/pi", PATH: "/usr/bin:/bin", LANG: "C.UTF-8", PI_CODING_AGENT_DIR: "/home/pi/.pi/agent", PI_SKIP_VERSION_CHECK: "1", PI_OFFLINE: "1", PI_TELEMETRY: "0", REMOTE_PI_DAEMON: "1", REMOTE_PI_MANAGED_CHILD: "1", REMOTE_PI_SANDBOX_CHILD: "1", REMOTE_PI_DIRECT_CONFIG: JSON.stringify({ agent_name: name, auto_start_relay: false }) };
    return { command: "/bin/bwrap", args, env, fds: handles.map(f => f.fd), close: async () => { await Promise.all(handles.map(f => f.close())); } };
  } catch (error) { await Promise.all(handles.map(f => f.close())); throw error; }
}

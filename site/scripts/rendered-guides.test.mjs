import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { repositoryUrl } from "../src/lib/repository-guides.mjs";

// Run after pnpm build, with the same NEXT_PUBLIC_REPOSITORY_URL used to build.
const output = resolve(dirname(fileURLToPath(import.meta.url)), "../.next/server/app");
const repository = repositoryUrl(process.env.NEXT_PUBLIC_REPOSITORY_URL);
const routes = ["docs", "remote-pi/docs", "remote-pi/tutorials/getting-started",
  "remote-pi/tutorials/mesh-local", "remote-pi/tutorials/mesh-remote",
  "remote-pi/tutorials/daemon", "remote-pi/tutorials/claude-mesh",
  "tutorials/cockpit-layouts", "tutorials/cockpit-team", "tutorials/cockpit-telemetry"];

for (const route of routes) {
  test(`prerendered canonical navigation: /${route}`, () => {
    const html = readFileSync(resolve(output, `${route}.html`), "utf8");
    // Only visible HTML, not RSC hydration data.
    const visible = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, "");
    const links = [...visible.matchAll(/href="([^"]*\/blob\/[^\"]*)"/g)].map((m) => m[1]);
    assert.doesNotMatch(visible, /npm:remote-pi|npm install -g remote-pi|curl -fsSL/);
    assert.match(visible, /License: MIT/);
    if (repository) {
      assert.ok(links.length > 0);
      for (const href of links) assert.ok(href.startsWith(`${repository}/blob/HEAD/`), href);
      assert.doesNotMatch(visible, /Repository guides unavailable|aria-disabled="true"/);
    } else {
      assert.equal(links.length, 0);
      assert.match(visible, /Repository guides unavailable/);
      assert.match(visible, /role="link" aria-disabled="true"/);
    }
  });
}

test("retained legal reference prominently distinguishes upstream operator", () => {
  for (const route of ["terms", "privacy"]) {
    const html = readFileSync(resolve(output, `${route}.html`), "utf8");
    assert.match(html, /Upstream reference only/);
    assert.match(html, /original Flutterando service/);
    assert.match(html, /33\.637\.582\/0001-70/);
  }
});

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/routing/adaptive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'viewmodels/agents_viewmodel.dart';

class AgentsTarget {
  const AgentsTarget(this.peer, this.room, this.host, this.session);
  final String peer, room, host, session;
}

class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key, required this.target});
  final AgentsTarget target;
  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

enum _LauncherAction { agents, lock }

class _AgentsPageState extends State<AgentsPage> with WidgetsBindingObserver {
  final _pin = TextEditingController();
  String? _selected, _identity, _projectDefinition;
  ({String id, String identity, String definition})? _selectionCandidate;
  bool _confirming = false, _targetChanged = false;

  String _definition(LauncherProject project) =>
      '${project.projectId}:${project.name}:${project.cwd}:${project.allowedFolders.join('\u0000')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AgentsViewModel>().initialize(
          widget.target.peer,
          widget.target.room,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pin.clear();
  }

  @override
  void didUpdateWidget(covariant AgentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.peer != widget.target.peer ||
        oldWidget.target.room != widget.target.room) {
      _pin.clear();
      _selected = null;
      _selectionCandidate = null;
      _targetChanged = true;
      final vm = context.read<AgentsViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.rejectTargetChange();
      });
    }
  }

  Future<void> _unlock(AgentsViewModel vm) async {
    if (vm.state.busy || vm.state.invalid || _targetChanged) return;
    final pin = _pin.text;
    _pin.clear();
    await vm.unlock(pin);
  }

  Future<void> _confirm({ManagedAgent? stop}) async {
    if (!mounted || _confirming || _targetChanged) return;
    final vm = context.read<AgentsViewModel>();
    if (!vm.unlocked || vm.state.invalid || vm.state.busy) return;
    final projectId = _selected;
    final projects = vm.projects.where((p) => p.projectId == projectId);
    final project = projects.firstOrNull;
    if (stop == null && project == null) return;
    final identity = _identity, definition = _projectDefinition;
    final launcherId = vm.security?.launcherId, epoch = vm.security?.epoch;
    final warnedUnknown = vm.hasUnknownLaunch;
    final extraFolders =
        project?.allowedFolders.where((path) => path != project.cwd).toList() ??
        const <String>[];
    setState(() => _confirming = true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(stop == null ? 'Start agent?' : 'Stop agent?'),
        content: Text(
          stop == null
              ? '${warnedUnknown ? 'Earlier start unconfirmed. Starting another may create a second agent.\n\n' : ''}${widget.target.host} · ${project!.name}\n${project.cwd}${extraFolders.isEmpty ? '' : '\nAccess: ${extraFolders.join(', ')}'}\n\nStops when this launcher closes or reloads.'
              : '${stop.name}\nStops this agent only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(stop == null ? 'Start' : 'Stop'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (ok != true ||
        _targetChanged ||
        identity != _identity ||
        vm.security?.launcherId != launcherId ||
        vm.security?.epoch != epoch) {
      return;
    }
    if (stop != null) {
      await vm.stop(stop.agentId, confirmed: true);
      return;
    }
    if (definition != _projectDefinition || _selected != projectId) return;
    final agent = await vm.launch(
      projectId!,
      null,
      confirmed: true,
      acknowledgeUnknown: warnedUnknown,
    );
    if (!mounted || agent == null) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.read<SessionSelection>().clear();
      router.go('/home');
    }
  }

  void _showAgents(AgentsViewModel vm) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<AgentsViewModel>.value(
          value: vm,
          child: _RunningAgentsPage(
            host: widget.target.host,
            onStop: (agent) => _confirm(stop: agent),
          ),
        ),
      ),
    );
  }

  void _reconcileSelection(AgentsViewModel vm, String identity) {
    final state = vm.state;
    if (vm.reconcilingSelection && !state.invalid && !_targetChanged) {
      if (_selected != null &&
          _identity != null &&
          _projectDefinition != null) {
        _selectionCandidate = (
          id: _selected!,
          identity: _identity!,
          definition: _projectDefinition!,
        );
      }
      _selected = null;
      _pin.clear();
    } else {
      final candidate = _selectionCandidate;
      _selectionCandidate = null;
      if (candidate != null &&
          !state.invalid &&
          !state.needsReconciliation &&
          !_targetChanged &&
          vm.unlocked &&
          candidate.identity == identity &&
          vm.projects.any(
            (p) =>
                p.projectId == candidate.id &&
                _definition(p) == candidate.definition,
          )) {
        _selected = candidate.id;
        _projectDefinition = candidate.definition;
        _identity = identity;
      }
      if (_identity != identity ||
          _selected != null &&
              !vm.projects.any(
                (p) =>
                    p.projectId == _selected &&
                    _definition(p) == _projectDefinition,
              )) {
        _selected = null;
        _pin.clear();
      }
    }
    _identity = identity;
    if (state.invalid) _pin.clear();
  }

  Widget _retry(AgentsViewModel vm) => FilledButton(
    onPressed: vm.state.busy || vm.state.invalid || _targetChanged
        ? null
        : vm.refresh,
    child: const Text('Retry'),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgentsViewModel>();
    final identity =
        '${widget.target.peer}:${widget.target.room}:${vm.security?.launcherId}:${vm.security?.epoch}';
    _reconcileSelection(vm, identity);
    final state = vm.state;
    final disabled =
        state.busy || state.invalid || _confirming || _targetChanged;
    final agents =
        vm.state.availability?.agents
            .where((a) => a.state != 'stopped')
            .toList() ??
        const <ManagedAgent>[];
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        title: const Text('Start agent'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: disabled ? null : vm.refresh,
            icon: const Icon(Icons.refresh),
          ),
          if (vm.unlocked && !state.invalid)
            PopupMenuButton<_LauncherAction>(
              tooltip: 'Agent options',
              enabled: !disabled,
              onSelected: (action) {
                switch (action) {
                  case _LauncherAction.agents:
                    _showAgents(vm);
                  case _LauncherAction.lock:
                    _pin.clear();
                    vm.lock();
                }
              },
              itemBuilder: (_) => [
                if (agents.isNotEmpty)
                  const PopupMenuItem(
                    value: _LauncherAction.agents,
                    child: Text('Started here'),
                  ),
                const PopupMenuItem(
                  value: _LauncherAction.lock,
                  child: Text('Lock access'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Text('Host: ${widget.target.host}', style: context.typo.sansBody),
            ..._content(vm, disabled, agents),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    AgentsViewModel vm,
    bool disabled,
    List<ManagedAgent> agents,
  ) {
    final state = vm.state, security = vm.security;
    if (state.busy) return [const LinearProgressIndicator()];
    if (state.invalid || _targetChanged) {
      return [Text(state.message ?? 'Host changed. Reopen the launcher.')];
    }
    if (security == null) {
      return [Text(state.message ?? 'Host unavailable.'), _retry(vm)];
    }
    if (!security.configured) {
      return [
        Text('Host setup required', style: context.typo.sansBody),
        const Text('Create a PIN on the PC, then retry.'),
        FilledButton.icon(
          key: const Key('copy-launcher-setup'),
          onPressed: () => Clipboard.setData(
            const ClipboardData(text: 'remote-pi-launcher pin-setup'),
          ),
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy setup command'),
        ),
        TextButton(onPressed: vm.refresh, child: const Text('Check again')),
      ];
    }
    if (!vm.unlocked) {
      final cooldown =
          security.cooldownUntil > DateTime.now().millisecondsSinceEpoch;
      return [
        if (state.message != null) Text(state.message!),
        if (cooldown && state.message == null)
          const Text('Too many attempts. Try again shortly.'),
        TextField(
          key: const Key('launcher-pin'),
          controller: _pin,
          enabled: !disabled,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 12,
          decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (!cooldown) _unlock(vm);
          },
        ),
        FilledButton(
          onPressed: disabled || cooldown || _pin.text.isEmpty
              ? null
              : () => _unlock(vm),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.tap),
          ),
          child: const Text('Unlock'),
        ),
      ];
    }
    final availability = state.availability;
    if (availability?.available != true) {
      return [
        Text(state.message ?? availability?.reason ?? 'Launching unavailable.'),
        _retry(vm),
      ];
    }
    if (vm.projects.isEmpty) {
      return [const Text('No approved projects on this PC.'), _retry(vm)];
    }
    final full =
        agents
            .where((a) => a.state == 'running' || a.state == 'starting')
            .length >=
        availability!.maxAgents;
    return [
      if (state.message != null) Text(state.message!),
      RadioGroup<String>(
        groupValue: _selected,
        onChanged: (value) {
          if (disabled) return;
          setState(() {
            _selected = value;
            _projectDefinition = value == null
                ? null
                : _definition(
                    vm.projects.firstWhere((p) => p.projectId == value),
                  );
          });
        },
        child: Column(
          children: [
            for (final project in vm.projects)
              RadioListTile<String>(
                key: ValueKey('launch-project-${project.projectId}'),
                value: project.projectId,
                enabled: !disabled,
                selected: _selected == project.projectId,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                title: Text(project.name),
                subtitle: Text(
                  project.cwd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.monoSmall.copyWith(
                    color: context.colors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
      if (vm.hasUnknownLaunch)
        const Text(
          'Previous start unconfirmed. Retrying may create another agent.',
        ),
      if (full) ...[
        const Text('Agent limit reached.'),
        FilledButton(
          onPressed: disabled ? null : () => _showAgents(vm),
          child: const Text('View agents'),
        ),
      ] else
        FilledButton(
          key: const Key('launch-agent'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.tap),
          ),
          onPressed: disabled || _selected == null || state.needsReconciliation
              ? null
              : () => _confirm(),
          child: const Text('Start agent'),
        ),
    ];
  }
}

class _RunningAgentsPage extends StatelessWidget {
  const _RunningAgentsPage({required this.host, required this.onStop});
  final String host;
  final ValueChanged<ManagedAgent> onStop;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgentsViewModel>();
    final agents =
        vm.state.availability?.agents
            .where((a) => a.state != 'stopped')
            .toList() ??
        const <ManagedAgent>[];
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(title: const Text('Started here')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(host, style: context.typo.monoSmall),
          if (vm.state.busy) const LinearProgressIndicator(),
          if (vm.state.invalid || !vm.unlocked)
            const Text('Unlock the host to manage agents.'),
          if (agents.isEmpty) const Text('No running agents.'),
          for (final agent in agents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                agent.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${agent.state}${agent.error == null ? '' : ': ${agent.error}'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: TextButton(
                onPressed: vm.state.busy || vm.state.invalid || !vm.unlocked
                    ? null
                    : () => onStop(agent),
                child: const Text('Stop'),
              ),
            ),
        ],
      ),
    );
  }
}

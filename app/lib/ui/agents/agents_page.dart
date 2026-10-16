import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/domain/contracts/agent_repository.dart';
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

class _AgentsPageState extends State<AgentsPage> with WidgetsBindingObserver {
  final _pin = TextEditingController(), _name = TextEditingController();
  String? _selected, _identity, _projectDefinition;
  ({String id, String identity, String definition})? _selectionCandidate;
  String _definition(LauncherProject project) =>
      '${project.projectId}:${project.name}:${project.cwd}:${project.allowedFolders.join('\u0000')}';
  bool _confirming = false, _targetChanged = false;
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
    _name.dispose();
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

  Future<void> _shutdown() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final vm = context.read<AgentsViewModel>();
    final identity = _identity;
    final launcherId = vm.security?.launcherId, epoch = vm.security?.epoch;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Stop all and lock?'),
        content: const Text(
          'Stops your managed agents; locks all launcher access. Other agents, OS and Relay stay running.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Shut down'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (ok == true &&
        !_targetChanged &&
        identity == _identity &&
        launcherId == vm.security?.launcherId &&
        epoch == vm.security?.epoch) {
      _pin.clear();
      await vm.lock(shutdown: true);
    }
  }

  Future<void> _confirm({String? id, String? name}) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final vm = context.read<AgentsViewModel>();
    final projectId = _selected ?? '', label = _name.text;
    final projects = vm.projects.where(
      (project) => project.projectId == projectId,
    );
    final directory = projects.isEmpty ? '' : projects.first.cwd;
    final identity = _identity;
    final launcherId = vm.security?.launcherId, epoch = vm.security?.epoch;
    final definition = _projectDefinition;
    final warnedUnknown = vm.hasUnknownLaunch;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(id == null ? 'Start agent?' : 'Stop $name?'),
        content: Text(
          id == null
              ? '${vm.hasUnknownLaunch ? 'Outcome unknown; it may still start/appear. Starting another may create a second agent.\n\n' : ''}Host: ${widget.target.host}\nSession: ${widget.target.session}\nDirectory: $directory\n\nOnly start in a project whose local code you trust. This fresh Pi process survives phone disconnects but stops when the launching Pi closes, or its session is replaced, resumed or reloaded. No initial prompt is sent.'
              : 'Stop this managed Pi process on ${widget.target.host}? Its session will no longer be online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(id == null ? 'Start' : 'Stop'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (_targetChanged ||
        identity != _identity ||
        vm.security?.launcherId != launcherId ||
        vm.security?.epoch != epoch) {
      return;
    }
    if (id == null) {
      if (identity != _identity ||
          definition != _projectDefinition ||
          _selected != projectId) {
        return;
      }
      await vm.launch(
        projectId,
        label.isEmpty ? null : label,
        confirmed: ok == true,
        acknowledgeUnknown: warnedUnknown,
      );
    } else {
      await vm.stop(id, confirmed: ok == true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgentsViewModel>(), colors = context.colors;
    final state = vm.state, availability = state.availability;
    final identity =
        '${widget.target.peer}:${widget.target.room}:${vm.security?.launcherId}:${vm.security?.epoch}';
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
      // Only a definition candidate survives: never selection authority or PIN.
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
    final disabled =
        state.busy || state.invalid || _confirming || _targetChanged;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: const Text('Start agent')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  'Host: ${widget.target.host}',
                  style: context.typo.sansBody,
                ),
                Text(
                  widget.target.session,
                  style: context.typo.monoSmall.copyWith(color: colors.muted),
                ),
              ],
            ),
            if (state.busy) const LinearProgressIndicator(),
            if (state.message != null)
              Text(state.message!, style: context.typo.sansBody),
            if (state.message == null && !state.busy)
              Text(
                vm.security == null
                    ? 'Host update required.'
                    : !vm.security!.configured
                    ? 'Set a PIN on the host.'
                    : vm.unlocked
                    ? 'Unlocked'
                    : 'Locked',
                style: context.typo.monoSmall.copyWith(color: colors.muted),
              ),
            if (availability?.available == false &&
                availability?.reason != null &&
                state.message == null)
              Text(
                availability!.reason!,
                style: context.typo.sansBody.copyWith(color: colors.error),
              ),
            if (availability?.available == true)
              Text(
                '${availability!.agents.where((a) => a.state == 'running' || a.state == 'starting').length}/${availability.maxAgents} agents',
                style: context.typo.monoSmall.copyWith(color: colors.muted),
              ),
            if ((vm.security?.cooldownUntil ?? 0) >
                DateTime.now().millisecondsSinceEpoch)
              Text('Too many attempts. Try later.'),
            if (!vm.unlocked) ...[
              TextField(
                controller: _pin,
                enabled: !disabled && vm.security?.configured == true,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 12,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  counterText: '',
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.tap),
                ),
                onPressed: disabled || vm.security?.configured != true
                    ? null
                    : () {
                        final pin = _pin.text;
                        _pin.clear();
                        vm.unlock(pin);
                      },
                child: const Text('Unlock'),
              ),
            ],
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selected,
              key: ValueKey(
                '$identity:$_selected:${vm.projects.map((p) => p.projectId).join(',')}',
              ),
              decoration: const InputDecoration(labelText: 'Project'),
              items: vm.projects
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.projectId,
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: disabled || !vm.unlocked
                  ? null
                  : (value) => setState(() {
                      _selected = value;
                      _projectDefinition = value == null
                          ? null
                          : _definition(
                              vm.projects.firstWhere(
                                (p) => p.projectId == value,
                              ),
                            );
                    }),
            ),
            for (final project in vm.projects.where(
              (p) => p.projectId == _selected,
            ))
              Text(
                'Directory: ${project.cwd}\nAllowed folders:\n${project.allowedFolders.join('\n')}',
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: disabled || vm.security == null
                      ? null
                      : () {
                          _pin.clear();
                          vm.lock();
                        },
                  child: const Text('Lock'),
                ),
                TextButton(
                  onPressed: disabled || vm.security == null ? null : _shutdown,
                  child: const Text('Stop all and lock'),
                ),
              ],
            ),
            TextField(
              controller: _name,
              enabled: !disabled,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.tap),
              ),
              onPressed:
                  disabled ||
                      !vm.unlocked ||
                      _selected == null ||
                      state.needsReconciliation ||
                      availability?.available != true
                  ? null
                  : () => _confirm(),
              child: const Text('Start agent'),
            ),
            TextButton(
              onPressed: disabled ? null : vm.refresh,
              child: const Text('Refresh'),
            ),
            if (vm.hasUnknownLaunch)
              const Text(
                'Launch unconfirmed. Refresh before retrying; retry may duplicate.',
              ),
            const Text('Managed agents'),
            for (final agent in availability?.agents ?? [])
              ListTile(
                title: Text(agent.name),
                subtitle: Text(
                  '${agent.cwd}\n${agent.state}${agent.error == null ? '' : ': ${agent.error}'}\nRoom: ${agent.roomId}',
                ),
                trailing:
                    agent.state == 'running' ||
                        agent.state == 'starting' ||
                        agent.state == 'failed'
                    ? TextButton(
                        onPressed: disabled || !vm.unlocked
                            ? null
                            : () =>
                                  _confirm(id: agent.agentId, name: agent.name),
                        child: const Text('Stop'),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

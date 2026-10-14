import 'package:flutter/material.dart';
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

class _AgentsPageState extends State<AgentsPage> {
  final _cwd = TextEditingController(), _name = TextEditingController();
  bool _hydrated = false, _confirming = false;
  @override
  void initState() {
    super.initState();
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
    _cwd.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirm({String? id, String? name}) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final vm = context.read<AgentsViewModel>();
    final cwd = _cwd.text, label = _name.text;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        scrollable: true,
        title: Text(id == null ? 'Start agent?' : 'Stop $name?'),
        content: Text(
          id == null
              ? 'Host: ${widget.target.host}\nSession: ${widget.target.session}\nDirectory: $cwd\n\nOnly start in a project whose local code you trust. This fresh Pi process survives phone disconnects but stops when the launching Pi closes, or its session is replaced, resumed or reloaded. No initial prompt is sent.'
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
    if (id == null) {
      await vm.launch(cwd, label.isEmpty ? null : label, confirmed: ok == true);
    } else {
      await vm.stop(id, confirmed: ok == true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgentsViewModel>(), colors = context.colors;
    final state = vm.state, availability = state.availability;
    if (!_hydrated && availability != null) {
      _hydrated = true;
      _cwd.text = availability.cwd;
    }
    final disabled = state.busy || state.invalid || _confirming;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: const Text('Start agent')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Host: ${widget.target.host}',
            style: TextStyle(color: colors.text),
          ),
          Text(
            'Session: ${widget.target.session}\nRoom: ${widget.target.room}',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 16),
          if (state.busy) const LinearProgressIndicator(),
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(state.message!),
            ),
          if (availability != null)
            Text(
              availability.available
                  ? 'Available · maximum ${availability.maxAgents} live agents'
                  : 'Unavailable: ${availability.reason ?? 'Launching disabled on this host'}',
            ),
          TextField(
            controller: _cwd,
            enabled: !disabled,
            decoration: const InputDecoration(
              labelText: 'Existing directory on host',
            ),
          ),
          TextField(
            controller: _name,
            enabled: !disabled,
            decoration: const InputDecoration(labelText: 'Name (optional)'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                disabled ||
                    state.needsReconciliation ||
                    availability?.available != true
                ? null
                : () => _confirm(),
            child: const Text('Start agent'),
          ),
          TextButton(
            onPressed: disabled ? null : vm.refresh,
            child: const Text('Refresh agents and discovery'),
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
                      onPressed: disabled
                          ? null
                          : () => _confirm(id: agent.agentId, name: agent.name),
                      child: const Text('Stop'),
                    )
                  : null,
            ),
          const Text(
            'New agents appear as regular sessions on Home. Return there to open the discovered online room.',
          ),
        ],
      ),
    );
  }
}

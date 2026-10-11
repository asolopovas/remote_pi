import 'package:app/pairing/storage.dart';
import 'package:app/protocol/protocol.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';

/// A row in the Home list.
///
/// Renders an inline presence dot (plano 12) driven by
/// [ConnectionManager.presenceStream]: green = online, grey = offline,
/// no dot = relay hasn't reported yet.
class SessionTile extends StatelessWidget {
  final PeerRecord peer;

  /// `true` when the room is announced live on the relay AND the
  /// relay itself is reachable. Drives the green dot.
  final bool isLive;

  /// `true` when the WS to the relay is currently retrying / down.
  /// Overrides `isLive` and renders an amber "reconnecting" dot —
  /// the app has no fresh signal on any room right now.
  final bool isReconnecting;

  /// Plan-18 follow-up — `true` when the agent in this room is
  /// currently producing a response. Highest-priority colour (blue).
  final bool isWorking;
  final RoomInfo? room;
  final VoidCallback onOpen;

  /// Plan/tablet — `true` when this is the session shown in the tablet's
  /// detail pane. Paints the accent left-bar + faint fill from the mock.
  /// Always `false` on phone (no persistent selection there).
  final bool isSelected;

  /// Plan-17 follow-up — long-press context menu. Caller wires the
  /// dialog (rename + delete-offline). Optional; when null the tile
  /// only responds to tap.
  final VoidCallback? onLongPress;

  const SessionTile({
    super.key,
    required this.peer,
    required this.isLive,
    required this.onOpen,
    this.room,
    this.isReconnecting = false,
    this.isWorking = false,
    this.isSelected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.bg,
      child: InkWell(
        onTap: onOpen,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accent.withValues(alpha: 0.06)
                : colors.bg,
            border: Border(
              left: BorderSide(
                color: isSelected ? colors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            // Trim the left inset by the 3px accent bar so content stays
            // aligned whether selected or not.
            padding: EdgeInsets.fromLTRB(isSelected ? 15 : 18, 14, 18, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(name: _avatarName()),
                const SizedBox(width: 14),
                Expanded(
                  child: _TitleBlock(
                    peer: peer,
                    room: room,
                    isLive: isLive,
                    isReconnecting: isReconnecting,
                    isWorking: isWorking,
                  ),
                ),
                _PresenceDot(
                  isLive: isLive,
                  isReconnecting: isReconnecting,
                  isWorking: isWorking,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _avatarName() {
    final r = room;
    if (r != null) {
      if (r.name != null && r.name!.isNotEmpty) return r.name!;
      final cwd = r.cwd;
      if (cwd != null && cwd.isNotEmpty) {
        return sessionProjectName(cwd) ?? cwd;
      }
    }
    if (peer.nickname?.isNotEmpty == true) return peer.nickname!;
    return peer.sessionName;
  }
}

class _PresenceDot extends StatelessWidget {
  final bool isLive;
  final bool isReconnecting;
  final bool isWorking;
  const _PresenceDot({
    required this.isLive,
    required this.isReconnecting,
    this.isWorking = false,
  });

  @override
  Widget build(BuildContext context) {
    // Plan-18 follow-up — 4-state dot. Priority high → low:
    //   working (agent streaming)   → blue
    //   reconnecting (relay down)   → amber
    //   live (relay up + announced) → green
    //   else (cached / offline)     → grey
    final colors = context.colors;
    final Color color = isWorking
        ? colors.working
        : isReconnecting
        ? colors.warning
        : isLive
        ? colors.success
        : colors.muted;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final PeerRecord peer;
  final RoomInfo? room;
  final bool isLive;
  final bool isReconnecting;
  final bool isWorking;
  const _TitleBlock({
    required this.peer,
    required this.room,
    required this.isLive,
    required this.isReconnecting,
    required this.isWorking,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = room;
    final path = r?.cwd;
    final project = sessionProjectName(path);
    final title = project ?? sessionFallbackName(r, peer);
    final status = isWorking
        ? 'Working'
        : isReconnecting
        ? 'Reconnecting'
        : isLive
        ? 'Online · idle'
        : 'Offline';
    final sessionContext = r?.name?.isNotEmpty == true
        ? '${r!.name} · ${r.roomId.length > 8 ? r.roomId.substring(0, 8) : r.roomId}'
        : r?.roomId ?? peer.sessionName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.text,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          path ?? 'Working directory unavailable',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.muted,
            fontSize: 11,
            fontFamily: kMonoFamily,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$sessionContext · $status${room?.model?.isNotEmpty == true ? ' · ${_truncateModel(room!.model!)}' : ''}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isWorking ? colors.working : colors.muted,
            fontSize: 11,
            fontFamily: kMonoFamily,
          ),
        ),
      ],
    );
  }
}

String? sessionProjectName(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final normalized = path
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'/+$'), '');
  if (normalized.isEmpty) return path;
  return normalized.split('/').last;
}

String sessionFallbackName(RoomInfo? room, PeerRecord peer) {
  if (room?.name?.isNotEmpty == true) return room!.name!;
  if (peer.nickname?.isNotEmpty == true) return peer.nickname!;
  if (peer.sessionName.isNotEmpty) return peer.sessionName;
  return room?.roomId ?? 'Session';
}

String _truncateModel(String name) =>
    name.length <= 24 ? name : '${name.substring(0, 21)}…';

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = _initial(name);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.accent,
          fontFamily: kMonoFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _initial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}

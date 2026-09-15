import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../models/group_session.dart';

class ParticipantsListWidget extends StatelessWidget {
  final List<GroupParticipant> participants;
  final String currentParticipantId;

  const ParticipantsListWidget({
    super.key,
    required this.participants,
    required this.currentParticipantId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Participants (${participants.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${participants.where((p) => p.isOnline).length} online',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF86EFAC) : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 56, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final p = participants[index];
              final isMe = p.id == currentParticipantId;

              final isReadyBg = p.isReady
                  ? (isDark ? const Color(0xFF143823) : Colors.green.shade50)
                  : (isDark ? const Color(0xFF3E2723) : Colors.orange.shade50);
              final isReadyBorder = p.isReady
                  ? (isDark ? const Color(0xFF1B5E20) : Colors.green.shade200)
                  : (isDark ? const Color(0xFF4E2600) : Colors.orange.shade200);
              final isReadyText = p.isReady
                  ? (isDark ? const Color(0xFF86EFAC) : Colors.green.shade900)
                  : (isDark ? const Color(0xFFFDBA74) : Colors.orange.shade900);

              return ListTile(
                dense: true,
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: p.isHost
                          ? (isDark ? const Color(0xFF4E2600) : Colors.orange.shade100)
                          : (isDark ? const Color(0xFF0D47A1).withValues(alpha: 0.4) : Colors.blue.shade100),
                      child: Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: p.isHost
                              ? (isDark ? const Color(0xFFFFB74D) : Colors.orange.shade900)
                              : (isDark ? const Color(0xFF90CAF9) : Colors.blue.shade900),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: p.isOnline ? Colors.green : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.cardColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(
                      p.displayName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isMe)
                      const Text(
                        ' (You)',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    if (p.isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4E2600) : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFFFB74D) : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReadyBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isReadyBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.isReady ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: 13,
                        color: isReadyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.isReady ? 'Ready' : 'Browsing',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isReadyText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

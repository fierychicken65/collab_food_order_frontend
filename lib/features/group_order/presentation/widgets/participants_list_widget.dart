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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${participants.where((p) => p.isOnline).length} online',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final p = participants[index];
              final isMe = p.id == currentParticipantId;

              return ListTile(
                dense: true,
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: p.isHost ? Colors.orange.shade100 : Colors.blue.shade100,
                      child: Text(
                        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: p.isHost ? Colors.orange.shade900 : Colors.blue.shade900,
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
                          color: p.isOnline ? Colors.green : Colors.grey.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '👑 HOST',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.isReady ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: p.isReady ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.isReady ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                        size: 13,
                        color: p.isReady ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.isReady ? 'Ready' : 'Browsing',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.isReady ? Colors.green.shade900 : Colors.orange.shade900,
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

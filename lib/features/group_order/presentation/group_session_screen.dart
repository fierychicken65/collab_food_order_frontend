import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/websocket/ws_client.dart';
import '../providers/group_session_provider.dart';
import 'widgets/participants_list_widget.dart';

class GroupSessionScreen extends ConsumerStatefulWidget {
  const GroupSessionScreen({super.key});

  @override
  ConsumerState<GroupSessionScreen> createState() => _GroupSessionScreenState();
}

class _GroupSessionScreenState extends ConsumerState<GroupSessionScreen> {
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join code "$code" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmLeaveSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group Session?'),
        content: const Text('Are you sure you want to disconnect from this shared session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              ref.read(groupSessionProvider.notifier).leaveSession();
              Navigator.of(ctx).pop(); // dismiss dialog
              Navigator.of(context).pop(); // back to home
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupSessionProvider);
    final wsClient = ref.read(wsClientProvider);

    if (groupState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Order')),
        body: const Center(
          child: Text('No active group session'),
        ),
      );
    }

    final session = groupState.session;
    final currentParticipant = groupState.currentParticipant;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeaveSession();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Order'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmLeaveSession,
          ),
          actions: [
            // Live WebSocket Connection Indicator
            StreamBuilder<WsConnectionStatus>(
              stream: wsClient.statusStream,
              initialData: wsClient.currentStatus,
              builder: (context, snapshot) {
                final status = snapshot.data ?? WsConnectionStatus.disconnected;
                Color dotColor;
                String statusText;

                switch (status) {
                  case WsConnectionStatus.connected:
                    dotColor = Colors.green;
                    statusText = 'Live';
                    break;
                  case WsConnectionStatus.connecting:
                    dotColor = Colors.orange;
                    statusText = 'Syncing...';
                    break;
                  case WsConnectionStatus.disconnected:
                    dotColor = Colors.red;
                    statusText = 'Offline';
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dotColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: dotColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Join Code Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF263238), Color(0xFF37474F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'SHARE JOIN CODE WITH FRIENDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          session.code,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                          tooltip: 'Copy Code',
                          onPressed: () => _copyCode(session.code),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Friends enter this code in "Join Group Session" to hop in!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live Participants List
              ParticipantsListWidget(
                participants: groupState.participants,
                currentParticipantId: currentParticipant.id,
              ),
              const SizedBox(height: 24),

              // Status Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${groupState.readyParticipantCount} of ${groupState.participants.length} Ready',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentParticipant.isHost
                                ? 'As Host, you can checkout once everyone is marked as Ready.'
                                : 'Add items to the shared cart and mark yourself Ready when done.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

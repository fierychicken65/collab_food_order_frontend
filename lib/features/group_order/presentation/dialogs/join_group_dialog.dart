import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../models/group_session.dart';
import '../../providers/group_session_provider.dart';
import '../group_session_screen.dart';

import '../../../user/providers/user_provider.dart';

class JoinGroupDialog extends ConsumerStatefulWidget {
  const JoinGroupDialog({super.key});

  @override
  ConsumerState<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends ConsumerState<JoinGroupDialog> {
  final _codeController = TextEditingController();
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final savedName = ref.read(userProvider).name;
    _nameController = TextEditingController(text: savedName);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    ref.read(userProvider.notifier).updateName(name);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(groupRepositoryProvider);
      final response = await repo.joinGroup(
        _codeController.text.trim().toUpperCase(),
        name,
      );

      final sessionData = response['session'] as Map<String, dynamic>;
      final participantData = response['participant'] as Map<String, dynamic>;

      final session = GroupSessionInfo.fromJson(sessionData);
      final participant = GroupParticipant.fromJson(participantData);

      ref.read(groupSessionProvider.notifier).initSession(
            session: session,
            currentParticipant: participant,
          );

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss dialog

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GroupSessionScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.login_rounded, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join Group Session',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Enter the 6-character host code',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                style: const TextStyle(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: const InputDecoration(
                  labelText: '6-Character Join Code',
                  hintText: 'e.g. PIZZA1',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().length != 6) {
                    return 'Please enter a valid 6-character code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Display Name',
                  hintText: 'e.g. Alex',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Join Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

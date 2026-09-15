import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final String name;
  final bool isOnboarded;

  const UserState({
    required this.name,
    required this.isOnboarded,
  });

  UserState copyWith({
    String? name,
    bool? isOnboarded,
  }) {
    return UserState(
      name: name ?? this.name,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState(name: 'Alex', isOnboarded: true));

  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      name: trimmed,
      isOnboarded: true,
    );
  }

  void updateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(name: trimmed);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

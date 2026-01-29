import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/presentation/profile/state/ProfileState.dart';
import 'package:naavi/presentation/profile/state/ProfileStateNotifier.dart';
import 'AuthProvider.dart';

/// Provider pour l'état du profil utilisateur
final profileProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return ProfileStateNotifier(authService: authService);
    });

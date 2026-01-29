import 'package:naavi/data/models/user_dto.dart';

/// États pour la page de profil utilisateur
sealed class ProfileState {
  const ProfileState();
}

/// État initial
class ProfileStateInitial extends ProfileState {
  const ProfileStateInitial();
}

/// État de chargement des données utilisateur
class ProfileStateLoading extends ProfileState {
  const ProfileStateLoading();
}

/// État avec les données utilisateur chargées
class ProfileStateLoaded extends ProfileState {
  final UserDto user;

  const ProfileStateLoaded(this.user);

  String get firstName => user.firstname ?? '';
  String get lastName => user.lastname ?? '';
  String get fullName => user.fullName;
  String get email => user.email;
  String? get profilePicture => user.profilePicture;
}

/// État d'erreur
class ProfileStateError extends ProfileState {
  final String message;

  const ProfileStateError(this.message);
}

/// État de déconnexion en cours
class ProfileStateLoggingOut extends ProfileState {
  const ProfileStateLoggingOut();
}

/// État lorsque l'utilisateur n'est pas authentifié
class ProfileStateNotAuthenticated extends ProfileState {
  const ProfileStateNotAuthenticated();
}

/// État de mise à jour du profil en cours
class ProfileStateUpdating extends ProfileState {
  final UserDto currentUser;

  const ProfileStateUpdating(this.currentUser);
}

/// État après une mise à jour réussie
class ProfileStateUpdateSuccess extends ProfileState {
  final UserDto user;
  final String message;

  const ProfileStateUpdateSuccess(this.user, this.message);

  String get firstName => user.firstname ?? '';
  String get lastName => user.lastname ?? '';
  String get fullName => user.fullName;
  String get email => user.email;
  String? get profilePicture => user.profilePicture;
}

/// État d'erreur lors de la mise à jour
class ProfileStateUpdateError extends ProfileState {
  final UserDto currentUser;
  final String message;

  const ProfileStateUpdateError(this.currentUser, this.message);
}

/// État hors-ligne - modification impossible
class ProfileStateOffline extends ProfileState {
  final UserDto? currentUser;

  const ProfileStateOffline(this.currentUser);
}

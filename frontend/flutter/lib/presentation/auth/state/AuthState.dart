sealed class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateSuccess extends AuthState {
  const AuthStateSuccess();
}

class AuthStateError extends AuthState {
  final String message;

  const AuthStateError(this.message);
}

class AuthStateEmailSent extends AuthState {
  final String email;

  const AuthStateEmailSent(this.email);
}

class AuthStateEmailChecked extends AuthState {
  final String email;
  final bool emailExists;

  const AuthStateEmailChecked({required this.email, required this.emailExists});
}

class AuthStatePasswordRequired extends AuthState {
  final String email;

  const AuthStatePasswordRequired(this.email);
}

class AuthStateCreatePassword extends AuthState {
  final String email;

  const AuthStateCreatePassword(this.email);
}

/// État indiquant qu'un compte a été créé avec succès
/// L'utilisateur doit maintenant se connecter avec l'email utilisé
class AuthStateAccountCreated extends AuthState {
  final String email;

  const AuthStateAccountCreated(this.email);
}

/// État indiquant que l'utilisateur est hors-ligne
class AuthStateOffline extends AuthState {
  const AuthStateOffline();
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';
import 'package:naavi/presentation/common/widget/FeedbackOverlay.dart';
import '../../../core/di/AuthProvider.dart';
import '../../../core/resources/colors.dart';
import '../../../core/validators/password_validator.dart';
import 'AuthButton.dart';
import 'GlassmorphicTextField.dart';

class AuthPasswordBottomSheet extends ConsumerStatefulWidget {
  final String email;
  final bool isLogin; // true pour connexion, false pour création

  const AuthPasswordBottomSheet({
    super.key,
    required this.email,
    required this.isLogin,
  });

  @override
  ConsumerState<AuthPasswordBottomSheet> createState() =>
      _AuthPasswordBottomSheetState();
}

class _AuthPasswordBottomSheetState
    extends ConsumerState<AuthPasswordBottomSheet> {
  // Controllers pour l'inscription
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _firstnameFocusNode = FocusNode();
  final FocusNode _lastnameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Erreurs locales pour chaque champ
  String? _firstnameError;
  String? _lastnameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstnameFocusNode.dispose();
    _lastnameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Réinitialise toutes les erreurs
  void _clearErrors() {
    setState(() {
      _firstnameError = null;
      _lastnameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });
  }

  /// Valide les champs et retourne true si tout est valide
  bool _validateFields() {
    _clearErrors();
    bool isValid = true;

    if (!widget.isLogin) {
      // Validation pour l'inscription
      if (_firstnameController.text.trim().isEmpty) {
        setState(() => _firstnameError = 'Le prénom est requis');
        isValid = false;
      }

      if (_lastnameController.text.trim().isEmpty) {
        setState(() => _lastnameError = 'Le nom est requis');
        isValid = false;
      }

      if (_confirmPasswordController.text.isEmpty) {
        setState(
          () => _confirmPasswordError = 'Veuillez confirmer le mot de passe',
        );
        isValid = false;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        setState(
          () =>
              _confirmPasswordError = 'Les mots de passe ne correspondent pas',
        );
        isValid = false;
      }
    }

    // Validation du mot de passe (login et inscription)
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Le mot de passe est requis');
      isValid = false;
    } else if (!widget.isLogin) {
      // Validation des règles de mot de passe uniquement pour l'inscription
      final validationMessage =
          PasswordValidator.getValidationMessage(_passwordController.text);
      if (validationMessage != null) {
        setState(() => _passwordError = validationMessage);
        isValid = false;
      }
    }

    return isValid;
  }

  /// Soumet le formulaire
  void _submit() {
    if (!_validateFields()) return;

    if (widget.isLogin) {
      ref
          .read(authProvider.notifier)
          .loginWithPassword(context, widget.email, _passwordController.text);
    } else {
      ref
          .read(authProvider.notifier)
          .createAccountWithPassword(
            context,
            widget.email,
            _firstnameController.text.trim(),
            _lastnameController.text.trim(),
            _passwordController.text,
            _confirmPasswordController.text,
          );
    }
  }

  /// Gère la demande de réinitialisation de mot de passe
  Future<void> _handleForgotPassword() async {
    // Afficher l'overlay de chargement
    final hideLoading = FeedbackOverlay.showLoading(
      context,
      'Envoi en cours...',
    );

    try {
      await ref.read(authProvider.notifier).forgotPassword(widget.email);

      // Fermer l'overlay de chargement
      hideLoading();

      if (mounted) {
        // On affiche toujours un message de succès pour ne pas révéler
        // si l'email existe ou non (sécurité)
        FeedbackOverlay.showSuccess(
          context,
          'Si cette adresse existe, un email a été envoyé',
        );
      }
    } catch (e) {
      hideLoading();
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          'Une erreur est survenue',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Écouter les changements d'état pour gérer le succès, l'offline et les erreurs
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      if (next is AuthStateSuccess) {
        // Pour le login, fermer la bottom sheet et naviguer
        // Pour l'inscription, l'état AccountCreated sera géré par AuthPage
        if (widget.isLogin) {
          // Fermer la bottom sheet
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          // Afficher l'overlay de succès
          FeedbackOverlay.showSuccess(
            context,
            'Connexion réussie',
          );
        }
      } else if (next is AuthStateAccountCreated) {
        // Après création de compte, fermer cette bottom sheet
        // AuthPage ouvrira automatiquement la bottom sheet de login
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Afficher l'overlay de succès
        FeedbackOverlay.showSuccess(
          context,
          'Compte créé !',
        );
      } else if (next is AuthStateOffline) {
        // Fermer la bottom sheet et afficher le message offline
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        FeedbackOverlay.showWarning(context, 'Pas de connexion internet');
      } else if (next is AuthStateError) {
        // Afficher l'erreur de l'API
        setState(() {
          _generalError = next.message;
        });
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Titre
                  Text(
                    widget.isLogin ? 'Connexion' : 'Créer un compte',
                    style: const TextStyle(
                      fontFamily: 'Lexend Deca',
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: TextStyle(
                      fontFamily: 'Lexend Deca',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Erreur générale (API)
                  if (_generalError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.shade400,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _generalError!,
                              style: TextStyle(
                                fontFamily: 'Lexend Deca',
                                fontSize: 13,
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  // Champs pour l'inscription uniquement (prénom, nom)
                  if (!widget.isLogin) ...[
                    GlassmorphicTextField(
                      controller: _firstnameController,
                      focusNode: _firstnameFocusNode,
                      hintText: 'Prénom',
                      textInputAction: TextInputAction.next,
                      errorText: _firstnameError,
                      onSubmitted: (_) {
                        _lastnameFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 18),
                    GlassmorphicTextField(
                      controller: _lastnameController,
                      focusNode: _lastnameFocusNode,
                      hintText: 'Nom',
                      textInputAction: TextInputAction.next,
                      errorText: _lastnameError,
                      onSubmitted: (_) {
                        _passwordFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  // Champ mot de passe
                  GlassmorphicTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    hintText: 'Mot de passe',
                    obscureText: true,
                    errorText: _passwordError,
                    textInputAction: widget.isLogin
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onSubmitted: widget.isLogin
                        ? (value) {
                            if (authState is! AuthStateLoading) {
                              _submit();
                            }
                          }
                        : (_) {
                            _confirmPasswordFocusNode.requestFocus();
                          },
                  ),
                  // Lien mot de passe oublié (seulement pour connexion)
                  if (widget.isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState is AuthStateLoading
                            ? null
                            : _handleForgotPassword,
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontFamily: 'Lexend Deca',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Champ confirmation (seulement pour création)
                  if (!widget.isLogin) ...[
                    const SizedBox(height: 18),
                    GlassmorphicTextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      hintText: 'Confirmer le mot de passe',
                      obscureText: true,
                      errorText: _confirmPasswordError,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        if (authState is! AuthStateLoading) {
                          _submit();
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Bouton principal
                  AuthButton(
                    text: widget.isLogin ? 'Se connecter' : 'Créer le compte',
                    onPressed: () {
                      if (authState is! AuthStateLoading) {
                        _submit();
                      }
                    },
                    isLoading: authState is AuthStateLoading,
                    type: AuthButtonType.primary,
                  ),
                  const SizedBox(height: 16),
                  // Bouton retour
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(authProvider.notifier).resetState();
                    },
                    child: Text(
                      'Retour',
                      style: TextStyle(
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

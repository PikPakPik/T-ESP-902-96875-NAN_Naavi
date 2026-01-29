import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:naavi/presentation/auth/state/AuthState.dart';
import '../../core/di/AuthProvider.dart';
import '../../core/di/HttpClientProvider.dart';
import '../../core/resources/colors.dart';
import 'widget/AuthButton.dart';
import 'widget/AuthBackgroundVideo.dart';
import 'widget/GlassmorphicTextField.dart';
import 'widget/AuthPasswordBottomSheet.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasLoadedEmail = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Réinitialiser l'état d'authentification quand on arrive sur la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).resetState();
      // Vérifier la connexion au démarrage
      ref.read(authProvider.notifier).checkConnectivity();
    });
    // Écouter les changements de focus pour scroller automatiquement
    _emailFocusNode.addListener(_onEmailFocusChange);
    // Charger l'email stocké si disponible
    _loadStoredEmail();
  }

  /// Charge l'email stocké dans le local storage
  Future<void> _loadStoredEmail() async {
    if (_hasLoadedEmail) return;

    final tokenStorage = ref.read(tokenStorageProvider);
    final email = await tokenStorage.getUserEmail();

    if (email != null && email.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = email;
        _hasLoadedEmail = true;
      });
    }
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      // Attendre que le clavier apparaisse et que le layout soit mis à jour
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            // Scroller vers le bas pour que le champ email soit visible au-dessus du clavier
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      });
      // Forcer un rebuild pour que le padding soit recalculé avec le viewInsets
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailController.dispose();
    _emailFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      if (next is AuthStateError) {
        // Afficher l'erreur sous le champ email
        setState(() {
          _emailError = next.message;
        });
      } else if (next is AuthStateOffline) {
        // Le banner offline s'affiche automatiquement
        setState(() {
          _emailError = null;
        });
      } else if (next is AuthStatePasswordRequired) {
        // Réinitialiser l'erreur et ouvrir bottom sheet pour connexion
        setState(() {
          _emailError = null;
        });
        if (!Navigator.of(context).canPop()) {
          _showPasswordBottomSheet(context, next.email, isLogin: true);
        }
      } else if (next is AuthStateCreatePassword) {
        // Réinitialiser l'erreur et ouvrir bottom sheet pour création
        setState(() {
          _emailError = null;
        });
        if (!Navigator.of(context).canPop()) {
          _showPasswordBottomSheet(context, next.email, isLogin: false);
        }
      } else if (next is AuthStateAccountCreated) {
        // Après création de compte, pré-remplir l'email et ouvrir bottom sheet de login
        setState(() {
          _emailController.text = next.email;
          _emailError = null;
        });
        // Attendre un peu pour que la bottom sheet d'inscription se ferme
        // (elle sera fermée par AuthPasswordBottomSheet qui détecte AuthStateAccountCreated)
        final contextToUse = context;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!contextToUse.mounted) return;
          if (!Navigator.of(contextToUse).canPop()) {
            _showPasswordBottomSheet(contextToUse, next.email, isLogin: true);
          }
        });
      } else if (next is AuthStateInitial || next is AuthStateLoading) {
        // Réinitialiser l'erreur
        setState(() {
          _emailError = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: AuthBackgroundVideo()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.37, 1.0],
                  colors: [
                    Colors.transparent,
                    AppColors.primaryColor.withValues(alpha: 0.45),
                    AppColors.primaryColor,
                  ],
                ),
              ),
            ),
          ),
          // Logo fixe en haut
          Positioned(
            top: 93,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/logo/logo_long-dark.svg',
                  width: 150,
                ),
              ),
            ),
          ),
          // Contenu scrollable
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 93 + 150), // Espace pour le logo
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 50,
                                  right: 50,
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                      30,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 130),
                                    AuthButton(
                                      text: "S'inscrire avec Google",
                                      onPressed: () => ref
                                          .read(authProvider.notifier)
                                          .signInWithGoogle(context),
                                      isLoading: authState is AuthStateLoading,
                                      type: AuthButtonType.social,
                                      disabled: true,
                                    ),
                                    const SizedBox(height: 12),
                                    AuthButton(
                                      text: "S'inscrire avec Apple",
                                      onPressed: () => ref
                                          .read(authProvider.notifier)
                                          .signInWithApple(context),
                                      isLoading: authState is AuthStateLoading,
                                      type: AuthButtonType.social,
                                      disabled: true,
                                    ),
                                    const SizedBox(height: 37),
                                    Container(height: 1, color: Colors.white),
                                    const SizedBox(height: 18),
                                    _buildContent(authState),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Banner offline en haut
          if (authState is AuthStateOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: _buildOfflineBanner()),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pas de connexion internet',
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).refreshConnectivity();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(
                  fontFamily: 'Lexend Deca',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthState authState) {
    // Toujours afficher l'écran email, la bottom sheet s'ouvrira automatiquement
    return _buildEmailInput();
  }

  void _showPasswordBottomSheet(
    BuildContext context,
    String email, {
    required bool isLogin,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AuthPasswordBottomSheet(email: email, isLogin: isLogin),
    );
  }

  Widget _buildEmailInput() {
    final authState = ref.watch(authProvider);
    return Column(
      children: [
        GlassmorphicTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          hintText: 'Adresse email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: _emailError,
          enabled: authState is! AuthStateLoading,
          onSubmitted: (value) {
            if (authState is! AuthStateLoading) {
              ref.read(authProvider.notifier).checkEmail(context, value);
            }
          },
        ),
        const SizedBox(height: 24),
        AuthButton(
          text: 'Suivant',
          onPressed: () {
            if (authState is! AuthStateLoading) {
              ref
                  .read(authProvider.notifier)
                  .checkEmail(context, _emailController.text);
            }
          },
          isLoading: authState is AuthStateLoading,
          type: AuthButtonType.primary,
        ),
        const SizedBox(height: 24),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(authProvider.notifier).skipAuthentication(context);
            },
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Ne pas se connecter',
                style: TextStyle(
                  fontFamily: 'Lexend Deca',
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

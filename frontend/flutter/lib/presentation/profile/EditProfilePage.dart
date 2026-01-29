import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/data/models/user_dto.dart';
import 'package:naavi/presentation/common/widget/FeedbackOverlay.dart';
import '../../core/di/ProfileProvider.dart';
import 'state/ProfileState.dart';

/// Page de modification du profil utilisateur
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les champs avec les données actuelles
    Future.microtask(() {
      _initializeFields();
    });
  }

  void _initializeFields() {
    final state = ref.read(profileProvider);
    UserDto? user;

    if (state is ProfileStateLoaded) {
      user = state.user;
    } else if (state is ProfileStateUpdateSuccess) {
      user = state.user;
    }

    if (user != null) {
      _firstnameController.text = user.firstname ?? '';
      _lastnameController.text = user.lastname ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          'Erreur lors de la sélection de l\'image',
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Lexend Deca',
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.tertiaryColor,
                ),
                title: const Text(
                  'Galerie',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend Deca',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.tertiaryColor,
                ),
                title: const Text(
                  'Appareil photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend Deca',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Si une image a été sélectionnée, l'uploader d'abord
      if (_selectedImage != null) {
        final imageSuccess = await ref
            .read(profileProvider.notifier)
            .uploadProfilePicture(_selectedImage!);

        if (!imageSuccess && mounted) {
          final state = ref.read(profileProvider);
          if (state is ProfileStateOffline) {
            _showOfflineDialog();
          } else {
            // Image upload failed for another reason (server error, etc.)
            ref.read(profileProvider.notifier).dismissErrorMessage();
            FeedbackOverlay.showError(
              context,
              state is ProfileStateUpdateError
                  ? state.message
                  : 'Erreur lors de l\'envoi de l\'image',
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Mettre à jour les autres informations
      final success = await ref
          .read(profileProvider.notifier)
          .updateProfile(
            firstname: _firstnameController.text.trim(),
            lastname: _lastnameController.text.trim(),
          );

      if (mounted) {
        final state = ref.read(profileProvider);

        if (state is ProfileStateOffline) {
          _showOfflineDialog();
        } else if (success) {
          // Réinitialiser l'état vers ProfileStateLoaded
          ref.read(profileProvider.notifier).dismissSuccessMessage();
          FeedbackOverlay.showSuccess(context, 'Profil mis à jour');
          context.pop();
        } else {
          // Réinitialiser l'état après affichage de l'erreur
          ref.read(profileProvider.notifier).dismissErrorMessage();
          FeedbackOverlay.showError(
            context,
            state is ProfileStateUpdateError
                ? state.message
                : 'Erreur lors de la mise à jour',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Mode hors-ligne',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend Deca',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Vous êtes actuellement hors-ligne. La modification du profil nécessite une connexion Internet.',
          style: TextStyle(color: Colors.white, fontFamily: 'Lexend Deca'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(profileProvider.notifier).dismissErrorMessage();
            },
            child: const Text(
              'Compris',
              style: TextStyle(
                color: AppColors.tertiaryColor,
                fontFamily: 'Lexend Deca',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    // Afficher l'overlay de chargement
    final hideLoading = FeedbackOverlay.showLoading(
      context,
      'Envoi en cours...',
    );

    try {
      final success = await ref
          .read(profileProvider.notifier)
          .requestPasswordReset();

      // Fermer l'overlay de chargement
      hideLoading();

      if (mounted) {
        if (success) {
          FeedbackOverlay.showSuccess(
            context,
            'Email de réinitialisation envoyé',
          );
        } else {
          FeedbackOverlay.showError(
            context,
            'Impossible d\'envoyer l\'email. Vérifiez votre connexion.',
          );
        }
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
    final profileState = ref.watch(profileProvider);

    // Récupérer l'utilisateur actuel pour l'affichage
    UserDto? currentUser;
    if (profileState is ProfileStateLoaded) {
      currentUser = profileState.user;
    } else if (profileState is ProfileStateUpdateSuccess) {
      currentUser = profileState.user;
    } else if (profileState is ProfileStateUpdating) {
      currentUser = profileState.currentUser;
    } else if (profileState is ProfileStateUpdateError) {
      currentUser = profileState.currentUser;
    } else if (profileState is ProfileStateOffline) {
      currentUser = profileState.currentUser;
    }

    final isUpdating = profileState is ProfileStateUpdating || _isLoading;

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Modifier mon profil',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isUpdating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: AppColors.tertiaryColor,
                  fontFamily: 'Lexend Deca',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Photo de profil
                  Center(
                    child: GestureDetector(
                      onTap: isUpdating ? null : _showImageSourceDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.tertiaryColor,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : currentUser?.profilePicture != null
                                ? NetworkImage(currentUser!.profilePicture!)
                                : null,
                            child:
                                (_selectedImage == null &&
                                    currentUser?.profilePicture == null)
                                ? Text(
                                    _getInitials(
                                      _firstnameController.text,
                                      _lastnameController.text,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                      fontFamily: 'Lexend Deca',
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.tertiaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Appuyez pour modifier',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontFamily: 'Lexend Deca',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Champ Prénom
                  _buildLabel('Prénom'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _firstnameController,
                    hintText: 'Entrez votre prénom',
                    enabled: !isUpdating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le prénom est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Champ Nom
                  _buildLabel('Nom'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _lastnameController,
                    hintText: 'Entrez votre nom',
                    enabled: !isUpdating,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Champ Email (non modifiable)
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentUser?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontFamily: 'Lexend Deca',
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'L\'adresse email ne peut pas être modifiée',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontFamily: 'Lexend Deca',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton de réinitialisation du mot de passe
                  _buildLabel('Mot de passe'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isUpdating ? null : _requestPasswordReset,
                      icon: const Icon(
                        Icons.lock_reset,
                        color: AppColors.tertiaryColor,
                      ),
                      label: const Text(
                        'Réinitialiser mon mot de passe',
                        style: TextStyle(
                          color: AppColors.tertiaryColor,
                          fontFamily: 'Lexend Deca',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.tertiaryColor,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Un email de réinitialisation sera envoyé à votre adresse',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontFamily: 'Lexend Deca',
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Lexend Deca',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Lexend Deca',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontFamily: 'Lexend Deca',
        ),
        filled: true,
        fillColor: AppColors.secondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.tertiaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontFamily: 'Lexend Deca',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  String _getInitials(String firstname, String lastname) {
    final first = firstname.isNotEmpty ? firstname[0].toUpperCase() : '';
    final last = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last';
  }
}

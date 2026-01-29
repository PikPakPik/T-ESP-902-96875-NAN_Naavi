import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naavi/core/resources/colors.dart';
import 'package:naavi/data/models/user_dto.dart';
import 'package:naavi/presentation/common/widget/FeedbackOverlay.dart';
import 'package:naavi/presentation/profile/state/ProfileState.dart';
import '../../core/di/ProfileProvider.dart';

/// Page de profil utilisateur
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Statistiques mockées (à remplacer par des appels API)
  final Map<String, dynamic> _mockStatistics = {
    'totalKilometers': 125.5,
    'totalTime': Duration(hours: 45, minutes: 30),
    'hikesCount': 12,
    'poisVisited': 28,
  };

  @override
  void initState() {
    super.initState();
    // Charger le profil au démarrage
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(child: _buildContent(profileState)),
    );
  }

  Widget _buildContent(ProfileState state) {
    return switch (state) {
      ProfileStateInitial() => const Center(
        child: Text('Initialisation...', style: TextStyle(color: Colors.white)),
      ),
      ProfileStateLoading() => const Center(
        child: CircularProgressIndicator(color: AppColors.tertiaryColor),
      ),
      ProfileStateLoaded() => _buildProfileContentFromUser(state.user),
      ProfileStateError() => _buildErrorContent(state.message),
      ProfileStateLoggingOut() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.tertiaryColor),
            SizedBox(height: 16),
            Text(
              'Déconnexion en cours...',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend Deca',
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      ProfileStateNotAuthenticated() => _buildNotAuthenticatedContent(),
      ProfileStateUpdating() => _buildProfileContentFromUser(state.currentUser),
      ProfileStateUpdateSuccess() => _buildProfileContentFromUser(state.user),
      ProfileStateUpdateError() => _buildProfileContentFromUser(
        state.currentUser,
      ),
      ProfileStateOffline() =>
        state.currentUser != null
            ? _buildProfileContentFromUser(state.currentUser!, isOffline: true)
            : _buildOfflineNoDataContent(),
    };
  }

  Widget _buildProfileContentFromUser(UserDto user, {bool isOffline = false}) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière hors-ligne
            if (isOffline) ...[
              _buildOfflineBanner(),
              const SizedBox(height: 16),
            ],

            // Section Nom et Avatar
            _buildHeaderFromUser(user),
            const SizedBox(height: 32),

            // Section Statistiques
            _buildStatisticsSection(),
            const SizedBox(height: 32),

            // Section Actions
            _buildActionsSection(isOffline: isOffline),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode hors-ligne',
                  style: TextStyle(
                    color: Colors.orange,
                    fontFamily: 'Lexend Deca',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Les données affichées peuvent ne pas être à jour',
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.8),
                    fontFamily: 'Lexend Deca',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineNoDataContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Mode hors-ligne',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Lexend Deca',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous à Internet pour charger votre profil',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Lexend Deca',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(profileProvider.notifier).loadUserProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryColor,
                foregroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFromUser(UserDto user) {
    return Center(
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.tertiaryColor,
            backgroundImage: user.profilePicture != null
                ? NetworkImage(user.profilePicture!)
                : null,
            child: user.profilePicture == null
                ? Text(
                    _getInitials(user.fullName),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontFamily: 'Lexend Deca',
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          // Nom
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Lexend Deca',
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'Lexend Deca',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques perso',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Lexend Deca',
          ),
        ),
        const SizedBox(height: 16),
        // Grille de statistiques
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              icon: Icons.straighten,
              label: 'Kilomètres',
              value: '${_mockStatistics['totalKilometers']} km',
            ),
            _buildStatCard(
              icon: Icons.timer,
              label: 'Temps passé',
              value: _formatDuration(_mockStatistics['totalTime'] as Duration),
            ),
            _buildStatCard(
              icon: Icons.hiking,
              label: 'Randonnées',
              value: '${_mockStatistics['hikesCount']}',
            ),
            _buildStatCard(
              icon: Icons.location_on,
              label: 'POI visités',
              value: '${_mockStatistics['poisVisited']}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.tertiaryColor, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Lexend Deca',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Lexend Deca',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection({bool isOffline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Lexend Deca',
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Modifier mon profil',
          onTap: isOffline
              ? () {
                  FeedbackOverlay.showWarning(context, 'Connexion requise');
                }
              : () {
                  context.push('/profile/edit');
                },
          isDisabled: isOffline,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.logout,
          label: 'Déconnexion',
          onTap: () => _showLogoutConfirmation(context),
          isDestructive: false,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.delete_forever,
          label: 'Suppression de compte',
          onTap: () => _showDeleteAccountConfirmation(context),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    final Color iconColor = isDisabled
        ? Colors.white.withValues(alpha: 0.3)
        : isDestructive
        ? Colors.red.shade400
        : AppColors.tertiaryColor;
    final Color textColor = isDisabled
        ? Colors.white.withValues(alpha: 0.3)
        : isDestructive
        ? Colors.red.shade400
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.secondaryColor.withValues(alpha: 0.5)
              : AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  fontFamily: 'Lexend Deca',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDisabled
                  ? Colors.white.withValues(alpha: 0.2)
                  : isDestructive
                  ? Colors.red.shade400
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Lexend Deca',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Lexend Deca',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(profileProvider.notifier).loadUserProfile();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tertiaryColor,
                foregroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lexend Deca',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: Colors.white, fontFamily: 'Lexend Deca'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Lexend Deca',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(profileProvider.notifier).logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    const emailAddress = 'delete-account@naavi-trails.fr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mail_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Suppression de compte',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Lexend Deca',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pour supprimer votre compte, veuillez envoyer un email à :',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend Deca',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.tertiaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.email,
                    color: AppColors.tertiaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emailAddress,
                      style: const TextStyle(
                        color: AppColors.tertiaryColor,
                        fontFamily: 'Lexend Deca',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Notre équipe traitera votre demande dans les plus brefs délais.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Lexend Deca',
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'Lexend Deca',
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              // Copier l'email dans le presse-papier
              await Clipboard.setData(const ClipboardData(text: emailAddress));
              if (context.mounted) {
                FeedbackOverlay.showSuccess(context, 'Email copié');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiaryColor,
              foregroundColor: AppColors.primaryColor,
            ),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text(
              'Copier l\'email',
              style: TextStyle(
                fontFamily: 'Lexend Deca',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Widget _buildNotAuthenticatedContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
              color: AppColors.tertiaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vous n\'êtes pas connecté',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Lexend Deca',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour accéder à votre profil et vos statistiques',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Lexend Deca',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButton(
              icon: Icons.login,
              label: 'Se connecter',
              onTap: () {
                context.go('/auth');
              },
              isDestructive: false,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.person_add,
              label: 'S\'inscrire',
              onTap: () {
                context.go('/auth');
              },
              isDestructive: false,
            ),
          ],
        ),
      ),
    );
  }
}

import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthStore } from '../auth.store';

export const AuthGuard = async () => {
  const authStore = inject(AuthStore);
  const router = inject(Router);

  try {
    // Vérifier si l'utilisateur est déjà chargé et valide
    const currentUser = authStore.user();
    if (currentUser && currentUser.id !== '') {
      return true; // Utilisateur déjà chargé, pas besoin de refaire l'appel
    }

    // Sinon, charger l'utilisateur
    await authStore.currentUser();

    if (!authStore.user() || authStore.user().id === '') {
      router.navigateByUrl('/login');
      return false;
    }

    return true;
  } catch (error) {
    // If there's an error getting the current user, redirect to login
    console.warn(
      'AuthGuard: Error getting current user, redirecting to login',
      error
    );
    router.navigateByUrl('/login');
    return false;
  }
};

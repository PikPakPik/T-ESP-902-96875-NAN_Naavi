import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthStore } from '../auth.store';

export const AdminGuard = async () => {
  const authStore = inject(AuthStore);
  const router = inject(Router);

  const user = authStore.user();

  // Vérifier que l'utilisateur est bien chargé
  if (!user || user.id === '') {
    // Si l'utilisateur n'est pas chargé, on attend un peu ou on redirige vers login
    router.navigateByUrl('/login');
    return false;
  }

  if (!user.roles.includes('ROLE_ADMIN')) {
    router.navigateByUrl('/forbidden');
    return false;
  }

  return true;
};

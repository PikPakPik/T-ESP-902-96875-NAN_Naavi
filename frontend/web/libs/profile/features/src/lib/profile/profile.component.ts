import { SelectModule } from 'primeng/select';
import { Component, inject, signal, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { form, required, email, minLength, FormField } from '@angular/forms/signals';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { CardModule } from 'primeng/card';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { DividerModule } from 'primeng/divider';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { AuthStore } from '@web/auth/data-access';
import { UsersStore } from '@web/users/data-access';
import { User } from '@web/shared/models/settings';
import { LanguageService, Language } from '@web/shared/util';

interface ProfileInfoData {
  firstname: string;
  lastname: string;
  email: string;
}

interface PasswordChangeData {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

@Component({
  selector: 'profile',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    FormField,
    ButtonModule,
    InputTextModule,
    CardModule,
    ToastModule,
    DividerModule,
    TranslateModule,
    SelectModule,
  ],
  providers: [MessageService],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss',
})
export class ProfileComponent {
  #authStore = inject(AuthStore);
  #usersStore = inject(UsersStore);
  #messageService = inject(MessageService);
  #translateService = inject(TranslateService);
  #languageService = inject(LanguageService);

  user = this.#authStore.user;

  // Form data pour les informations
  profileInfoModel = signal<ProfileInfoData>({
    firstname: '',
    lastname: '',
    email: '',
  });

  profileInfoForm = form(this.profileInfoModel, (schemaPath) => {
    required(schemaPath.firstname, { message: this.#translateService.instant('PROFILE.FIRSTNAME_REQUIRED') });
    required(schemaPath.lastname, { message: this.#translateService.instant('PROFILE.LASTNAME_REQUIRED') });
    required(schemaPath.email, { message: this.#translateService.instant('PROFILE.EMAIL_REQUIRED') });
    email(schemaPath.email, { message: this.#translateService.instant('PROFILE.EMAIL_REQUIRED') });
  });

  // Form data pour le mot de passe
  passwordChangeModel = signal<PasswordChangeData>({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });

  passwordChangeForm = form(this.passwordChangeModel, (schemaPath) => {
    required(schemaPath.currentPassword, { message: this.#translateService.instant('PROFILE.CURRENT_PASSWORD_REQUIRED') });
    required(schemaPath.newPassword, { message: this.#translateService.instant('PROFILE.NEW_PASSWORD_REQUIRED') });
    minLength(schemaPath.newPassword, 8, { message: this.#translateService.instant('PROFILE.PASSWORD_MIN_LENGTH') });
    required(schemaPath.confirmPassword, { message: this.#translateService.instant('PROFILE.CONFIRM_PASSWORD_REQUIRED') });
  });

  // Données lecture seule
  status = signal(this.user()?.status || '');
  roles = signal(this.user()?.roles || []);
  userId = signal(this.user()?.id || '');

  // États UI
  isEditingInfo = signal(false);
  isChangingPassword = signal(false);
  submittedInfo = signal(false);
  submittedPassword = signal(false);

  // Language selector
  availableLanguages = this.#languageService.getAvailableLanguages();
  selectedLanguage: { code: Language; label: string } =
    this.#languageService
      .getAvailableLanguages()
      .find(
        (lang) => lang.code === this.#languageService.getCurrentLanguage()
      ) || this.#languageService.getAvailableLanguages()[0];

  constructor() {
    // Initialiser les données du formulaire avec les données utilisateur
    effect(() => {
      const currentUser = this.user();
      if (currentUser) {
        this.profileInfoModel.set({
          firstname: currentUser.firstname,
          lastname: currentUser.lastname,
          email: currentUser.email,
        });
        this.status.set(currentUser.status);
        this.roles.set([...currentUser.roles]);
        this.userId.set(currentUser.id);
      }
    });
  }

  toggleEditInfo() {
    if (this.isEditingInfo()) {
      // Annuler - recharger les données
      const user = this.#authStore.user();
      if (user) {
        this.profileInfoModel.set({
          firstname: user.firstname,
          lastname: user.lastname,
          email: user.email,
        });
      }
    }
    this.isEditingInfo.set(!this.isEditingInfo());
  }

  togglePasswordChange() {
    if (this.isChangingPassword()) {
      // Annuler - vider les champs
      this.passwordChangeModel.set({
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      });
    }
    this.isChangingPassword.set(!this.isChangingPassword());
  }

  async saveInfo() {
    this.submittedInfo.set(true);

    const emailField = this.profileInfoForm.email();
    const firstnameField = this.profileInfoForm.firstname();
    const lastnameField = this.profileInfoForm.lastname();

    if (!emailField.valid() || !firstnameField.valid() || !lastnameField.valid()) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING') || 'Warning',
        detail: this.#translateService.instant('PROFILE.WARNING.FILL_REQUIRED'),
      });
      return;
    }

    const model = this.profileInfoModel();
    const user = this.#authStore.user();
    const userData = {
      ...user,
      firstname: model.firstname,
      lastname: model.lastname,
      fullName: `${model.firstname} ${model.lastname}`,
      email: model.email,
    } as User;

    try {
      await this.#usersStore.update(userData);
      // Recharger l'utilisateur dans le AuthStore
      await this.#authStore.currentUser();

      this.#messageService.add({
        severity: 'success',
        summary: this.#translateService.instant('COMMON.SUCCESS') || 'Success',
        detail: this.#translateService.instant('PROFILE.SUCCESS.UPDATED'),
      });
      this.isEditingInfo.set(false);
      this.submittedInfo.set(false);
    } catch (error) {
      console.error('Error saving user info:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR') || 'Error',
        detail: this.#translateService.instant('PROFILE.ERROR.SAVE_FAILED'),
      });
    }
  }

  async changePassword() {
    this.submittedPassword.set(true);

    const currentPwdField = this.passwordChangeForm.currentPassword();
    const newPwdField = this.passwordChangeForm.newPassword();
    const confirmPwdField = this.passwordChangeForm.confirmPassword();

    if (!currentPwdField.valid() || !newPwdField.valid() || !confirmPwdField.valid()) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING') || 'Warning',
        detail: this.#translateService.instant('PROFILE.WARNING.FILL_REQUIRED'),
      });
      return;
    }

    const model = this.passwordChangeModel();
    if (model.newPassword !== model.confirmPassword) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING') || 'Warning',
        detail: this.#translateService.instant(
          'PROFILE.WARNING.PASSWORDS_MISMATCH'
        ),
      });
      return;
    }

    try {
      // TODO: Implémenter l'API de changement de mot de passe
      // await this.#authService.changePassword(model.currentPassword, model.newPassword);

      this.#messageService.add({
        severity: 'success',
        summary: this.#translateService.instant('COMMON.SUCCESS') || 'Success',
        detail: this.#translateService.instant(
          'PROFILE.SUCCESS.PASSWORD_CHANGED'
        ),
      });

      this.passwordChangeModel.set({
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      });
      this.isChangingPassword.set(false);
      this.submittedPassword.set(false);
    } catch (error) {
      console.error('Error changing password:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR') || 'Error',
        detail: this.#translateService.instant(
          'PROFILE.ERROR.PASSWORD_CHANGE_FAILED'
        ),
      });
    }
  }

  onLanguageChange(): void {
    if (this.selectedLanguage && this.selectedLanguage.code) {
      this.#languageService.setLanguage(this.selectedLanguage.code);
    }
  }
}

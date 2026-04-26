import { Component, inject, signal, effect, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { form, required, email, FormField } from '@angular/forms/signals';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { CardModule } from 'primeng/card';
import { SelectModule } from 'primeng/select';
import { MultiSelectModule } from 'primeng/multiselect';
import { ToastModule } from 'primeng/toast';
import { TooltipModule } from 'primeng/tooltip';
import { ImageModule } from 'primeng/image';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService, MessageService } from 'primeng/api';
import { UsersStore } from '@web/users/data-access';
import { User, Role, Status } from '@web/shared/models/settings';
import { IMAGES_BASE_URL } from '@web/shared/http-client';
import { naaviMediaDisplayUrl } from '@web/shared/util';
import { DividerModule } from 'primeng/divider';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

interface UserUpsertData {
  firstname: string;
  lastname: string;
  email: string;
  selectedRoles: Role[];
  status: Status;
}

@Component({
  selector: 'user-upsert',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ButtonModule,
    InputTextModule,
    CardModule,
    SelectModule,
    MultiSelectModule,
    ToastModule,
    TooltipModule,
    ImageModule,
    ConfirmDialogModule,
    DividerModule,
    TranslateModule,
    FormField
],
  providers: [MessageService, ConfirmationService],
  templateUrl: './user-upsert.component.html',
  styleUrl: './user-upsert.component.scss',
})
export class UserUpsertComponent {
  #router = inject(Router);
  #route = inject(ActivatedRoute);
  #usersStore = inject(UsersStore);
  #messageService = inject(MessageService);
  #translateService = inject(TranslateService);
  #confirmationService = inject(ConfirmationService);
  #imagesBaseUrl = inject(IMAGES_BASE_URL, { optional: true });

  // Form data
  userModel = signal<UserUpsertData>({
    firstname: '',
    lastname: '',
    email: '',
    selectedRoles: [],
    status: 'UNVERIFIED',
  });

  userForm = form(this.userModel, (schemaPath) => {
    required(schemaPath.firstname, { message: this.#translateService.instant('PROFILE.FIRSTNAME_REQUIRED') });
    required(schemaPath.lastname, { message: this.#translateService.instant('PROFILE.LASTNAME_REQUIRED') });
    required(schemaPath.email, { message: this.#translateService.instant('USER.UPSERT.EMAIL_VALID_REQUIRED') });
    email(schemaPath.email, { message: this.#translateService.instant('USER.UPSERT.EMAIL_VALID_REQUIRED') });
  });

  isEditMode = signal(false);
  userId = signal<string | null>(null);
  submitted = signal(false);
  profilePicture = signal<string | null>(null);

  // Options - ROLE_USER est ajouté automatiquement, ne pas l'afficher
  roleOptions = computed(() => {
    return [
      { label: 'PROFILE.ROLE.ADMIN', value: 'ROLE_ADMIN' as Role },
      { label: 'PROFILE.ROLE.MODERATOR', value: 'ROLE_MODERATOR' as Role },
    ];
  });

  statusOptions = computed(() => {
    return [
      { label: 'PROFILE.STATUS.VERIFIED', value: 'VERIFIED' as Status },
      { label: 'PROFILE.STATUS.UNVERIFIED', value: 'UNVERIFIED' as Status },
      { label: 'PROFILE.STATUS.DELETED', value: 'DELETED' as Status },
    ];
  });

  // Computed pour faciliter l'accès
  firstname = computed(() => this.userModel().firstname);
  lastname = computed(() => this.userModel().lastname);
  email = computed(() => this.userModel().email);
  selectedRoles = computed(() => this.userModel().selectedRoles);
  status = computed(() => this.userModel().status);

  profilePictureUrl = computed(() =>
    naaviMediaDisplayUrl(this.profilePicture(), this.#imagesBaseUrl)
  );

  onRolesChange(selectedRoles: Role[]) {
    this.userModel.update((model) => ({
      ...model,
      selectedRoles: selectedRoles || [],
    }));
  }

  onStatusChange(status: Status) {
    this.userModel.update((model) => ({
      ...model,
      status: status,
    }));
  }

  constructor() {
    // Load user data if in edit mode
    effect(() => {
      const id = this.#route.snapshot.params['id'];
      if (id) {
        this.loadUserForEdit(id);
      }
    });

    // Watch for route params changes
    this.#route.params.subscribe((params) => {
      if (params['id'] && params['id'] !== this.userId()) {
        this.loadUserForEdit(params['id']);
      }
    });
  }

  async loadUserForEdit(id: string) {
    try {
      // Essayer de charger depuis le store d'abord
      const users = this.#usersStore.entities();
      let user = users.find((u) => u.id === id);

      // Si pas dans le store, le charger via le service
      if (!user) {
        user = await this.#usersStore.getUserById(id);
      }

      if (user) {
        this.isEditMode.set(true);
        this.userId.set(user.id);
        this.profilePicture.set(user.profilePicture ?? null);
        this.userModel.set({
          firstname: user.firstname,
          lastname: user.lastname,
          email: user.email,
          // Filtrer ROLE_USER car il est ajouté automatiquement
          selectedRoles: user.roles.filter((role) => role !== 'ROLE_USER'),
          status: user.status,
        });
      }
    } catch (error) {
      console.error('Error loading user:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('USER.ERROR.LOAD_FAILED'),
      });
    }
  }

  async resetPassword() {
    const model = this.userModel();
    if (!model.email) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('USER.WARNING.EMAIL_REQUIRED'),
      });
      return;
    }

    try {
      const user = {
        id: this.userId() || '',
        firstname: model.firstname,
        lastname: model.lastname,
        email: model.email,
        roles: model.selectedRoles,
        status: model.status,
        fullName: `${model.firstname} ${model.lastname}`,
      } as User;

      await this.#usersStore.resetPassword(user);
    } catch (error) {
      console.error('Error resetting password:', error);
    }
  }

  async saveUser() {
    this.submitted.set(true);

    const firstnameField = this.userForm.firstname();
    const lastnameField = this.userForm.lastname();
    const emailField = this.userForm.email();

    if (!firstnameField.valid() || !lastnameField.valid() || !emailField.valid()) {
      this.#messageService.add({
        severity: 'warn',
        summary: this.#translateService.instant('COMMON.WARNING'),
        detail: this.#translateService.instant('USER.WARNING.FILL_REQUIRED'),
      });
      return;
    }

    const model = this.userModel();
    // Toujours ajouter ROLE_USER aux rôles sélectionnés
    const allRoles = ['ROLE_USER' as Role, ...model.selectedRoles];
    // Supprimer les doublons au cas où
    const uniqueRoles = [...new Set(allRoles)] as Role[];

    const userData = {
      id: this.userId() || Date.now().toString(),
      firstname: model.firstname,
      lastname: model.lastname,
      fullName: `${model.firstname} ${model.lastname}`,
      email: model.email,
      roles: uniqueRoles,
      status: model.status,
    } as User;

    try {
      if (this.isEditMode()) {
        await this.#usersStore.update(userData);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('USER.SUCCESS.UPDATED'),
        });
      } else {
        await this.#usersStore.create(userData);
        this.#messageService.add({
          severity: 'success',
          summary: this.#translateService.instant('COMMON.SUCCESS'),
          detail: this.#translateService.instant('USER.SUCCESS.CREATED'),
        });
      }

      this.#router.navigate(['/backoffice/users']);
    } catch (error) {
      console.error('Error saving user:', error);
      this.#messageService.add({
        severity: 'error',
        summary: this.#translateService.instant('COMMON.ERROR'),
        detail: this.#translateService.instant('USER.ERROR.SAVE_FAILED'),
      });
    }
  }

  cancel() {
    this.#router.navigate(['/backoffice/users']);
  }

  async deleteProfilePicture() {
    const id = this.userId();
    if (!id) return;
    this.#confirmationService.confirm({
      message: this.#translateService.instant('USER.CONFIRM.DELETE_PROFILE_PICTURE'),
      header: this.#translateService.instant('COMMON.CONFIRM') || 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: async () => {
        try {
          await this.#usersStore.deleteProfilePicture(id);
          this.profilePicture.set(null);
          this.#messageService.add({
            severity: 'success',
            summary: this.#translateService.instant('COMMON.SUCCESS'),
            detail: this.#translateService.instant('USER.SUCCESS.PROFILE_PICTURE_DELETED'),
          });
        } catch (error) {
          this.#messageService.add({
            severity: 'error',
            summary: this.#translateService.instant('COMMON.ERROR'),
            detail: this.#translateService.instant('USER.ERROR.DELETE_PROFILE_PICTURE_FAILED'),
          });
        }
      },
    });
  }
}

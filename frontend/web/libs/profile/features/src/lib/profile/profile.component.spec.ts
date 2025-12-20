import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ProfileComponent } from './profile.component';
import { AuthStore } from '@web/auth/data-access';
import { UsersStore } from '@web/users/data-access';
import { signal } from '@angular/core';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { MessageService } from 'primeng/api';
import { LanguageService } from '@web/shared/util';
import { FormsModule } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { Subject } from 'rxjs';

describe('ProfileComponent', () => {
  let component: ProfileComponent;
  let fixture: ComponentFixture<ProfileComponent>;
  let usersStoreMock: { update: jest.Mock };
  let authStoreMock: {
    user: ReturnType<typeof signal>;
    currentUser: jest.Mock;
  };
  let messageServiceMock: {
    add: jest.Mock;
    messageObserver: unknown;
    clearObserver: unknown;
    clear: jest.Mock;
  };
  let languageServiceMock: {
    getAvailableLanguages: jest.Mock;
    getCurrentLanguage: jest.Mock;
    setLanguage: jest.Mock;
  };

  const mockUser = {
    id: '1',
    firstname: 'John',
    lastname: 'Doe',
    fullName: 'John Doe',
    email: 'john.doe@example.com',
    status: 'VERIFIED' as const,
    roles: ['ROLE_USER' as const],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  beforeEach(async () => {
    authStoreMock = {
      user: signal(mockUser),
      currentUser: jest.fn().mockResolvedValue(undefined),
    };

    usersStoreMock = {
      update: jest.fn().mockResolvedValue(undefined),
    };

    const messageSubject = new Subject();
    messageServiceMock = {
      add: jest.fn(),
      messageObserver: messageSubject.asObservable(),
      clearObserver: new Subject().asObservable(),
      clear: jest.fn(),
    };

    languageServiceMock = {
      getAvailableLanguages: jest.fn().mockReturnValue([
        { code: 'fr', label: 'Français' },
        { code: 'en', label: 'English' },
      ]),
      getCurrentLanguage: jest.fn().mockReturnValue('fr'),
      setLanguage: jest.fn(),
    };

    await TestBed.configureTestingModule({
      imports: [ProfileComponent, FormsModule, TranslateModule.forRoot()],
      providers: [
        { provide: AuthStore, useValue: authStoreMock },
        { provide: UsersStore, useValue: usersStoreMock },
        { provide: LanguageService, useValue: languageServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(ProfileComponent, {
        set: {
          providers: [
            { provide: MessageService, useValue: messageServiceMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(ProfileComponent);
    component = fixture.componentInstance;
    fixture.detectChanges(); // Déclencher l'effect() pour initialiser les données
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('toggleEditInfo', () => {
    it('should toggle edit mode from false to true', () => {
      expect(component.isEditingInfo()).toBe(false);

      component.toggleEditInfo();
      expect(component.isEditingInfo()).toBe(true);
    });

    it('should toggle edit mode from true to false and reload user data', () => {
      component.isEditingInfo.set(true);
      component.profileInfoModel.set({
        firstname: 'Modified',
        lastname: 'Data',
        email: 'modified@example.com',
      });

      component.toggleEditInfo();

      expect(component.isEditingInfo()).toBe(false);
      expect(component.profileInfoModel().firstname).toBe('John');
      expect(component.profileInfoModel().lastname).toBe('Doe');
      expect(component.profileInfoModel().email).toBe('john.doe@example.com');
    });

    it('should toggle edit mode from true to false even if user is null', () => {
      component.isEditingInfo.set(true);
      component.profileInfoModel.set({
        firstname: 'Modified',
        lastname: 'Data',
        email: 'modified@example.com',
      });

      // Mocker user() pour retourner null
      authStoreMock.user.set(null as any);

      component.toggleEditInfo();

      expect(component.isEditingInfo()).toBe(false);
      // Les données modifiées restent car l'utilisateur est null
      expect(component.profileInfoModel().firstname).toBe('Modified');
      expect(component.profileInfoModel().lastname).toBe('Data');

      // Restaurer le mock pour les autres tests
      authStoreMock.user.set(mockUser);
    });
  });

  describe('togglePasswordChange', () => {
    it('should toggle password change mode from false to true', () => {
      expect(component.isChangingPassword()).toBe(false);

      component.togglePasswordChange();
      expect(component.isChangingPassword()).toBe(true);
    });

    it('should toggle password change mode from true to false and clear fields', () => {
      component.isChangingPassword.set(true);
      component.passwordChangeModel.set({
        currentPassword: 'oldPass',
        newPassword: 'newPass',
        confirmPassword: 'newPass',
      });

      component.togglePasswordChange();

      expect(component.isChangingPassword()).toBe(false);
      expect(component.passwordChangeModel().currentPassword).toBe('');
      expect(component.passwordChangeModel().newPassword).toBe('');
      expect(component.passwordChangeModel().confirmPassword).toBe('');
    });
  });

  describe('profileInfoModel initialization', () => {
    it('should initialize profileInfoModel from user signal', () => {
      expect(component.profileInfoModel().firstname).toBe('John');
      expect(component.profileInfoModel().lastname).toBe('Doe');
      expect(component.profileInfoModel().email).toBe('john.doe@example.com');
      expect(component.status()).toBe('VERIFIED');
      expect(component.roles()).toEqual(['ROLE_USER']);
    });
  });

  describe('saveInfo', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      component.isEditingInfo.set(true);
    });

    it('should not save if form is invalid', () => {
      component.profileInfoModel.set({
        firstname: '',
        lastname: '',
        email: '',
      });
      fixture.detectChanges();

      component.saveInfo();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'PROFILE.WARNING.FILL_REQUIRED',
      });
      expect(usersStoreMock.update).not.toHaveBeenCalled();
      expect(component.isEditingInfo()).toBe(true);
    });

    it('should save user info with correct parameters on valid form', async () => {
      component.profileInfoModel.set({
        firstname: 'Jane',
        lastname: 'Smith',
        email: 'jane.smith@example.com',
      });
      fixture.detectChanges();

      await component.saveInfo();

      expect(usersStoreMock.update).toHaveBeenCalledTimes(1);
      expect(usersStoreMock.update).toHaveBeenCalledWith({
        ...mockUser,
        firstname: 'Jane',
        lastname: 'Smith',
        fullName: 'Jane Smith',
        email: 'jane.smith@example.com',
      });
      expect(authStoreMock.currentUser).toHaveBeenCalledTimes(1);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'PROFILE.SUCCESS.UPDATED',
      });
      expect(component.isEditingInfo()).toBe(false);
    });

    it('should save user info without form parameter', async () => {
      component.profileInfoModel.set({
        firstname: 'Jane',
        lastname: 'Smith',
        email: 'jane.smith@example.com',
      });
      fixture.detectChanges();

      await component.saveInfo();

      expect(usersStoreMock.update).toHaveBeenCalledTimes(1);
      expect(usersStoreMock.update).toHaveBeenCalledWith({
        ...mockUser,
        firstname: 'Jane',
        lastname: 'Smith',
        fullName: 'Jane Smith',
        email: 'jane.smith@example.com',
      });
      expect(authStoreMock.currentUser).toHaveBeenCalledTimes(1);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'PROFILE.SUCCESS.UPDATED',
      });
      expect(component.isEditingInfo()).toBe(false);
    });

    it('should handle error when saving fails', async () => {
      component.profileInfoModel.set({
        firstname: 'Jane',
        lastname: 'Smith',
        email: 'jane.smith@example.com',
      });
      fixture.detectChanges();

      const error = new Error('Save failed');
      usersStoreMock.update.mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.saveInfo();

      expect(usersStoreMock.update).toHaveBeenCalledTimes(1);
      expect(console.error).toHaveBeenCalledWith(
        'Error saving user info:',
        error
      );
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'PROFILE.ERROR.SAVE_FAILED',
      });
      expect(component.isEditingInfo()).toBe(true);

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('changePassword', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      component.isChangingPassword.set(true);
      fixture.detectChanges();
    });

    it('should not change password if form is invalid', () => {
      component.passwordChangeModel.set({
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      });
      fixture.detectChanges();

      component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'PROFILE.WARNING.FILL_REQUIRED',
      });
      expect(component.isChangingPassword()).toBe(true);
    });

    it('should not change password if passwords do not match', async () => {
      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'differentPassword',
      });
      fixture.detectChanges();

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'PROFILE.WARNING.PASSWORDS_MISMATCH',
      });
      expect(component.isChangingPassword()).toBe(true);
    });

    it('should not change password if new password is too short', async () => {
      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'short',
        confirmPassword: 'short',
      });
      fixture.detectChanges();
      await fixture.whenStable();

      await component.changePassword();

      // La validation minLength devrait échouer avant d'atteindre la vérification de correspondance
      // Donc on s'attend à FILL_REQUIRED car les champs ne passent pas la validation Signal Forms
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'PROFILE.WARNING.FILL_REQUIRED',
      });
      expect(component.isChangingPassword()).toBe(true);
    });

    it('should change password successfully with valid parameters', async () => {
      // Simuler l'entrée utilisateur en mettant à jour les field.value
      component.passwordChangeForm.currentPassword().value.set('oldPassword123');
      component.passwordChangeForm.newPassword().value.set('newPassword123');
      component.passwordChangeForm.confirmPassword().value.set('newPassword123');

      // Mettre à jour le model aussi pour la vérification de correspondance des mots de passe
      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      });
      fixture.detectChanges();

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'PROFILE.SUCCESS.PASSWORD_CHANGED',
      });
      expect(component.passwordChangeModel().currentPassword).toBe('');
      expect(component.passwordChangeModel().newPassword).toBe('');
      expect(component.passwordChangeModel().confirmPassword).toBe('');
      expect(component.isChangingPassword()).toBe(false);
    });

    it('should change password without form parameter', async () => {
      // Simuler l'entrée utilisateur
      component.passwordChangeForm.currentPassword().value.set('oldPassword123');
      component.passwordChangeForm.newPassword().value.set('newPassword123');
      component.passwordChangeForm.confirmPassword().value.set('newPassword123');

      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      });
      fixture.detectChanges();

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'PROFILE.SUCCESS.PASSWORD_CHANGED',
      });
      expect(component.passwordChangeModel().currentPassword).toBe('');
      expect(component.passwordChangeModel().newPassword).toBe('');
      expect(component.passwordChangeModel().confirmPassword).toBe('');
      expect(component.isChangingPassword()).toBe(false);
    });

    it('should accept password with length exactly 8', async () => {
      // Simuler l'entrée utilisateur
      component.passwordChangeForm.currentPassword().value.set('oldPass1');
      component.passwordChangeForm.newPassword().value.set('newPass1');
      component.passwordChangeForm.confirmPassword().value.set('newPass1');

      component.passwordChangeModel.set({
        currentPassword: 'oldPass1',
        newPassword: 'newPass1', // 8 caractères
        confirmPassword: 'newPass1',
      });
      fixture.detectChanges();

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'COMMON.SUCCESS',
        detail: 'PROFILE.SUCCESS.PASSWORD_CHANGED',
      });
      expect(component.isChangingPassword()).toBe(false);
    });

    it('should handle error when changing password fails', async () => {
      // Simuler l'entrée utilisateur
      component.passwordChangeForm.currentPassword().value.set('oldPassword123');
      component.passwordChangeForm.newPassword().value.set('newPassword123');
      component.passwordChangeForm.confirmPassword().value.set('newPassword123');

      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      });
      component.isChangingPassword.set(true);
      fixture.detectChanges();

      // Forcer une erreur en faisant planter messageService.add
      const error = new Error('Password change failed');
      jest.spyOn(console, 'error').mockImplementation();
      messageServiceMock.add.mockImplementationOnce(() => {
        throw error;
      });

      await component.changePassword();

      expect(console.error).toHaveBeenCalledWith('Error changing password:', error);
      // Le deuxième appel à messageService.add devrait afficher l'erreur
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'PROFILE.ERROR.PASSWORD_CHANGE_FAILED',
      });

      jest.spyOn(console, 'error').mockRestore();
    });
  });

  describe('onLanguageChange', () => {
    it('should call setLanguage when language is selected', () => {
      component.selectedLanguage = { code: 'en', label: 'English' };

      component.onLanguageChange();

      expect(languageServiceMock.setLanguage).toHaveBeenCalledWith('en');
    });

    it('should not call setLanguage when selectedLanguage is undefined', () => {
      component.selectedLanguage = undefined as any;

      component.onLanguageChange();

      expect(languageServiceMock.setLanguage).not.toHaveBeenCalled();
    });

    it('should not call setLanguage when code is undefined', () => {
      component.selectedLanguage = { code: undefined as any, label: 'English' };

      component.onLanguageChange();

      expect(languageServiceMock.setLanguage).not.toHaveBeenCalled();
    });
  });

  describe('selectedLanguage initialization', () => {
    it('should use fallback language when current language is not found', () => {
      // Mock getCurrentLanguage to return a language that doesn't exist in available languages
      languageServiceMock.getCurrentLanguage.mockReturnValue('de');
      languageServiceMock.getAvailableLanguages.mockReturnValue([
        { code: 'fr', label: 'Français' },
        { code: 'en', label: 'English' },
      ]);

      // Create a new component instance to test the initialization
      fixture = TestBed.createComponent(ProfileComponent);
      const newComponent = fixture.componentInstance;

      // Should fallback to the first available language
      expect(newComponent.selectedLanguage).toEqual({
        code: 'fr',
        label: 'Français',
      });
    });
  });

  describe('translation fallbacks', () => {
    it('should use fallback text when COMMON.WARNING translation returns undefined', async () => {
      const translateService = TestBed.inject(TranslateService);
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.WARNING') return undefined as any;
          return key as string;
        });

      component.profileInfoModel.set({
        firstname: '',
        lastname: '',
        email: '',
      });
      fixture.detectChanges();

      await component.saveInfo();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'Warning', // Fallback value
        detail: 'PROFILE.WARNING.FILL_REQUIRED',
      });
    });

    it('should use fallback text when COMMON.SUCCESS translation returns undefined in saveInfo', async () => {
      const translateService = TestBed.inject(TranslateService);
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.SUCCESS') return undefined as any;
          return key as string;
        });

      component.profileInfoModel.set({
        firstname: 'Jane',
        lastname: 'Smith',
        email: 'jane.smith@example.com',
      });
      fixture.detectChanges();

      await component.saveInfo();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'Success', // Fallback value
        detail: 'PROFILE.SUCCESS.UPDATED',
      });
    });

    it('should use fallback text when COMMON.ERROR translation returns undefined in saveInfo', async () => {
      const translateService = TestBed.inject(TranslateService);
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.ERROR') return undefined as any;
          return key as string;
        });

      component.profileInfoModel.set({
        firstname: 'Jane',
        lastname: 'Smith',
        email: 'jane.smith@example.com',
      });
      fixture.detectChanges();

      const error = new Error('Save failed');
      usersStoreMock.update.mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.saveInfo();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'Error', // Fallback value
        detail: 'PROFILE.ERROR.SAVE_FAILED',
      });

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should use fallback text when COMMON.SUCCESS translation returns undefined in changePassword', async () => {
      const translateService = TestBed.inject(TranslateService);
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.SUCCESS') return undefined as any;
          return key as string;
        });

      component.passwordChangeForm.currentPassword().value.set('oldPassword123');
      component.passwordChangeForm.newPassword().value.set('newPassword123');
      component.passwordChangeForm.confirmPassword().value.set('newPassword123');

      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      });
      fixture.detectChanges();

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'success',
        summary: 'Success', // Fallback value
        detail: 'PROFILE.SUCCESS.PASSWORD_CHANGED',
      });
    });

    it('should use fallback text when COMMON.ERROR translation returns undefined in changePassword', async () => {
      const translateService = TestBed.inject(TranslateService);
      jest
        .spyOn(translateService, 'instant')
        .mockImplementation((key: string | string[]) => {
          if (key === 'COMMON.ERROR') return undefined as any;
          return key as string;
        });

      component.passwordChangeForm.currentPassword().value.set('oldPassword123');
      component.passwordChangeForm.newPassword().value.set('newPassword123');
      component.passwordChangeForm.confirmPassword().value.set('newPassword123');

      component.passwordChangeModel.set({
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword123',
        confirmPassword: 'newPassword123',
      });
      component.isChangingPassword.set(true);
      fixture.detectChanges();

      const error = new Error('Password change failed');
      jest.spyOn(console, 'error').mockImplementation();
      messageServiceMock.add.mockImplementationOnce(() => {
        throw error;
      });

      await component.changePassword();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'Error', // Fallback value
        detail: 'PROFILE.ERROR.PASSWORD_CHANGE_FAILED',
      });

      jest.spyOn(console, 'error').mockRestore();
    });
  });
});

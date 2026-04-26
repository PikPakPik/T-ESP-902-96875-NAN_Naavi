import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoiUpsertComponent } from './poi-upsert.component';
import { POIsStore, POIsService } from '@web/pois/data-access';
import { Router, ActivatedRoute } from '@angular/router';
import { signal } from '@angular/core';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { MessageService } from 'primeng/api';
import { of, throwError } from 'rxjs';
import { POI } from '@web/shared/models/settings';
import { NgForm, FormsModule } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { UsersService } from '@web/users/data-access';

/** Jest/jsdom : FileList minimal (length + item) comme dans le navigateur. */
function fileListFromFiles(files: File[]): FileList {
  return {
    length: files.length,
    item: (i: number) => files[i] ?? null,
    ...files,
  } as unknown as FileList;
}

function fileInputChangeEvent(files: File[]): Event {
  return {
    target: { files: fileListFromFiles(files), value: '' },
  } as unknown as Event;
}

describe('PoiUpsertComponent', () => {
  let component: PoiUpsertComponent;
  let fixture: ComponentFixture<PoiUpsertComponent>;
  let poisStore: jest.Mocked<Partial<InstanceType<typeof POIsStore>>>;
  let router: jest.Mocked<Router>;
  let messageServiceMock: { add: jest.Mock };
  let translateServiceMock: { instant: jest.Mock };
  let usersServiceMock: {
    getUsers: jest.Mock;
    getUserById: jest.Mock;
  };
  let poisServiceMock: {
    uploadPoiImage: jest.Mock;
    deletePoiImage: jest.Mock;
  };

  const mockPOI = new POI({
    id: '1',
    name: 'Test POI',
    description: 'A test POI',
    types: ['RESTAURANT'],
    photos: [],
    latitude: 48.8566,
    longitude: 2.3522,
    comment: 'Test comment',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    status: 'ACTIVE',
  });

  beforeEach(async () => {
    // Jest (Node) : URL sans API blob — nécessaire pour les tests d’upload.
    Object.assign(URL, {
      createObjectURL: jest.fn().mockReturnValue('blob:mock-preview'),
      revokeObjectURL: jest.fn(),
    });

    messageServiceMock = {
      add: jest.fn(),
    };

    translateServiceMock = {
      instant: jest.fn((key: string) => key),
    };
    usersServiceMock = {
      getUsers: jest.fn(() =>
        of({
          usersInstances: [
            { id: '16', firstname: 'Jean', lastname: 'Dupont' },
          ],
        })
      ),
      getUserById: jest.fn(() =>
        of({ id: '16', firstname: 'Jean', lastname: 'Dupont' })
      ),
    };

    poisServiceMock = {
      uploadPoiImage: jest.fn(() => of(undefined)),
      deletePoiImage: jest.fn(() => of(undefined)),
    };

    const poisStoreMock = {
      entities: signal([]),
      point_of_interest_categories: signal(['RESTAURANT']),
      status: signal(['DRAFT', 'PUBLISHED']),
      sources: signal(['OFFICIAL', 'COMMUNITY']),
      create: jest.fn().mockResolvedValue(mockPOI),
      update: jest.fn().mockResolvedValue(undefined),
      getPOIById: jest.fn().mockResolvedValue(mockPOI),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    const activatedRouteMock = {
      params: of({ id: null }),
      snapshot: {
        params: {},
      },
    };

    await TestBed.configureTestingModule({
      imports: [PoiUpsertComponent, TranslateModule.forRoot(), FormsModule],
      providers: [
        { provide: POIsStore, useValue: poisStoreMock },
        { provide: POIsService, useValue: poisServiceMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
        { provide: TranslateService, useValue: translateServiceMock },
        { provide: UsersService, useValue: usersServiceMock },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(PoiUpsertComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu
          providers: [
            { provide: MessageService, useValue: messageServiceMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(PoiUpsertComponent);
    component = fixture.componentInstance;
    poisStore = TestBed.inject(POIsStore) as jest.Mocked<
      Partial<InstanceType<typeof POIsStore>>
    >;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should expose source options from store', () => {
    expect(component.sourceOptions()).toEqual([
      { label: 'OFFICIAL', value: 'OFFICIAL' },
      { label: 'COMMUNITY', value: 'COMMUNITY' },
    ]);
  });

  it('should expose the selected category and its icon path', () => {
    component.types.set(['WATER']);

    expect(component.getSelectedCategory()).toBe('WATER');
    expect(component.getSelectedCategoryIconPath()).toBe(
      '/assets/icons/poi/water.png'
    );
  });

  it('should update location when map is clicked', () => {
    component.onMapClick({ lngLat: { lng: 2.5, lat: 48.9 } });

    expect(component.longitude()).toBe(2.5);
    expect(component.latitude()).toBe(48.9);
  });

  it('should add a pending photo from file input', () => {
    const file = new File(['x'], 'shot.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));

    expect(component.photoSlots()).toHaveLength(1);
    expect(component.photoSlots()[0].kind).toBe('pending');
  });

  it('should warn and skip when file exceeds 5MB', () => {
    const buf = new Uint8Array(5 * 1024 * 1024 + 1);
    const file = new File([buf], 'huge.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));

    expect(component.photoSlots()).toHaveLength(0);
    expect(messageServiceMock.add).toHaveBeenCalledWith(
      expect.objectContaining({ severity: 'warn' })
    );
  });

  it('should remove a pending photo slot', async () => {
    const file = new File(['x'], 'a.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));

    component.removePhotoSlotAt(0);
    await Promise.resolve();
    await Promise.resolve();

    expect(component.photoSlots()).toHaveLength(0);
  });

  it('should navigate back when cancel is called', () => {
    component.cancel();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
  });

  it('should keep only one selected type', () => {
    component.onTypeChange('RESTAURANT');
    expect(component.types()).toEqual(['RESTAURANT']);

    component.onTypeChange('WATER');
    expect(component.types()).toEqual(['WATER']);

    component.onTypeChange(null);
    expect(component.types()).toEqual([]);
  });

  it('should create POI when savePOI is called in create mode', async () => {
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('OFFICIAL');

    await component.savePOI();

    expect(poisStore.create).toHaveBeenCalled();
    expect(poisStore.create).toHaveBeenCalledWith(
      expect.objectContaining({
        source: 'OFFICIAL',
        userId: null,
      })
    );
    expect(poisStore.create).toHaveBeenCalledWith(
      expect.not.objectContaining({ status: expect.anything() })
    );
    expect(poisStore.update).toHaveBeenCalledWith(
      expect.objectContaining({
        id: '1',
        status: 'PUBLISHED',
      })
    );
    expect(poisServiceMock.uploadPoiImage).not.toHaveBeenCalled();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
  });

  it('should upload pending photos after create then publish', async () => {
    const file = new File(['x'], 'a.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));

    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('OFFICIAL');

    await component.savePOI();

    expect(poisServiceMock.uploadPoiImage).toHaveBeenCalledWith('1', file);
    expect(poisStore.update).toHaveBeenCalled();
  });

  it('should upload pending photos after update in edit mode', async () => {
    const file = new File(['b'], 'b.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));
    component.isEditMode.set(true);
    component.poiId.set('1');
    component.name.set('Updated');
    component.description.set('Desc');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);

    await component.savePOI();

    expect(poisServiceMock.uploadPoiImage).toHaveBeenCalledWith('1', file);
  });

  it('getSlotDisplayUrl returns blob preview for pending slot', () => {
    const file = new File(['x'], 'z.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));
    expect(
      component.getSlotDisplayUrl(component.photoSlots()[0])
    ).toBe('blob:mock-preview');
  });

  it('getSlotDisplayUrl returns null for server filename without images base URL', () => {
    component.photoSlots.set([
      { kind: 'server', id: '', filename: 'POINTS_OF_INTEREST/1/a.png' },
    ]);
    expect(
      component.getSlotDisplayUrl(component.photoSlots()[0])
    ).toBeNull();
  });

  it('should call deletePoiImage when removing server photo in edit mode', async () => {
    component.isEditMode.set(true);
    component.poiId.set('10');
    component.photoSlots.set([
      { kind: 'server', id: '55', filename: 'POINTS_OF_INTEREST/10/f.png' },
    ]);
    component.removePhotoSlotAt(0);
    await Promise.resolve();
    await Promise.resolve();
    expect(poisServiceMock.deletePoiImage).toHaveBeenCalledWith('10', '55');
    expect(component.photoSlots()).toHaveLength(0);
  });

  it('onPhotoFilesSelected ignores empty file list', () => {
    component.onPhotoFilesSelected(
      { target: { files: null, value: '' } } as unknown as Event
    );
    expect(component.photoSlots()).toHaveLength(0);
  });

  it('onPhotoFilesSelected rejects non-image file', () => {
    const file = new File(['x'], 'doc.txt', { type: 'text/plain' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));
    expect(component.photoSlots()).toHaveLength(0);
    expect(messageServiceMock.add).toHaveBeenCalledWith(
      expect.objectContaining({ severity: 'warn' })
    );
  });

  it('should show error when photo upload fails after update', async () => {
    poisServiceMock.uploadPoiImage.mockReturnValueOnce(
      throwError(() => new Error('upload'))
    );
    const file = new File(['b'], 'b.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));
    component.isEditMode.set(true);
    component.poiId.set('1');
    component.name.set('U');
    component.description.set('D');
    component.latitude.set(48);
    component.longitude.set(2);
    component.types.set(['RESTAURANT']);

    await component.savePOI();

    expect(messageServiceMock.add).toHaveBeenCalledWith(
      expect.objectContaining({
        severity: 'error',
        detail: 'POI.ERROR.PHOTO_UPLOAD_FAILED',
      })
    );
    expect(router.navigate).not.toHaveBeenCalled();
    poisServiceMock.uploadPoiImage.mockReturnValue(of(undefined));
  });

  it('should show error when photo upload fails after create', async () => {
    poisServiceMock.uploadPoiImage.mockReturnValueOnce(
      throwError(() => new Error('upload'))
    );
    const file = new File(['b'], 'b.png', { type: 'image/png' });
    component.onPhotoFilesSelected(fileInputChangeEvent([file]));
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('OFFICIAL');

    await component.savePOI();

    expect(messageServiceMock.add).toHaveBeenCalledWith(
      expect.objectContaining({
        severity: 'error',
        detail: 'POI.ERROR.PHOTO_UPLOAD_FAILED',
      })
    );
    expect(router.navigate).not.toHaveBeenCalled();
    poisServiceMock.uploadPoiImage.mockReturnValue(of(undefined));
  });

  it('onSourceChange community without owner sets display Communauté', async () => {
    component.selectedUserId.set(null);
    await component.onSourceChange('COMMUNITY');
    expect(component.ownerDisplay()).toBe('Communauté');
  });

  it('delegates category and status translation keys', () => {
    expect(component.getCategoryTranslationKey('RESTAURANT')).toContain(
      'POI.CATEGORY'
    );
    expect(component.getStatusTranslationKey('DRAFT')).toContain('POI.STATUS');
  });

  it('onOwnerUserChange shows introuvable when user fetch fails', async () => {
    usersServiceMock.getUserById.mockReturnValueOnce(
      throwError(() => new Error('x'))
    );
    await component.onOwnerUserChange('99');
    expect(component.ownerDisplay()).toContain('introuvable');
    usersServiceMock.getUserById.mockReturnValue(
      of({ id: '16', firstname: 'Jean', lastname: 'Dupont' })
    );
  });

  it('loadPOIForEdit maps images from API to server photo slots', async () => {
    const poiWithImg = new POI({
      id: '3',
      name: 'P',
      description: 'D',
      types: ['WATER'],
      photos: [],
      images: [{ id: '9', filename: 'POINTS_OF_INTEREST/3/x.png' }],
      latitude: 48,
      longitude: 2,
      comment: '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      status: 'DRAFT',
    });
    (poisStore.entities as any) = signal([poiWithImg]);

    await component.loadPOIForEdit('3');

    expect(component.photoSlots()).toEqual([
      expect.objectContaining({
        kind: 'server',
        id: '9',
        filename: 'POINTS_OF_INTEREST/3/x.png',
      }),
    ]);
  });

  it('should require an owner when source is community', async () => {
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('COMMUNITY');
    component.selectedUserId.set(null);

    await component.savePOI();

    expect(poisStore.create).not.toHaveBeenCalled();
    expect(messageServiceMock.add).toHaveBeenCalledWith(
      expect.objectContaining({ severity: 'warn' })
    );
  });

  it('should create community POI with selected owner', async () => {
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('COMMUNITY');
    component.selectedUserId.set('16');

    await component.savePOI();

    expect(poisStore.create).toHaveBeenCalledWith(
      expect.objectContaining({
        source: 'COMMUNITY',
        userId: '16',
      })
    );
    expect(poisStore.update).toHaveBeenCalledWith(
      expect.objectContaining({
        id: '1',
        status: 'PUBLISHED',
      })
    );
  });

  it('should abort when create does not return an id', async () => {
    (poisStore.create as jest.Mock).mockResolvedValueOnce(undefined);
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);
    component.source.set('OFFICIAL');

    await component.savePOI();

    expect(poisStore.create).toHaveBeenCalled();
    expect(poisStore.update).not.toHaveBeenCalled();
    expect(router.navigate).not.toHaveBeenCalled();
  });

  it('should update POI when savePOI is called in edit mode', async () => {
    component.isEditMode.set(true);
    component.poiId.set('1');
    component.name.set('Updated POI');
    component.description.set('Updated description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['INFORMATION']);

    await component.savePOI();

    expect(poisStore.update).toHaveBeenCalled();
    expect(poisStore.update).toHaveBeenCalledWith(
      expect.objectContaining({ status: 'DRAFT' })
    );
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
  });

  it('should not save POI when required fields are missing', async () => {
    component.name.set('');
    component.description.set('');

    await component.savePOI();

    expect(poisStore.create).not.toHaveBeenCalled();
    expect(poisStore.update).not.toHaveBeenCalled();
  });

  describe('savePOI', () => {
    beforeEach(() => {
      jest.clearAllMocks();
      component.name.set('Test POI');
      component.description.set('Test description');
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);
    });

    it('should not save when form is invalid', async () => {
      const mockForm = {
        valid: false,
        control: {
          markAllAsTouched: jest.fn(),
        },
      } as unknown as NgForm;

      component.types.set(['RESTAURANT']);

      await component.savePOI(mockForm);

      expect(mockForm.control.markAllAsTouched).toHaveBeenCalled();
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'POI.WARNING.FILL_REQUIRED',
      });
      expect(poisStore.create).not.toHaveBeenCalled();
      expect(poisStore.update).not.toHaveBeenCalled();
    });

    it('should not save when types are empty', async () => {
      component.types.set([]);

      await component.savePOI();

      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'warn',
        summary: 'COMMON.WARNING',
        detail: 'POI.WARNING.SELECT_TYPE',
      });
      expect(poisStore.create).not.toHaveBeenCalled();
      expect(poisStore.update).not.toHaveBeenCalled();
    });

    it('should handle error when saving fails in create mode', async () => {
      component.types.set(['RESTAURANT']);
      const error = new Error('Save failed');
      (poisStore.create as jest.Mock).mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.savePOI();

      expect(console.error).toHaveBeenCalledWith('Error saving POI:', error);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'POI.ERROR.SAVE_FAILED',
      });
      expect(router.navigate).not.toHaveBeenCalled();

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should handle error when saving fails in edit mode', async () => {
      component.isEditMode.set(true);
      component.poiId.set('1');
      component.types.set(['RESTAURANT']);
      const error = new Error('Update failed');
      (poisStore.update as jest.Mock).mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.savePOI();

      expect(console.error).toHaveBeenCalledWith('Error saving POI:', error);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'POI.ERROR.SAVE_FAILED',
      });
      expect(router.navigate).not.toHaveBeenCalled();

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should switch owner display when source changes to official', async () => {
      component.selectedUserId.set('16');

      await component.onSourceChange('OFFICIAL');

      expect(component.source()).toBe('OFFICIAL');
      expect(component.selectedUserId()).toBeNull();
      expect(component.ownerDisplay()).toBe('Officielle');
    });

    it('should resolve owner display when owner user changes', async () => {
      await component.onOwnerUserChange('16');

      expect(component.selectedUserId()).toBe('16');
      expect(component.ownerDisplay()).toBe('(#16) DUPONT Jean');
    });
  });

  describe('loadPOIForEdit', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should load POI from store if available', async () => {
      (poisStore.entities as any) = signal([mockPOI]);

      await component.loadPOIForEdit('1');

      expect(component.isEditMode()).toBe(true);
      expect(component.poiId()).toBe('1');
      expect(component.name()).toBe('Test POI');
      expect(component.description()).toBe('A test POI');
      expect(poisStore.getPOIById).not.toHaveBeenCalled();
    });

    it('should load POI from service if not in store', async () => {
      (poisStore.entities as any) = signal([]);

      await component.loadPOIForEdit('1');

      expect(component.isEditMode()).toBe(true);
      expect(poisStore.getPOIById).toHaveBeenCalledWith('1');
    });

    it('should handle error when loading POI fails', async () => {
      (poisStore.entities as any) = signal([]);
      const error = new Error('POI not found');
      (poisStore.getPOIById as jest.Mock).mockRejectedValueOnce(error);
      jest.spyOn(console, 'error').mockImplementation();

      await component.loadPOIForEdit('999');

      expect(console.error).toHaveBeenCalledWith('Error loading POI:', error);
      expect(messageServiceMock.add).toHaveBeenCalledWith({
        severity: 'error',
        summary: 'COMMON.ERROR',
        detail: 'POI.ERROR.LOAD_FAILED',
      });

      jest.spyOn(console, 'error').mockRestore();
    });

    it('should handle POI with optional fields', async () => {
      const poiWithoutOptional = new POI({
        id: '2',
        name: 'POI without optional',
        description: 'Description',
        types: ['RESTAURANT'],
        photos: [],
        latitude: 48.8566,
        longitude: 2.3522,
        comment: '',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        status: 'ACTIVE',
      });
      (poisStore.entities as any) = signal([poiWithoutOptional]);

      await component.loadPOIForEdit('2');

      expect(component.comment()).toBe('');
      expect(component.photoSlots()).toEqual([]);
      expect(component.status()).toBe('ACTIVE');
    });
  });

  describe('updateMapCenter', () => {
    it('should update map center coordinates', () => {
      component.latitude.set(48.8566);
      component.longitude.set(2.3522);

      component.updateMapCenter();

      expect(component.mapCenter).toEqual([2.3522, 48.8566]);
    });
  });
});

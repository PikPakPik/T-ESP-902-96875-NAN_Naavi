import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoiUpsertComponent } from './poi-upsert.component';
import { POIsStore } from '@web/pois/data-access';
import { Router, ActivatedRoute } from '@angular/router';
import { signal } from '@angular/core';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { MessageService } from 'primeng/api';
import { of } from 'rxjs';
import { POI } from '@web/shared/models/settings';
import { NgForm, FormsModule } from '@angular/forms';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('PoiUpsertComponent', () => {
  let component: PoiUpsertComponent;
  let fixture: ComponentFixture<PoiUpsertComponent>;
  let poisStore: jest.Mocked<Partial<InstanceType<typeof POIsStore>>>;
  let router: jest.Mocked<Router>;
  let messageServiceMock: { add: jest.Mock };
  let translateServiceMock: { instant: jest.Mock };

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
    messageServiceMock = {
      add: jest.fn(),
    };

    translateServiceMock = {
      instant: jest.fn((key: string) => key),
    };

    const poisStoreMock = {
      entities: signal([]),
      create: jest.fn().mockResolvedValue(undefined),
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
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
        { provide: TranslateService, useValue: translateServiceMock },
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

  it('should update location when map is clicked', () => {
    component.onMapClick({ lngLat: { lng: 2.5, lat: 48.9 } });

    expect(component.longitude()).toBe(2.5);
    expect(component.latitude()).toBe(48.9);
  });

  it('should add a photo URL', () => {
    component.photos.set(['https://example.com/photo.jpg']);
    const initialLength = component.photos().length;

    component.addPhoto('https://example.com/photo1.jpg');

    expect(component.photos()).toHaveLength(initialLength + 1);
    expect(component.photos()).toContainEqual('https://example.com/photo.jpg');
  });

  it('should not add empty photo URL', () => {
    component.photos.set([]);
    const initialLength = component.photos().length;

    component.addPhoto('');

    expect(component.photos()).toHaveLength(initialLength);
  });

  it('should remove a photo', () => {
    component.photos.set(['photo1.jpg', 'photo2.jpg', 'photo3.jpg']);

    component.removePhoto(1);

    expect(component.photos()).toHaveLength(2);
    expect(component.photos()).not.toContain('photo2.jpg');
  });

  it('should navigate back when cancel is called', () => {
    component.cancel();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
  });

  it('should create POI when savePOI is called in create mode', async () => {
    component.name.set('Test POI');
    component.description.set('Test description');
    component.latitude.set(48.8566);
    component.longitude.set(2.3522);
    component.types.set(['RESTAURANT']);

    await component.savePOI();

    expect(poisStore.create).toHaveBeenCalled();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
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
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/pois']);
  });

  it('should not save POI when required fields are missing', async () => {
    component.name.set('');
    component.description.set('');

    await component.savePOI();

    expect(poisStore.create).not.toHaveBeenCalled();
    expect(poisStore.update).not.toHaveBeenCalled();
  });

  describe('addPhoto', () => {
    it('should not add photo URL when it is only whitespace', () => {
      component.photos.set([]);
      const initialLength = component.photos().length;

      component.addPhoto('   ');

      expect(component.photos()).toHaveLength(initialLength);
    });

    it('should not add duplicate photo URL', () => {
      component.photos.set(['https://example.com/photo.jpg']);

      component.addPhoto('https://example.com/photo.jpg');

      expect(component.photos()).toHaveLength(1);
      expect(component.photos()).toEqual(['https://example.com/photo.jpg']);
    });
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
      expect(component.photos()).toEqual([]);
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

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HikeDetailComponent } from './hike-detail.component';
import { HikeDetailStore } from '@web/hikes/data-access';
import { Router, ActivatedRoute } from '@angular/router';
import { signal } from '@angular/core';
import { Hike } from '@web/shared/models/settings';
import { TranslateModule } from '@ngx-translate/core';
import { of } from 'rxjs';
import { IMAGES_BASE_URL } from '@web/shared/http-client';

describe('HikeDetailComponent', () => {
  let component: HikeDetailComponent;
  let fixture: ComponentFixture<HikeDetailComponent>;
  let router: jest.Mocked<Router>;

  const mockHike = new Hike({
    id: '1',
    name: 'Test Hike',
    startingPointLatitude: 48.8566,
    startingPointLongitude: 2.3522,
    startingElevation: 100,
    arrivalPointLatitude: 48.86,
    arrivalPointLongitude: 2.355,
    arrivalElevation: 150,
    wkbGeometry: '',
    wkbWaypoints: '',
    distance: 5000,
    difficulty: 'EASY',
    status: 'PUBLISHED',
    source: 'OFFICIAL',
    seasons: ['SPRING', 'SUMMER', 'FALL', 'WINTER'],
    location: 'Paris',
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
  });

  beforeEach(async () => {
    const hikeDetailStoreMock = {
      hike: signal(mockHike),
      isPending: signal(false),
    };

    const routerMock = {
      navigate: jest.fn(),
    };

    const activatedRouteMock = {
      params: of({ id: '1' }),
      snapshot: {
        params: { id: '1' },
      },
    };

    await TestBed.configureTestingModule({
      imports: [HikeDetailComponent, TranslateModule.forRoot()],
      providers: [
        { provide: HikeDetailStore, useValue: hikeDetailStoreMock },
        { provide: Router, useValue: routerMock },
        { provide: ActivatedRoute, useValue: activatedRouteMock },
        { provide: IMAGES_BASE_URL, useValue: 'https://cdn.example.com/' },
      ],
    })
      .overrideComponent(HikeDetailComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu
          providers: [
            { provide: HikeDetailStore, useValue: hikeDetailStoreMock },
            { provide: ActivatedRoute, useValue: activatedRouteMock },
          ],
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(HikeDetailComponent);
    component = fixture.componentInstance;
    router = TestBed.inject(Router) as jest.Mocked<Router>;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should navigate back to hikes list when goBack is called', () => {
    component.goBack();
    expect(router.navigate).toHaveBeenCalledWith(['/backoffice/hikes']);
  });

  it('should return visibility labels for known and unknown values', () => {
    expect(component.getVisibilityLabel(undefined)).toBe('Public');
    expect(component.getVisibilityLabel('PRIVATE')).toBe('Privé');
    expect(component.getVisibilityLabel('UNLISTED')).toBe('Non listée');
    expect(component.getVisibilityLabel('TEAM_ONLY')).toBe('TEAM_ONLY');
  });

  it('should return owner labels for official and community hikes', () => {
    expect(component.getOwnerLabel(undefined)).toBe('Officielle');
    expect(component.getOwnerLabel('16')).toBe('User #16');
  });

  it('should build image URLs correctly', () => {
    expect(component.getHikeImageUrl(undefined)).toBeNull();
    expect(component.getHikeImageUrl('https://external.test/img.jpg')).toBe(
      'https://external.test/img.jpg'
    );
    expect(component.getHikeImageUrl('/uploads/hike.jpg')).toBe(
      'https://cdn.example.com/uploads/hike.jpg'
    );
  });

  it('should fall back to a placeholder image when no hike image exists', () => {
    expect(component.getPrimaryImageUrl()).toContain(
      'https://via.placeholder.com/1200x500?text=Test%20Hike'
    );
  });

  it('should use the first hike image when available', () => {
    mockHike.images = [
      {
        id: 1,
        filename: '/uploads/primary.jpg',
        createdAt: '2024-01-01T00:00:00.000Z',
      },
    ];

    expect(component.getPrimaryImageUrl()).toBe(
      'https://cdn.example.com/uploads/primary.jpg'
    );
  });

  // Tests removed: coordinatesToGeoJSON, getMapCenter, getMapBounds methods don't exist on HikeDetailComponent
  // These methods exist on HikeMapComponent instead
});

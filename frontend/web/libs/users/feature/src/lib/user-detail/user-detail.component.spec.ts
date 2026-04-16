import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserDetailComponent } from './user-detail.component';
import { User, HikeHistoryItem } from '@web/shared/models/settings';
import { Point, LineString } from 'wkx-ts';
import { Buffer } from 'buffer/';

describe('UserDetailComponent', () => {
  let component: UserDetailComponent;
  let fixture: ComponentFixture<UserDetailComponent>;

  const mockUser: User = {
    id: '1',
    firstname: 'John',
    lastname: 'Doe',
    fullName: 'John Doe',
    email: 'john.doe@example.com',
    status: 'VERIFIED',
    roles: ['ROLE_USER'],
  } as User;

  const mockHistory: HikeHistoryItem[] = [
    {
      id: '10',
      hike: 'Mont Blanc',
      createdAt: '2024-01-01T10:00:00Z',
      duration: 7200,
    } as unknown as HikeHistoryItem,
  ];

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserDetailComponent],
    })
      .overrideComponent(UserDetailComponent, {
        set: {
          // Template simplifié pour éviter les dépendances complexes (translate pipe, PrimeNG, etc.)
          template: '<div>user-detail-stub</div>',
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(UserDetailComponent);
    component = fixture.componentInstance;
  });

  it('Given page change event When onPageChange is called Then should emit incremented page and same rows', () => {
    // GIVEN
    const emitSpy = jest.spyOn(component.pageChange, 'emit');
    const event = { page: 0, rows: 20 };

    // WHEN
    component.onPageChange(event);

    // THEN
    expect(emitSpy).toHaveBeenCalledWith({ page: 1, rows: 20 });
  });

  describe('visual state', () => {
    it('Given user and history When rendering component Then should display user card and history table', () => {
      // GIVEN
      fixture.componentRef.setInput('user', mockUser);
      fixture.componentRef.setInput('loadingUser', false);
      fixture.componentRef.setInput('history', mockHistory);
      fixture.componentRef.setInput('loadingHistory', false);
      fixture.componentRef.setInput('totalHistory', mockHistory.length);

      // WHEN
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });

    it('Given loading user state When rendering component Then should display skeleton loader', () => {
      // GIVEN
      fixture.componentRef.setInput('loadingUser', true);

      // WHEN
      fixture.detectChanges();

      // THEN
      expect(fixture).toMatchSnapshot();
    });
  });

  describe('history detail interactions', () => {
    it('Given history item without trace When opening detail Then should open dialog and keep empty trace', () => {
      // GIVEN
      const item = mockHistory[0];

      // WHEN
      component.openHistoryDetail(item);

      // THEN
      expect(component.historyDialogVisible()).toBe(true);
      expect(component.selectedHistory()).toEqual(item);
      expect(component.traceCoordinates()).toEqual([]);
    });

    it('Given history item with point WKB When opening detail Then should decode point trace', () => {
      // GIVEN
      const pointWkb = Buffer.from(new Point(2.35, 48.85).toWkb() as Buffer).toString(
        'hex'
      );
      const item = {
        ...mockHistory[0],
        wkbGeometry: pointWkb,
      } as HikeHistoryItem;

      // WHEN
      component.openHistoryDetail(item);

      // THEN
      expect(component.traceCoordinates()).toEqual([[2.35, 48.85]]);
      expect(component.mapCenter()).toEqual([2.35, 48.85]);
      expect(component.traceGeoJson().features[0]?.geometry.type).toBe('Point');
    });

    it('Given history item with line WKB When opening detail Then should decode line trace', () => {
      // GIVEN
      const lineWkb = Buffer.from(
        new LineString([new Point(2.35, 48.85), new Point(2.36, 48.86)]).toWkb() as Buffer
      ).toString('hex');
      const item = {
        ...mockHistory[0],
        wkbGeometry: lineWkb,
      } as HikeHistoryItem;

      // WHEN
      component.openHistoryDetail(item);

      // THEN
      expect(component.traceCoordinates()).toEqual([
        [2.35, 48.85],
        [2.36, 48.86],
      ]);
      expect(component.traceGeoJson().features[0]?.geometry.type).toBe('LineString');
    });

    it('Given opened detail When closing detail Then should reset selection and trace', () => {
      // GIVEN
      component.openHistoryDetail(mockHistory[0]);

      // WHEN
      component.closeHistoryDetail();

      // THEN
      expect(component.historyDialogVisible()).toBe(false);
      expect(component.selectedHistory()).toBeNull();
      expect(component.traceCoordinates()).toEqual([]);
    });
  });

  describe('metrics formatting', () => {
    it('Given undefined distance When converting distance Then should return null', () => {
      expect(component.distanceInKm(undefined)).toBeNull();
    });

    it('Given distance in meters When converting distance Then should return kilometers rounded to 2 decimals', () => {
      expect(component.distanceInKm(12345)).toBe(12.35);
    });
  });
});

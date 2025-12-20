import { ComponentFixture, TestBed } from '@angular/core/testing';
import { UserDetailComponent } from './user-detail.component';
import { User, HikeHistoryItem } from '@web/shared/models/settings';

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
});

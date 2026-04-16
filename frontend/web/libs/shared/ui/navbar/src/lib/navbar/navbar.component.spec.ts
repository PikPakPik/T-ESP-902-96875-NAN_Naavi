import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter, ActivatedRoute, Router } from '@angular/router';
import { of } from 'rxjs';
import { NavbarComponent } from './navbar.component';
import { MenuItem } from 'primeng/api';
import { NO_ERRORS_SCHEMA } from '@angular/core';

const mockActivatedRoute = {
  snapshot: {},
  url: of([]),
  paramMap: of(new Map()),
  queryParamMap: of(new Map()),
  outlet: 'primary',
  component: null,
  routeConfig: null,
  root: {} as ActivatedRoute,
  parent: null,
  firstChild: null,
  children: [],
  pathFromRoot: [],
  params: of({}),
  queryParams: of({}),
} as unknown as ActivatedRoute;

@Component({
  template: `<navigation [menuItems]="menuItems" [userMenuItems]="userMenuItems" />`,
  standalone: true,
  imports: [NavbarComponent],
})
class TestHost {
  menuItems: MenuItem[] = [];
  userMenuItems: MenuItem[] = [];
}

describe('NavbarComponent', () => {
  let component: NavbarComponent;
  let hostFixture: ComponentFixture<TestHost>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NavbarComponent, TestHost],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        provideRouter([]),
        { provide: ActivatedRoute, useValue: mockActivatedRoute },
      ],
    })
      .overrideComponent(NavbarComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu PrimeNG
        },
      })
      .compileComponents();

    hostFixture = TestBed.createComponent(TestHost);
    component = hostFixture.debugElement.children[0].componentInstance;
  });

  it('should create', () => {
    hostFixture.detectChanges();
    expect(component).toBeTruthy();
  });

  describe('onItemClick', () => {
    it('should emit itemClick event', () => {
      hostFixture.detectChanges();
      const mockItem: MenuItem = {
        label: 'Test Item',
        icon: 'pi pi-test',
      };
      const emitSpy = jest.spyOn(component.itemClick, 'emit');

      component.onItemClick(mockItem);

      expect(emitSpy).toHaveBeenCalledWith(mockItem);
    });

    it('should call command function if provided', () => {
      hostFixture.detectChanges();
      const mockCommand = jest.fn();
      const mockItem: MenuItem = {
        label: 'Test Item',
        command: mockCommand,
      };
      const emitSpy = jest.spyOn(component.itemClick, 'emit');

      component.onItemClick(mockItem);

      expect(emitSpy).toHaveBeenCalledWith(mockItem);
      expect(mockCommand).toHaveBeenCalledWith({});
    });

    it('should work without command function', () => {
      hostFixture.detectChanges();
      const mockItem: MenuItem = {
        label: 'Test Item',
      };
      const emitSpy = jest.spyOn(component.itemClick, 'emit');

      component.onItemClick(mockItem);

      expect(emitSpy).toHaveBeenCalledWith(mockItem);
    });
  });

  describe('mobileMenuModel / userMenuModel', () => {
    it('should transform routerLink to command in mobileMenuModel', () => {
      hostFixture.componentInstance.menuItems = [
        { label: 'Dashboard', icon: 'pi pi-home', routerLink: '' },
        { label: 'Users', icon: 'pi pi-users', routerLink: 'users' },
      ];
      hostFixture.componentInstance.userMenuItems = [];
      hostFixture.detectChanges();

      const model = component.mobileMenuModel();
      expect(model).toHaveLength(2);
      expect(model[0].command).toBeDefined();
      expect(model[0].routerLink).toBeUndefined();
      expect(model[1].command).toBeDefined();
    });

    it('should call router.navigate when command is executed', () => {
      const router = TestBed.inject(Router);
      const navigateSpy = jest.spyOn(router, 'navigate');

      hostFixture.componentInstance.menuItems = [
        { label: 'Users', routerLink: 'users' },
      ];
      hostFixture.detectChanges();
      const model = component.mobileMenuModel();
      model[0].command!({});

      expect(navigateSpy).toHaveBeenCalledWith(
        ['users'],
        expect.objectContaining({ relativeTo: mockActivatedRoute })
      );
    });

    it('should preserve nested items structure', () => {
      hostFixture.componentInstance.menuItems = [
        {
          label: 'Hikes',
          icon: 'pi pi-map',
          items: [
            { label: 'List', routerLink: 'hikes' },
            { label: 'New', routerLink: 'hikes/new' },
          ],
        },
      ];
      hostFixture.detectChanges();
      const model = component.mobileMenuModel();
      expect(model).toHaveLength(1);
      expect(model[0].items).toHaveLength(2);
      expect(model[0].items![0].command).toBeDefined();
      expect(model[0].items![1].command).toBeDefined();
    });

    it('should preserve command in userMenuModel', () => {
      hostFixture.componentInstance.userMenuItems = [
        { label: 'Profile', routerLink: 'profile' },
        { label: 'Logout', command: jest.fn() },
      ];
      hostFixture.detectChanges();
      const model = component.userMenuModel();
      expect(model[1].command).toBeDefined();
    });

    it('should handle routerLink as array', () => {
      const router = TestBed.inject(Router);
      const navigateSpy = jest.spyOn(router, 'navigate');

      hostFixture.componentInstance.menuItems = [
        { label: 'User detail', routerLink: ['users', '123'] },
      ];
      hostFixture.detectChanges();
      const model = component.mobileMenuModel();
      model[0].command!({});

      expect(navigateSpy).toHaveBeenCalledWith(
        ['users', '123'],
        expect.objectContaining({ relativeTo: mockActivatedRoute })
      );
    });

    it('should handle empty routerLink for dashboard', () => {
      const router = TestBed.inject(Router);
      const navigateSpy = jest.spyOn(router, 'navigate');

      hostFixture.componentInstance.menuItems = [
        { label: 'Dashboard', routerLink: '' },
      ];
      hostFixture.detectChanges();
      const model = component.mobileMenuModel();
      model[0].command!({});

      expect(navigateSpy).toHaveBeenCalledWith(
        [],
        expect.objectContaining({ relativeTo: mockActivatedRoute })
      );
    });
  });
});

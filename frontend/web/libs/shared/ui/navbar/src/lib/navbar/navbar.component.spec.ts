import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NavbarComponent } from './navbar.component';
import { MenuItem } from 'primeng/api';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('NavbarComponent', () => {
  let component: NavbarComponent;
  let fixture: ComponentFixture<NavbarComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [NavbarComponent],
      schemas: [NO_ERRORS_SCHEMA],
    })
      .overrideComponent(NavbarComponent, {
        set: {
          template: '', // Template vide pour éviter le rendu
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(NavbarComponent);
    component = fixture.componentInstance;
    // Ne pas appeler detectChanges() pour éviter le rendu du template
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('onItemClick', () => {
    it('should emit itemClick event', () => {
      const mockItem: MenuItem = {
        label: 'Test Item',
        icon: 'pi pi-test',
      };
      const emitSpy = jest.spyOn(component.itemClick, 'emit');

      component.onItemClick(mockItem);

      expect(emitSpy).toHaveBeenCalledWith(mockItem);
    });

    it('should call command function if provided', () => {
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
      const mockItem: MenuItem = {
        label: 'Test Item',
      };
      const emitSpy = jest.spyOn(component.itemClick, 'emit');

      component.onItemClick(mockItem);

      expect(emitSpy).toHaveBeenCalledWith(mockItem);
    });
  });
});

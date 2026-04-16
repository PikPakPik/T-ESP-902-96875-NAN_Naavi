import { ComponentFixture, TestBed } from '@angular/core/testing';
import { PoiMapComponent } from './poi-map.component';
import { NO_ERRORS_SCHEMA } from '@angular/core';

describe('PoiMapComponent', () => {
  let component: PoiMapComponent;
  let fixture: ComponentFixture<PoiMapComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PoiMapComponent],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(PoiMapComponent);
    component = fixture.componentInstance;

    // Set required inputs
    fixture.componentRef.setInput('latitude', 48.8566);
    fixture.componentRef.setInput('longitude', 2.3522);
    fixture.componentRef.setInput('poiId', 'test-poi-1');
    fixture.componentRef.setInput('category', 'WATER');

    // Don't call detectChanges() to avoid rendering mapbox-gl components
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should convert coordinates to GeoJSON', () => {
    const geoJSON = component.coordinatesToGeoJSON();

    expect(geoJSON.type).toBe('Feature');
    expect(geoJSON.geometry.type).toBe('Point');
    expect((geoJSON.geometry as any).coordinates).toEqual([2.3522, 48.8566]);
    expect(geoJSON.properties).toEqual({});
  });

  it('should return map center coordinates', () => {
    const center = component.getMapCenter();

    expect(center).toEqual([2.3522, 48.8566]);
    expect(center[0]).toBe(component.longitude());
    expect(center[1]).toBe(component.latitude());
  });

  it('should return the Flutter marker icon path from the category', () => {
    expect(component.getMarkerIconPath()).toBe('/assets/icons/poi/water.png');
  });

  it('should use category icon markers by default', () => {
    expect(component.useCategoryIcon()).toBe(true);
  });

  it('should update GeoJSON when inputs change', () => {
    fixture.componentRef.setInput('latitude', 50.123);
    fixture.componentRef.setInput('longitude', 3.456);
    // Don't call detectChanges() to avoid rendering mapbox-gl components

    const geoJSON = component.coordinatesToGeoJSON();
    expect((geoJSON.geometry as any).coordinates).toEqual([3.456, 50.123]);

    const center = component.getMapCenter();
    expect(center).toEqual([3.456, 50.123]);
  });
});

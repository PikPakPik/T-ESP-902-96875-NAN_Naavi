export type POIType =
  | 'RESTAURANT'
  | 'VIEWPOINT'
  | 'PARKING'
  | 'SHELTER'
  | 'WATER_SOURCE'
  | 'MONUMENT'
  | 'PICNIC_AREA'
  | 'INFORMATION'
  | 'DANGER'
  | 'OTHER';

export const POI_TYPES: { label: string; value: POIType }[] = [
  { label: 'Restaurant', value: 'RESTAURANT' },
  { label: 'Point de vue', value: 'VIEWPOINT' },
  { label: 'Parking', value: 'PARKING' },
  { label: 'Refuge', value: 'SHELTER' },
  { label: "Point d'eau", value: 'WATER_SOURCE' },
  { label: 'Monument', value: 'MONUMENT' },
  { label: 'Aire de pique-nique', value: 'PICNIC_AREA' },
  { label: 'Information', value: 'INFORMATION' },
  { label: 'Danger', value: 'DANGER' },
  { label: 'Autre', value: 'OTHER' },
];

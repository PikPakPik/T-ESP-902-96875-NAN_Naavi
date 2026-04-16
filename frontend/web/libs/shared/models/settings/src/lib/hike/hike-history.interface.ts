export interface HikeHistoryItem {
  id: string;
  hike: string;
  hikeId?: string;
  duration: number;
  distance?: number;
  elevationGain?: number;
  averageSpeed?: number;
  wkbGeometry?: string;
  startingPointLatitude?: number;
  startingPointLongitude?: number;
  arrivalPointLatitude?: number;
  arrivalPointLongitude?: number;
  createdAt: string;
}

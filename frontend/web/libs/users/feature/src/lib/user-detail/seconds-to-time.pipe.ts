import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'secondsToTimePipe',
  standalone: true,
})
export class SecondsToTimePipe implements PipeTransform {
  transform(totalSeconds: number | null | undefined): string {
    if (totalSeconds == null || isNaN(totalSeconds as number)) {
      return '';
    }

    const safeSeconds = Math.max(0, Math.floor(totalSeconds));

    // Affichage uniquement en secondes si strictement moins d'une minute
    if (safeSeconds < 60) {
      return `${safeSeconds}s`;
    }

    const hours = Math.floor(safeSeconds / 3600);
    const minutes = Math.floor((safeSeconds % 3600) / 60);

    if (hours === 0) {
      return `${minutes}min`;
    }

    if (minutes === 0) {
      return `${hours}h`;
    }

    return `${hours}h ${minutes}min`;
  }
}

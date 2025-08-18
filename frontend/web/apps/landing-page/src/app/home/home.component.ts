import { Component } from '@angular/core';

import { BadgeModule } from 'primeng/badge';
import { AvatarModule } from 'primeng/avatar';
import { MenubarModule } from 'primeng/menubar';
import { RippleModule } from 'primeng/ripple';
import { DividerModule } from 'primeng/divider';
import { TagModule } from 'primeng/tag';
import { CardModule } from 'primeng/card';
import { ButtonModule } from 'primeng/button';
import { ChipModule } from 'primeng/chip';
import { SplitButtonModule } from 'primeng/splitbutton';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
    ButtonModule,
    CardModule,
    MenubarModule,
    RippleModule,
    DividerModule,
    TagModule,
    AvatarModule,
    BadgeModule,
    ChipModule,
    SplitButtonModule
],
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss',
})
export class HomeComponent {
  title = 'NAavi - Votre solution de navigation intelligente';

  downloadItems = [
    {
      label: 'App Store',
      icon: 'pi pi-apple',
    },
    {
      label: 'Google Play',
      icon: 'pi pi-android',
    },
  ];

  features = [
    {
      icon: '🗺️',
      title: 'Cartes interactives',
      description:
        'Explorez des milliers de parcours avec nos cartes détaillées et navigation GPS précise.',
      color: 'linear-gradient(135deg, #4A5D23, #7FB069)',
    },
    {
      icon: '⚠️',
      title: 'Signalements temps réel',
      description:
        'Soyez alerté des dangers et incidents signalés par la communauté en temps réel.',
      color: 'linear-gradient(135deg, #F39C12, #E67E22)',
    },
    {
      icon: '👥',
      title: 'Communauté active',
      description:
        "Partagez vos expériences et découvrez de nouveaux parcours avec d'autres randonneurs.",
      color: 'linear-gradient(135deg, #3498DB, #2980B9)',
    },
    {
      icon: '🛡️',
      title: 'Sécurité renforcée',
      description:
        "Bouton d'urgence, géolocalisation et alertes automatiques pour votre sécurité.",
      color: 'linear-gradient(135deg, #E74C3C, #C0392B)',
    },
    {
      icon: '🏆',
      title: 'Gamification',
      description:
        'Gagnez des kilomètres virtuels, débloquez des badges et relevez des défis.',
      color: 'linear-gradient(135deg, #F1C40F, #F39C12)',
    },
    {
      icon: '📱',
      title: 'Mode hors-ligne',
      description:
        'Continuez à naviguer même sans connexion grâce au mode hors-ligne complet.',
      color: 'linear-gradient(135deg, #9B59B6, #8E44AD)',
    },
  ];

  poiTypes = [
    { icon: '🏪', label: 'Partenaire', color: '#4A5D23' },
    { icon: '📍', label: 'Endroit incontournable', color: '#7FB069' },
    { icon: '🏛️', label: 'Monument', color: '#A4C2A5' },
    { icon: '🥤', label: 'Ravitaillement', color: '#3498DB' },
    { icon: '💧', label: 'Eau', color: '#5DADE2' },
    { icon: '🏠', label: 'Hébergement', color: '#85C1E9' },
    { icon: '⛺', label: 'Camping', color: '#F39C12' },
    { icon: '🍽️', label: 'Restaurant', color: '#E74C3C' },
    { icon: '🚻', label: 'Toilettes', color: '#9B59B6' },
    { icon: '🅿️', label: 'Parking', color: '#34495E' },
  ];

  signalTypes = [
    { icon: '🚫', label: 'Passage inaccessible', color: '#F39C12' },
    { icon: '⚠️', label: 'Danger', color: '#E74C3C' },
    { icon: '🦌', label: "Passage d'animaux", color: '#F39C12' },
    { icon: '🧊', label: 'Terrain glissant', color: '#3498DB' },
    { icon: '🟤', label: 'Terrain boueux', color: '#8B4513' },
    { icon: '❄️', label: "Risque d'avalanche", color: '#85C1E9' },
  ];
}

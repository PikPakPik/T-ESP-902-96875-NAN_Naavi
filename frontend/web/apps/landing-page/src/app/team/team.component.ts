import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardModule } from 'primeng/card';
import { AvatarModule } from 'primeng/avatar';
import { BadgeModule } from 'primeng/badge';
import { ChipModule } from 'primeng/chip';
import { DividerModule } from 'primeng/divider';
import { ButtonModule } from 'primeng/button';

interface TeamMember {
  name: string;
  roles: string[];
  avatar?: string;
  email?: string;
  isRecruiting?: boolean;
}

@Component({
  selector: 'app-team',
  standalone: true,
  imports: [
    CommonModule,
    CardModule,
    AvatarModule,
    BadgeModule,
    ChipModule,
    DividerModule,
    ButtonModule,
  ],
  templateUrl: './team.component.html',
  styleUrls: ['./team.component.scss'],
})
export class TeamComponent {
  teamMembers: TeamMember[] = [
    {
      name: 'Eloi JAHAN',
      roles: ['Chef de projet', 'Responsable Qualité', 'Développeur mobile'],
      avatar: 'EJ',
      email: 'eloi.jahan@epitech.eu',
    },
    {
      name: 'Yann PLOUHINEC',
      roles: ['Responsable Qualité', 'Développeur mobile'],
      avatar: 'YP',
      email: 'yann.plouhinec@epitech.eu',
    },
    {
      name: 'Charlotte LAURENT',
      roles: ['Développeur mobile'],
      avatar: 'CL',
      email: 'charlotte.laurent@epitech.eu',
    },
    {
      name: 'Jean CLEMENTE RADIGOIS',
      roles: ['Développeur mobile'],
      avatar: 'JCR',
      email: 'jean.clemente-radigois@epitech.eu',
    },
    {
      name: 'Julien MERCOURT',
      roles: ['Développeur backend'],
      avatar: 'JM',
      email: 'julien.mercourt@epitech.eu',
    },
    {
      name: 'Raphael EOUZAN',
      roles: ['Développeur backend'],
      avatar: 'RE',
      email: 'raphael.eouzan@epitech.eu',
    },
    {
      name: 'Alexandre TRESSEL',
      roles: ['Développeur frontend', 'DevOps'],
      avatar: 'AT',
      email: 'alexandre.tressel@epitech.eu',
    },
    {
      name: 'Valentin RAGOT',
      roles: ['Développeur backend', 'DevOps'],
      avatar: 'VR',
      email: 'valentin.ragot@epitech.eu',
    },
  ];

  roleColors: { [key: string]: string } = {
    'Chef de projet': 'primary',
    'Responsable Qualité': 'success',
    'Développeur mobile': 'info',
    'Développeur front': 'secondary',
    'Développeur backend': 'warning',
    'Développeur back-office': 'warning',
    DevOps: 'danger',
  };

  getRoleColor(role: string): string {
    return this.roleColors[role] || 'secondary';
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .map((word) => word.charAt(0))
      .join('')
      .toUpperCase();
  }

  sendEmail(email?: string) {
    if (email) {
      window.location.href = `mailto:${email}`;
    }
  }
}

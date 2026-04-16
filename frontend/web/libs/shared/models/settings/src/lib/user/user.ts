import { Role } from './role';
import { Status } from './status';
import { IDB_User } from './user.interface';

export class User {
  id: IDB_User['id'];
  firstname: string;
  lastname: string;
  fullName: string;
  email: string;
  status: Status;
  roles: Role[];
  profilePicture: string | null;

  constructor(user: IDB_User) {
    this.id = user.id;
    this.firstname = user.firstname;
    this.lastname = user.lastname;
    this.email = user.email;
    this.status = user.status as Status;
    this.roles = user.roles as Role[];
    this.fullName = user.fullName;
    this.profilePicture = user.profilePicture ?? null;
  }
}

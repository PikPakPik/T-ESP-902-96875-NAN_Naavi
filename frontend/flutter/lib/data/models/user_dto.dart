/// Représente les données d'un utilisateur
class UserDto {
  final int? id;
  final String? firstname;
  final String? lastname;
  final String email;
  final List<String>? roles;
  final List<String>? permissions;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profilePicture;

  const UserDto({
    this.id,
    this.firstname,
    this.lastname,
    required this.email,
    this.roles,
    this.permissions,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.profilePicture,
  });

  /// Construit le nom complet à partir du prénom et du nom
  String get fullName {
    final parts = <String>[];
    if (firstname != null && firstname!.isNotEmpty) {
      parts.add(firstname!);
    }
    if (lastname != null && lastname!.isNotEmpty) {
      parts.add(lastname!);
    }
    return parts.isEmpty ? email : parts.join(' ');
  }

  /// Crée une instance de UserDto à partir d'une map JSON
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int?,
      firstname: json['firstname'] as String? ?? json['firstName'] as String?,
      lastname: json['lastname'] as String? ?? json['lastName'] as String?,
      email: json['email'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.cast<String>(),
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>(),
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  /// Convertit l'instance en map JSON pour l'envoi à l'API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (firstname != null) 'firstname': firstname,
      if (lastname != null) 'lastname': lastname,
      'email': email,
      if (roles != null) 'roles': roles,
      if (permissions != null) 'permissions': permissions,
      if (status != null) 'status': status,
      if (profilePicture != null) 'profilePicture': profilePicture,
    };
  }

  /// Crée une copie de l'instance avec des valeurs modifiées
  UserDto copyWith({
    int? id,
    String? firstname,
    String? lastname,
    String? email,
    List<String>? roles,
    List<String>? permissions,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePicture,
  }) {
    return UserDto(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  @override
  String toString() {
    return 'UserDto(id: $id, fullName: $fullName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDto &&
        other.id == id &&
        other.firstname == firstname &&
        other.lastname == lastname &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(id, firstname, lastname, email);
  }
}

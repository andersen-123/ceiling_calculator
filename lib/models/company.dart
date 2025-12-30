class Company {
  final int? id;
  final String name;
  final String? logoPath;
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? footerNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    this.id,
    required this.name,
    this.logoPath,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.footerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'company_id': id,
      'name': name,
      'logo_path': logoPath,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'footer_note': footerNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['company_id']?.toInt(),
      name: map['name'] ?? '',
      logoPath: map['logo_path'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      address: map['address'],
      footerNote: map['footer_note'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? logoPath,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? footerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      footerNote: footerNote ?? this.footerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

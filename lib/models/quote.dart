import 'package:flutter/material.dart';

class Quote {
  final int? id;
  final int companyId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? objectName;
  final String? address;
  final double? areaS;
  final double? perimeterP;
  final double? heightH;
  final String? ceilingSystem;
  final QuoteStatus status;
  final String? paymentTerms;
  final String? installationTerms;
  final String? notes;
  final String currencyCode;
  final double subtotalWork;
  final double subtotalEquipment;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Quote({
    this.id,
    required this.companyId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.objectName,
    this.address,
    this.areaS,
    this.perimeterP,
    this.heightH,
    this.ceilingSystem,
    this.status = QuoteStatus.draft,
    this.paymentTerms,
    this.installationTerms,
    this.notes,
    this.currencyCode = 'RUB',
    this.subtotalWork = 0.0,
    this.subtotalEquipment = 0.0,
    this.totalAmount = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'quote_id': id,
      'company_id': companyId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'object_name': objectName,
      'address': address,
      'area_s': areaS,
      'perimeter_p': perimeterP,
      'height_h': heightH,
      'ceiling_system': ceilingSystem,
      'status': status.name,
      'payment_terms': paymentTerms,
      'installation_terms': installationTerms,
      'notes': notes,
      'currency_code': currencyCode,
      'subtotal_work': subtotalWork,
      'subtotal_equipment': subtotalEquipment,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['quote_id']?.toInt(),
      companyId: map['company_id']?.toInt() ?? 1,
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'],
      customerEmail: map['customer_email'],
      objectName: map['object_name'],
      address: map['address'],
      areaS: map['area_s']?.toDouble(),
      perimeterP: map['perimeter_p']?.toDouble(),
      heightH: map['height_h']?.toDouble(),
      ceilingSystem: map['ceiling_system'],
      status: QuoteStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => QuoteStatus.draft,
      ),
      paymentTerms: map['payment_terms'],
      installationTerms: map['installation_terms'],
      notes: map['notes'],
      currencyCode: map['currency_code'] ?? 'RUB',
      subtotalWork: map['subtotal_work']?.toDouble() ?? 0.0,
      subtotalEquipment: map['subtotal_equipment']?.toDouble() ?? 0.0,
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  Quote copyWith({
    int? id,
    int? companyId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? objectName,
    String? address,
    double? areaS,
    double? perimeterP,
    double? heightH,
    String? ceilingSystem,
    QuoteStatus? status,
    String? paymentTerms,
    String? installationTerms,
    String? notes,
    String? currencyCode,
    double? subtotalWork,
    double? subtotalEquipment,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      objectName: objectName ?? this.objectName,
      address: address ?? this.address,
      areaS: areaS ?? this.areaS,
      perimeterP: perimeterP ?? this.perimeterP,
      heightH: heightH ?? this.heightH,
      ceilingSystem: ceilingSystem ?? this.ceilingSystem,
      status: status ?? this.status,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      installationTerms: installationTerms ?? this.installationTerms,
      notes: notes ?? this.notes,
      currencyCode: currencyCode ?? this.currencyCode,
      subtotalWork: subtotalWork ?? this.subtotalWork,
      subtotalEquipment: subtotalEquipment ?? this.subtotalEquipment,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

enum QuoteStatus {
  draft,
  sent,
  approved,
  completed,
  cancelled,
}

extension QuoteStatusExtension on QuoteStatus {
  String get displayName {
    switch (this) {
      case QuoteStatus.draft:
        return 'Черновик';
      case QuoteStatus.sent:
        return 'Отправлено';
      case QuoteStatus.approved:
        return 'Согласовано';
      case QuoteStatus.completed:
        return 'Выполнено';
      case QuoteStatus.cancelled:
        return 'Отменено';
    }
  }

  Color get color {
    switch (this) {
      case QuoteStatus.draft:
        return Colors.grey;
      case QuoteStatus.sent:
        return Colors.blue;
      case QuoteStatus.approved:
        return Colors.orange;
      case QuoteStatus.completed:
        return Colors.green;
      case QuoteStatus.cancelled:
        return Colors.red;
    }
  }
}

/// A row from `public.coupons` (publicly readable while valid).
class CouponModel {
  final String id;
  final String code;
  final String? salonId;
  final double discountPercent;
  final double? maxDiscount;
  final DateTime? validTo;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    this.salonId,
    required this.discountPercent,
    this.maxDiscount,
    this.validTo,
    this.isActive = true,
  });

  /// e.g. `50` -> "50% off", `12.5` -> "12.5% off".
  String get discountLabel {
    final value = discountPercent % 1 == 0
        ? discountPercent.toInt().toString()
        : discountPercent.toStringAsFixed(1);
    return '$value% off';
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      salonId: json['salon_id'] as String?,
      discountPercent: (json['discount_percent'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      validTo: json['valid_to'] != null
          ? DateTime.tryParse(json['valid_to'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

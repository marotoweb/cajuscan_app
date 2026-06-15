// lib/merchant_profile.dart
import 'dart:convert';

class MerchantProfile {
  String name;
  String category;
  String? subcategory;

  MerchantProfile({
    required this.name,
    required this.category,
    this.subcategory,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'category': category, 'subcategory': subcategory};
  }

  factory MerchantProfile.fromMap(Map<String, dynamic> map) {
    return MerchantProfile(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
    );
  }

  String toJson() => json.encode(toMap());
  factory MerchantProfile.fromJson(String source) =>
      MerchantProfile.fromMap(json.decode(source));
}

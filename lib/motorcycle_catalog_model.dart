// คุมหมวดหมู่อะไหล่ตามที่เคยออกแบบไว้
enum PartCategory {
  fluids,
  driveTrain,
  braking,
  suspension,
  electrical,
  body,
  labor,
  others,
}

class SparePartItem {
  final String name;
  final PartCategory category;
  final double estimatedPrice;

  SparePartItem({
    required this.name,
    required this.category,
    required this.estimatedPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'estimatedPrice': estimatedPrice,
    };
  }

  factory SparePartItem.fromMap(Map<String, dynamic> map) {
    return SparePartItem(
      name: map['name'] ?? '',
      category: PartCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PartCategory.others,
      ),
      estimatedPrice: (map['estimatedPrice'] as num).toDouble(),
    );
  }
}

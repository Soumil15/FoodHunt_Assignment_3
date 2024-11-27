class FoodItem {
  final int? id;  // The ID is nullable
  final String name;
  final double cost;

  // Constructor
  FoodItem({this.id, required this.name, required this.cost});

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,  // Add id here as nullable
      'name': name,
      'cost': cost,
    };
  }

  // Create from Map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],  // id will be nullable here
      name: map['name'],
      cost: map['cost'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoodItem && other.name == name && other.cost == cost;
  }

  @override
  int get hashCode => name.hashCode ^ cost.hashCode;
}

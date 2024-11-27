import 'dart:convert'; // Import for jsonEncode and jsonDecode

class OrderPlan {
  int? id;  // Make id nullable
  String date;
  double targetCost;
  List<String> foodItems;

  OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.foodItems,
  });

  // Convert the object to a map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'target_cost': targetCost,
      'food_items': jsonEncode(foodItems), // Convert list to JSON string
    };
  }

  // Create an OrderPlan object from a map
  factory OrderPlan.fromMap(Map<String, dynamic> map) {
    return OrderPlan(
      id: map['id'],
      date: map['date'],
      targetCost: (map['target_cost'] ?? 0.0) as double,  // Provide a default value
      foodItems: List<String>.from(jsonDecode(map['food_items'])), // Decode JSON string
    );
  }
}

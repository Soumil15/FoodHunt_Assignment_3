import 'package:flutter/material.dart';
import 'food_item.dart';
import 'OrderPlan.dart';
import 'database_helper.dart';
import 'query_order_plan_screen.dart'; // Screen for querying order plans

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeDatabase(); // Initialize the database with food items
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      home: FoodSelectionScreen(),
    );
  }
}

// Initialize database with 20 food items
Future<void> _initializeDatabase() async {
  final db = DatabaseHelper.instance;
  final existingFoods = await db.getAllFoods();

  if (existingFoods.isEmpty) {
    final List<FoodItem> initialFoods = List.generate(
      20,
          (index) => FoodItem(
        name: 'Food Item ${index + 1}',
        cost: (index + 1) * 2.0,
      ),
    );

    for (var food in initialFoods) {
      await db.insertFood(food.toMap());
    }
    print('20 food items added to the database.');
  }
}

class FoodSelectionScreen extends StatefulWidget {
  @override
  _FoodSelectionScreenState createState() => _FoodSelectionScreenState();
}

class _FoodSelectionScreenState extends State<FoodSelectionScreen> {
  double targetCost = 0.0;
  DateTime selectedDate = DateTime.now();
  Set<FoodItem> selectedFoods = {};
  double totalCost = 0.0;

  // Save order plan in the database
  void _saveOrderPlan() async {
    if (selectedFoods.isEmpty || targetCost == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one food item and set the target cost.')),
      );
      return;
    }

    final date = selectedDate.toIso8601String().split('T').first;

    // Check if total cost exceeds target cost
    totalCost = selectedFoods.fold(0.0, (sum, food) => sum + food.cost);
    if (totalCost > targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total cost exceeds target cost!')),
      );
      return;
    }

    OrderPlan orderPlan = OrderPlan(
      date: date,
      targetCost: targetCost,
      foodItems: selectedFoods.map((food) => food.name).toList(),
    );

    await DatabaseHelper.instance.insertOrderPlan(orderPlan.toMap());

    // Show a confirmation message after saving the order plan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order plan saved successfully!')),
    );

    // Optionally, clear selections after saving
    setState(() {
      selectedFoods.clear();
      targetCost = 0.0;
      totalCost = 0.0;
    });
  }


  // The _addFoodItem function can be called as a dialog in the same screen:
  void _addFoodItem() async {
    String name = '';
    double cost = 0.0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Food Item'),
          content: Column(
            children: [
              TextField(
                onChanged: (value) {
                  name = value;
                },
                decoration: InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  cost = double.tryParse(value) ?? 0.0;
                },
                decoration: InputDecoration(labelText: 'Cost'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (name.isNotEmpty && cost > 0) {
                  FoodItem newFoodItem = FoodItem(name: name, cost: cost);
                  await DatabaseHelper.instance.insertFood(newFoodItem.toMap());
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _updateFoodItem(FoodItem food) async {
    String updatedName = food.name;
    double updatedCost = food.cost;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Food Item'),
          content: Column(
            children: [
              TextField(
                controller: TextEditingController(text: food.name),
                onChanged: (value) {
                  updatedName = value;
                },
                decoration: InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                controller: TextEditingController(text: food.cost.toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  updatedCost = double.tryParse(value) ?? 0.0;
                },
                decoration: InputDecoration(labelText: 'Cost'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (updatedName.isNotEmpty && updatedCost > 0) {
                  // Ensure the id is passed in the map for update
                  Map<String, dynamic> updatedFoodMap = {
                    'id': food.id, // Pass the id from the current food item
                    'name': updatedName,
                    'cost': updatedCost,
                  };

                  await DatabaseHelper.instance.updateFood(updatedFoodMap); // Pass the map with 'id'
                  setState(() {}); // Refresh the screen after updating
                  Navigator.pop(context);
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a food item
  void _deleteFood(FoodItem food) async {
    if (food.id != null) { // Check if the ID is not null
      await DatabaseHelper.instance.deleteFood(food.id!); // Use '!' to cast to non-nullable
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Food item deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Food item ID is null')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Food Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addFoodItem, // Calls the add food item function
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QueryOrderPlanScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Target Cost: \$${targetCost.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                double? newTargetCost = await _showTargetCostDialog();
                if (newTargetCost != null) {
                  setState(() {
                    targetCost = newTargetCost;
                  });
                }
              },
            ),
          ),
          ListTile(
            title: Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
            trailing: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && picked != selectedDate) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
            ),
          ),
          // Display the total cost of selected items
          ListTile(
            title: Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
          ),
          Expanded(
            child: FutureBuilder(
              future: DatabaseHelper.instance.getAllFoods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final foods = snapshot.data as List<Map<String, dynamic>>;
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = FoodItem.fromMap(foods[index]);
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text('\$${food.cost.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _updateFoodItem(food), // Update button
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteFood(food), // Delete button
                          ),
                        ],
                      ),
                      leading: Checkbox(
                        value: selectedFoods.contains(food),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedFoods.add(food);
                            } else {
                              selectedFoods.remove(food);
                            }
                            totalCost = selectedFoods.fold(0.0, (sum, food) => sum + food.cost);
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveOrderPlan, // Call save order plan function
        child: Icon(Icons.save),
        tooltip: 'Save Order Plan',
      ),
    );
  }

  // Show a dialog to set target cost
  Future<double?> _showTargetCostDialog() async {
    double targetCostValue = targetCost;
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Target Cost'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              targetCostValue = double.tryParse(value) ?? 0.0;
            },
            decoration: InputDecoration(labelText: 'Target Cost'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, targetCostValue);
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }
}

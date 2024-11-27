import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class QueryOrderPlanScreen extends StatefulWidget {
  @override
  _QueryOrderPlanScreenState createState() => _QueryOrderPlanScreenState();
}

class _QueryOrderPlanScreenState extends State<QueryOrderPlanScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? orderPlan;

  void _queryOrderPlan() async {
    final date = selectedDate.toIso8601String().split('T').first;
    final result = await DatabaseHelper.instance.getOrderPlanByDate(date);

    setState(() {
      orderPlan = result?.toMap();  // Update the state with the result
    });

    if (result != null) {
      print('Order Plan Retrieved: $result');
      print('Food Items: ${result.foodItems}'); // Check parsed food items
    } else {
      print('No order plan found for the date: $date');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Query Order Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: TextEditingController(
                    text: "${selectedDate.toLocal()}".split(' ')[0],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _queryOrderPlan,
              child: Text('Query Order Plan'),
            ),
            SizedBox(height: 16),
            if (orderPlan != null) ...[
              Text(
                'Order Plan Details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Date: ${orderPlan!['date']}'),
              Text('Target Cost: \$${orderPlan!['target_cost']}'),

              // Decode and display food items
              Text('Food Items: ${jsonDecode(orderPlan!['food_items']).join(', ')}'),
            ] else ...[
              Text('No order plan found for the selected date.'),
            ],
          ],
        ),
      ),
    );
  }
}

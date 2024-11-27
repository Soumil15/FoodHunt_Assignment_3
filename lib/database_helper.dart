import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'OrderPlan.dart';
import 'food_item.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_items.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,  // Increment version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    // Create `food_items` table
    await db.execute('''
      CREATE TABLE food_items (
        id $idType,
        name $textType,
        cost $realType
      )
    ''');

    // Create `order_plan` table (add target_cost column)
    await db.execute('''
      CREATE TABLE order_plan (
        id $idType,
        date $textType,
        target_cost $realType,
        food_items $textType
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if the `target_cost` column exists in the `order_plan` table
      final result = await db.rawQuery('PRAGMA table_info(order_plan);');
      bool hasTargetCostColumn = result.any((column) => column['name'] == 'target_cost');

      // Add the `target_cost` column only if it doesn't already exist
      if (!hasTargetCostColumn) {
        await db.execute('''
          ALTER TABLE order_plan ADD COLUMN target_cost REAL NOT NULL DEFAULT 0;
        ''');
      }
    }
  }

  // *** Food Item Methods ***

  // Insert a food item into the database
  Future<int> insertFood(Map<String, dynamic> food) async {
    final db = await instance.database;
    return await db.insert('food_items', food);
  }

  // Retrieve all food items from the database
  Future<List<Map<String, dynamic>>> getAllFoods() async {
    final db = await instance.database;
    return await db.query('food_items');
  }

  // Retrieve a single food item by ID
  Future<Map<String, dynamic>?> getFoodById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Retrieve a single food item by name
  Future<Map<String, dynamic>?> getFoodByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'food_items',
      where: 'name = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update a food item
  Future<int> updateFood(Map<String, dynamic> updatedFood) async {
    final db = await instance.database;
    return await db.update(
      'food_items',
      updatedFood,
      where: 'id = ?',
      whereArgs: [updatedFood['id']],
    );
  }

  // Delete a food item
  Future<int> deleteFood(int id) async {
    final db = await instance.database;
    return await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }

  // Delete all food items
  Future<int> deleteAllFoods() async {
    final db = await instance.database;
    return await db.delete('food_items');
  }

  // Check if initial food items exist
  Future<bool> hasInitialFoods() async {
    final db = await instance.database;
    final result = await db.query('food_items');
    return result.isNotEmpty;
  }

  // *** Order Plan Methods ***

  // Insert a new order plan
  Future<int> insertOrderPlan(Map<String, dynamic> orderPlan) async {
    final db = await instance.database;
    return await db.insert('order_plan', orderPlan);
  }

  // Retrieve all order plans
  Future<List<Map<String, dynamic>>> getAllOrderPlans() async {
    final db = await instance.database;
    return await db.query('order_plan');
  }

  // Retrieve an order plan by date
  Future<OrderPlan?> getOrderPlanByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'order_plan',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (result.isNotEmpty) {
      return OrderPlan.fromMap(result.first);
    }
    return null;
  }

  // Delete all order plans
  Future<int> deleteAllOrderPlans() async {
    final db = await instance.database;
    return await db.delete('order_plan');
  }
}

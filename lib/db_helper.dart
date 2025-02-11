import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

static Future<Database> _initDB() async {
  final path = join(await getDatabasesPath(), 'ict4580.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          userID INTEGER PRIMARY KEY AUTOINCREMENT,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          userName TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE products (
          productID INTEGER PRIMARY KEY AUTOINCREMENT,
          productName TEXT NOT NULL,
          productDesc TEXT NOT NULL,
          productPrice REAL NOT NULL,
          category TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE orders (
          orderID INTEGER PRIMARY KEY AUTOINCREMENT,
          userID INTEGER NOT NULL,
          orderDate TEXT NOT NULL,
          orderTotal REAL NOT NULL,
          FOREIGN KEY(userID) REFERENCES users(userID)
        );
      ''');

      await db.execute('''
        CREATE TABLE orderedProducts (
          orderedID INTEGER PRIMARY KEY AUTOINCREMENT,
          userID INTEGER NOT NULL,
          productID INTEGER NOT NULL,
          FOREIGN KEY(userID) REFERENCES users(userID),
          FOREIGN KEY(productID) REFERENCES products(productID)
        );
      ''');

      // Insert sample data
      await _insertSampleData(db);
    },
  );
}

Future<int> insertUser(Map<String, dynamic> user) async {
  final db = await database;
  return await db.insert('users', user);
}

//Method to show users where the username and password match provided values
Future<Map<String, dynamic>?> getUserByCredentials(String userName, String password) async {
  final db = await DBHelper.database;
  final List<Map<String, dynamic>> results = await db.query(
    'users',
    where: 'userName = ? AND password = ?',
    whereArgs: [userName, password],
  );
  if (results.isNotEmpty) {
    return results.first;
  }
  return null;
}

// Fetch products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    final db = await database;
    return db.query('products', where: 'category = ?', whereArgs: [category]);
  }

//Insert sample data--can update as needed
static Future<void> _insertSampleData(Database db) async {
  await db.insert('users', {
    'firstName': 'John',
    'lastName': 'Doe',
    'userName': 'johndoe',
    'password': 'password123'
  });

  await db.insert('users', {
    'firstName': 'Jane',
    'lastName': 'Smith',
    'userName': 'janesmith',
    'password': 'password123'
  });

  List<Map<String, dynamic>> products = [
    {'productName': 'Colorful Tie Blouse', 'productDesc': 'White blouse with a cute colorful pattern and a black ribbon in the back for a bow.', 'productPrice': 20.00, 'category': 'Tops'},
    {'productName': 'Linen Pants', 'productDesc': 'Khaki-colored linen pants for a casual look.', 'productPrice': 20.00, 'category': 'Bottoms'},
    {'productName': 'Summer Dress', 'productDesc': 'Floral summer dress', 'productPrice': 35.00, 'category': 'Dresses'},
    {'productName': 'Winter Coat', 'productDesc': 'Warm winter coat', 'productPrice': 35.00, 'category': 'Outerwear'},
    {'productName': 'Asymmetrical Maroon Top', 'productDesc': 'A maroon top with an asymmetrical hemline.', 'productPrice': 20.00, 'category': 'Tops'},
    {'productName': 'Black Trouser Pants', 'productDesc': 'Comfortable black trouser pants for a professional look.', 'productPrice': 25.00, 'category': 'Bottoms'},
  ];

  for (var product in products) {
    await db.insert('products', product);
  }
}

}

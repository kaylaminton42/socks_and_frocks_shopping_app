import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database
  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'ict4580.db');
    return openDatabase(
      path,
      version: 1,  // If you already have a database created, you might need to bump the version and implement onUpgrade.
      onCreate: (db, version) async {
        // Create users table
        await db.execute('''
          CREATE TABLE users (
            userID INTEGER PRIMARY KEY AUTOINCREMENT,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            userName TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          );
        ''');

        // Create products table with an additional "image" column.
        await db.execute('''
          CREATE TABLE products (
            productID INTEGER PRIMARY KEY AUTOINCREMENT,
            productName TEXT NOT NULL,
            productDesc TEXT NOT NULL,
            productPrice REAL NOT NULL,
            category TEXT NOT NULL,
            image TEXT
          );
        ''');

        // Create orders table
        await db.execute('''
          CREATE TABLE orders (
            orderID INTEGER PRIMARY KEY AUTOINCREMENT,
            userID INTEGER NOT NULL,
            orderDate TEXT NOT NULL,
            orderTotal REAL NOT NULL,
            FOREIGN KEY(userID) REFERENCES users(userID)
          );
        ''');

        // Create orderedProducts table with orderID foreign key
        await db.execute('''
          CREATE TABLE orderedProducts (
            orderedID INTEGER PRIMARY KEY AUTOINCREMENT,
            orderID INTEGER NOT NULL,
            productID INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(orderID) REFERENCES orders(orderID),
            FOREIGN KEY(productID) REFERENCES products(productID)
          );
        ''');

        // Insert sample data (users, products, orders, and orderedProducts)
        await _insertSampleData(db);
      },
    );
  }

  // Insert a new user into the database
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Get user by credentials (for login)
  Future<Map<String, dynamic>?> getUserByCredentials(String userName, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'userName = ? AND password = ?',
      whereArgs: [userName, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Get user by ID (for Profile Page)
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'userID = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update user info (username & password)
  Future<int> updateUser(int userId, String newUsername, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'userName': newUsername,
        'password': newPassword,
      },
      where: 'userID = ?',
      whereArgs: [userId],
    );
  }

  // Fetch orders for a given user
  Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    final db = await database;
    return db.query(
      'orders',
      where: 'userID = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );
  }

  // Delete user (optional: for account deletion)
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'userID = ?',
      whereArgs: [userId],
    );
  }

  // Fetch products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    final db = await database;
    return db.query('products', where: 'category = ?', whereArgs: [category]);
  }

  Future<List<Map<String, dynamic>>> getOrderedProductsByOrderId(int orderId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, op.quantity
      FROM products p
      JOIN orderedProducts op ON p.productID = op.productID
      WHERE op.orderID = ?
    ''', [orderId]);
  }

  // Insert sample data (users, products, orders, and corresponding orderedProducts)
  static Future<void> _insertSampleData(Database db) async {
    // Insert sample users
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

    // Insert sample products with the new image field.
    List<Map<String, dynamic>> products = [
      {
        'productName': 'Colorful Tie Blouse',
        'productDesc': 'White blouse with a cute colorful pattern and a black ribbon in the back for a bow.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/colorful_top.png', // provide asset path
      },
      {
        'productName': 'Linen Pants',
        'productDesc': 'Khaki-colored linen pants for a casual look.',
        'productPrice': 20.00,
        'category': 'Bottoms',
        'image': 'assets/products/linen_pants.JPEG',
      },
      {
        'productName': 'Summer Dress',
        'productDesc': 'Floral summer dress',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/summer_dress.jpg',
      },
      {
        'productName': 'Winter Coat',
        'productDesc': 'Warm winter coat',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/winter_coat.jpg',
      },
      {
        'productName': 'Asymmetrical Maroon Top',
        'productDesc': 'A maroon top with an asymmetrical hemline.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/maroon_top.JPEG',
      },
      {
        'productName': 'Black Trouser Pants',
        'productDesc': 'Comfortable black trouser pants for a professional look.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/black_trousers.JPEG',
      },
      {
        'productName': 'Teal Blouse',
        'productDesc': 'Comfy, casual teal blouse.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/teal_blouse.JPEG',
      },
      {
        'productName': 'Linen Pants',
        'productDesc': 'Green-colored linen pants for a casual look.',
        'productPrice': 20.00,
        'category': 'Bottoms',
        'image': 'assets/products/green_linen_pants.jpg',
      },
      {
        'productName': 'Maxi Dress',
        'productDesc': 'Long, knit dress',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/maxi_dress.jpg',
      },
      {
        'productName': 'Rain Coat',
        'productDesc': 'Cute rain coat to keep you dry and chic during a rainstorm.',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/rain_coat.jpg',
      },
      {
        'productName': 'Striped Top',
        'productDesc': 'A striped, knit top.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/striped_top.JPEG',
      },
      {
        'productName': 'Skinny Jeans',
        'productDesc': 'Soft, stretchy skinny jeans in a dark rinse.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/skinny_jeans.JPEG',
      },
    ];

    for (var product in products) {
      await db.insert('products', product);
    }

    // Insert sample orders and corresponding orderedProducts entries.
    List<Map<String, dynamic>> sampleOrders = [
      // Orders for johndoe (userID = 1)
      {
        'userID': 1,
        'orderDate': '2024-12-01',
        'orderTotal': 40.00,
        'productID': 1,
        'quantity': 2,
      },
      {
        'userID': 1,
        'orderDate': '2024-12-15',
        'orderTotal': 60.00,
        'productID': 2,
        'quantity': 3,
      },
      {
        'userID': 1,
        'orderDate': '2024-12-20',
        'orderTotal': 35.00,
        'productID': 3,
        'quantity': 1,
      },
      // Orders for janesmith (userID = 2)
      {
        'userID': 2,
        'orderDate': '2024-12-05',
        'orderTotal': 35.00,
        'productID': 4,
        'quantity': 1,
      },
      {
        'userID': 2,
        'orderDate': '2024-12-10',
        'orderTotal': 40.00,
        'productID': 5,
        'quantity': 2,
      },
      {
        'userID': 2,
        'orderDate': '2024-12-25',
        'orderTotal': 75.00,
        'productID': 6,
        'quantity': 3,
      },
    ];

    for (var order in sampleOrders) {
      int productID = order.remove('productID');
      int quantity = order.remove('quantity') ?? 1;
      // Insert the order and capture the auto-generated orderID.
      int orderID = await db.insert('orders', order);
      // Insert the corresponding orderedProducts entry linking the order to the product.
      await db.insert('orderedProducts', {
        'orderID': orderID,
        'productID': productID,
        'quantity': quantity,
      });
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // Get the database instance.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize the database.
  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'ict4580.db');
    // Bump the version to force onUpgrade if needed.
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertSampleData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // For simplicity, drop existing tables and recreate them.
        await db.execute('DROP TABLE IF EXISTS orderedProducts');
        await db.execute('DROP TABLE IF EXISTS orders');
        await db.execute('DROP TABLE IF EXISTS product_styles');
        await db.execute('DROP TABLE IF EXISTS product_colors');
        await db.execute('DROP TABLE IF EXISTS products');
        await db.execute('DROP TABLE IF EXISTS users');
        await _createTables(db);
        await _insertSampleData(db);
      },
    );
  }

  // Create all tables.
  static Future<void> _createTables(Database db) async {
    // Users table.
    await db.execute('''
      CREATE TABLE users (
        userID INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        userName TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      );
    ''');

    // Products table.
    // Note: We remove AUTOINCREMENT so that productID is manually input.
    await db.execute('''
      CREATE TABLE products (
        productID INTEGER PRIMARY KEY,
        productName TEXT NOT NULL,
        productDesc TEXT NOT NULL,
        productPrice REAL NOT NULL,
        category TEXT NOT NULL,
        image TEXT,
        altText TEXT,
        onSale INTEGER NOT NULL DEFAULT 0,
        salePrice REAL NOT NULL
      );
    ''');

    // Join table for product colors.
    await db.execute('''
      CREATE TABLE product_colors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productID INTEGER NOT NULL,
        color TEXT NOT NULL,
        FOREIGN KEY(productID) REFERENCES products(productID)
      );
    ''');

    // Join table for product styles.
    await db.execute('''
      CREATE TABLE product_styles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productID INTEGER NOT NULL,
        style TEXT NOT NULL,
        FOREIGN KEY(productID) REFERENCES products(productID)
      );
    ''');

    // Orders table.
    await db.execute('''
      CREATE TABLE orders (
        orderID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        orderDate TEXT NOT NULL,
        orderTotal REAL NOT NULL,
        FOREIGN KEY(userID) REFERENCES users(userID)
      );
    ''');

    // OrderedProducts table.
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
  }

  // Insert a new user.
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  // Get user by credentials (for login).
  Future<Map<String, dynamic>?> getUserByCredentials(String userName, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'userName = ? AND password = ?',
      whereArgs: [userName, password],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Get user by ID.
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'userID = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update user info.
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

  // Fetch orders for a given user.
  Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'userID = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );
  }

  // Delete a user.
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'userID = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
  final db = await database;
  // Query all products.
  List<Map<String, dynamic>> products = await db.query('products');
  List<Map<String, dynamic>> mutableProducts = [];

  // For each product, also fetch associated colors and styles.
  for (var product in products) {
    var mutableProduct = Map<String, dynamic>.from(product);
    int productID = mutableProduct['productID'] as int;

    List<Map<String, dynamic>> colorResults = await db.query(
      'product_colors',
      columns: ['color'],
      where: 'productID = ?',
      whereArgs: [productID],
    );
    mutableProduct['colors'] =
        colorResults.map((e) => e['color']?.toString() ?? '').toList();

    List<Map<String, dynamic>> styleResults = await db.query(
      'product_styles',
      columns: ['style'],
      where: 'productID = ?',
      whereArgs: [productID],
    );
    mutableProduct['styles'] =
        styleResults.map((e) => e['style']?.toString() ?? '').toList();

    mutableProducts.add(mutableProduct);
  }
  return mutableProducts;
}


 Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
  final db = await database;
  // Query the products table.
  List<Map<String, dynamic>> products = await db.query(
    'products',
    where: 'category = ?',
    whereArgs: [category],
  );
  
  // Create a new list to store mutable product maps.
  List<Map<String, dynamic>> mutableProducts = [];
  
  // For each product, retrieve its colors and styles.
  for (var product in products) {
    // Create a mutable copy of the product map.
    var mutableProduct = Map<String, dynamic>.from(product);
    int productID = mutableProduct['productID'] as int;
    
    try {
      List<Map<String, dynamic>> colorResults = await db.query(
        'product_colors',
        columns: ['color'],
        where: 'productID = ?',
        whereArgs: [productID],
      );
      print("Product $productID colors: $colorResults");
      mutableProduct['colors'] = colorResults
          .map((e) => e['color']?.toString() ?? '')
          .toList();
    } catch (e) {
      print("Error fetching colors for product $productID: $e");
      mutableProduct['colors'] = [];
    }
    
    try {
      List<Map<String, dynamic>> styleResults = await db.query(
        'product_styles',
        columns: ['style'],
        where: 'productID = ?',
        whereArgs: [productID],
      );
      print("Product $productID styles: $styleResults");
      mutableProduct['styles'] = styleResults
          .map((e) => e['style']?.toString() ?? '')
          .toList();
    } catch (e) {
      print("Error fetching styles for product $productID: $e");
      mutableProduct['styles'] = [];
    }
    
    mutableProducts.add(mutableProduct);
  }
  
  return mutableProducts;
}


  // Search products by name.
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'productName LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Get ordered products for an order.
  Future<List<Map<String, dynamic>>> getOrderedProductsByOrderId(int orderId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, op.quantity
      FROM products p
      JOIN orderedProducts op ON p.productID = op.productID
      WHERE op.orderID = ?
    ''', [orderId]);
  }

  // Insert sample data.
  static Future<void> _insertSampleData(Database db) async {
    // Insert sample users.
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

    // Sample products with additional keys for colors and styles.
    // Note: We're manually assigning productIDs starting at 101.
    List<Map<String, dynamic>> products = [
      {
        'productID': 101,
        'productName': 'Colorful Tie Blouse',
        'productDesc': 'White blouse with a cute colorful pattern and a black ribbon in the back for a bow.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/colorful_top.png',
        'colors': ['White', 'Multicolor'],
        'styles': ['Casual'],
        'altText': 'Colorful Tie Blouse',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 102,
        'productName': 'Linen Pants',
        'productDesc': 'Khaki-colored linen pants for a casual look.',
        'productPrice': 20.00,
        'category': 'Bottoms',
        'image': 'assets/products/linen_pants.JPEG',
        'colors': ['Khaki', 'Beige'],
        'styles': ['Casual'],
        'altText': 'Linen Pants in a khaki color',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 103,
        'productName': 'Summer Dress',
        'productDesc': 'Floral summer dress',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/summer_dress.jpg',
        'colors': ['Pink', 'White'],
        'styles': ['Casual'],
        'altText': 'Floral Summer Dress',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 104,
        'productName': 'Winter Coat',
        'productDesc': 'Warm winter coat',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/winter_coat.jpg',
        'colors': ['Cream', 'White'],
        'styles': ['Casual'],
        'altText': 'Winter Coat',
        'onSale': 1,
        'salePrice': 20.00
      },
      {
        'productID': 105,
        'productName': 'Asymmetrical Maroon Top',
        'productDesc': 'A maroon top with an asymmetrical hemline.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/maroon_top.JPEG',
        'colors': ['Red'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Asymmetrical Maroon Top',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 106,
        'productName': 'Black Trouser Pants',
        'productDesc': 'Comfortable black trouser pants for a professional look.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/black_trousers.JPEG',
        'colors': ['Black'],
        'styles': ['Formal', 'Business Casual', 'Business Professional'],
        'altText': 'Black Trouser Pants',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 107,
        'productName': 'Teal Blouse',
        'productDesc': 'Comfy, casual teal blouse.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/teal_blouse.JPEG',
        'colors': ['Teal'],
        'styles': ['Casual'],
        'altText': 'Teal Blouse',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 108,
        'productName': 'Linen Pants',
        'productDesc': 'Green-colored linen pants for a casual look.',
        'productPrice': 20.00,
        'category': 'Bottoms',
        'image': 'assets/products/green_linen_pants.jpg',
        'colors': ['Green'],
        'styles': ['Casual'],
        'altText': 'Green Linen Pants',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 109,
        'productName': 'Maxi Dress',
        'productDesc': 'Long, knit dress',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/maxi_dress.jpg',
        'colors': ['Gray'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Maxi Dress',
        'onSale': 1,
        'salePrice': 20.00
      },
      {
        'productID': 110,
        'productName': 'Rain Coat',
        'productDesc': 'Cute rain coat to keep you dry and chic during a rainstorm.',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/rain_coat.jpg',
        'colors': ['Blue'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Rain Coat',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 111,
        'productName': 'Striped Top',
        'productDesc': 'A striped, knit top.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/striped_top.JPEG',
        'colors': ['Red', 'Orange', 'Yellow'],
        'styles': ['Casual'],
        'altText': 'Striped Top',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 112,
        'productName': 'Skinny Jeans',
        'productDesc': 'Soft, stretchy skinny jeans in a dark rinse.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/skinny_jeans.JPEG',
        'colors': ['Blue'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Skinny Jeans',
        'onSale': 1,
        'salePrice': 10.00
      },
    ];

    // Insert products and associated join table entries.
    for (var product in products) {
      // Extract colors and styles.
      List<String> colors = product.containsKey('colors')
          ? List<String>.from(product['colors'])
          : [];
      List<String> styles = product.containsKey('styles')
          ? List<String>.from(product['styles'])
          : [];
      // Remove extra keys before inserting into the products table.
      product.remove('colors');
      product.remove('styles');

      // Insert product with manually provided productID.
      int productID = await db.insert('products', product);

      // Insert colors.
      for (String color in colors) {
        await db.insert('product_colors', {
          'productID': productID,
          'color': color,
        });
      }

      // Insert styles.
      for (String style in styles) {
        await db.insert('product_styles', {
          'productID': productID,
          'style': style,
        });
      }
    }

    // Insert sample orders and corresponding orderedProducts entries.
    List<Map<String, dynamic>> sampleOrders = [
      {
        'userID': 1,
        'orderDate': '2024-12-01',
        'orderTotal': 40.00,
        'productID': 101,
        'quantity': 2,
      },
      {
        'userID': 1,
        'orderDate': '2024-12-15',
        'orderTotal': 60.00,
        'productID': 102,
        'quantity': 3,
      },
      {
        'userID': 1,
        'orderDate': '2024-12-20',
        'orderTotal': 35.00,
        'productID': 103,
        'quantity': 1,
      },
      {
        'userID': 2,
        'orderDate': '2024-12-05',
        'orderTotal': 35.00,
        'productID': 104,
        'quantity': 1,
      },
      {
        'userID': 2,
        'orderDate': '2024-12-10',
        'orderTotal': 40.00,
        'productID': 105,
        'quantity': 2,
      },
      {
        'userID': 2,
        'orderDate': '2024-12-25',
        'orderTotal': 75.00,
        'productID': 106,
        'quantity': 3,
      },
    ];

    for (var order in sampleOrders) {
      int productID = order.remove('productID');
      int quantity = order.remove('quantity') ?? 1;
      int orderID = await db.insert('orders', order);
      await db.insert('orderedProducts', {
        'orderID': orderID,
        'productID': productID,
        'quantity': quantity,
      });
    }
  }
}

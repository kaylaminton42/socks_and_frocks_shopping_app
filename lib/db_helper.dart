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
      var mutableProduct = Map<String, dynamic>.from(product);
      int productID = mutableProduct['productID'] as int;

      try {
        List<Map<String, dynamic>> colorResults = await db.query(
          'product_colors',
          columns: ['color'],
          where: 'productID = ?',
          whereArgs: [productID],
        );
        mutableProduct['colors'] =
            colorResults.map((e) => e['color']?.toString() ?? '').toList();
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
        mutableProduct['styles'] =
            styleResults.map((e) => e['style']?.toString() ?? '').toList();
      } catch (e) {
        print("Error fetching styles for product $productID: $e");
        mutableProduct['styles'] = [];
      }

      mutableProducts.add(mutableProduct);
    }

    return mutableProducts;
  }

  // New function to get sale products.
  Future<List<Map<String, dynamic>>> getSaleProducts() async {
    final db = await database;
    // Query products where onSale equals 1.
    List<Map<String, dynamic>> saleProducts = await db.query(
      'products',
      where: 'onSale = ?',
      whereArgs: [1],
    );
    List<Map<String, dynamic>> mutableProducts = [];

    // For each product, also fetch associated colors and styles.
    for (var product in saleProducts) {
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
      {
        'productID': 113,
        'productName': 'Sleeveless Knit Top',
        'productDesc': 'Gray sleeveless top in a comfy knit fabric.',
        'productPrice': 25.00,
        'category': 'Tops',
        'image': 'assets/products/gray_knit_top.png',
        'colors': ['Gray'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Gray Sleeveless Top',
        'onSale': 1,
        'salePrice': 20.00
      },
      {
        'productID': 114,
        'productName': 'Red Top',
        'productDesc': 'Deep red boatneck top with short sleeves.',
        'productPrice': 25.00,
        'category': 'Tops',
        'image': 'assets/products/red_top.png',
        'colors': ['Red'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Red Short Sleeve Top',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 115,
        'productName': 'Black & White Striped Button-Down',
        'productDesc': 'Classic black and white striped button-down shirt.',
        'productPrice': 25.00,
        'category': 'Tops',
        'image': 'assets/products/bw_buttondown.png',
        'colors': ['Black', 'White'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Black and White Striped Button-Down',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 116,
        'productName': 'Plain White Tee',
        'productDesc': 'Classic white t-shirt.',
        'productPrice': 20.00,
        'category': 'Tops',
        'image': 'assets/products/plain_white_tee.png',
        'colors': ['White'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Plain White T-shirt',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 117,
        'productName': 'Boatneck Long Sleeve Top',
        'productDesc': 'Dark gray boatneck top with long sleeves.',
        'productPrice': 25.00,
        'category': 'Tops',
        'image': 'assets/products/longsleeve_boatneck_shirt.png',
        'colors': ['Gray'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Dark Gray Long Sleeve Top',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 118,
        'productName': 'Longsleeve Polo Shirt',
        'productDesc': 'Maroon and blue striped longsleeve polo shirt.',
        'productPrice': 25.00,
        'category': 'Tops',
        'image': 'assets/products/longsleeve_polo.png',
        'colors': ['Red', 'Blue'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Maroon and Blue Striped Polo Shirt',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 119,
        'productName': 'Pink Tweed Miniskirt',
        'productDesc': 'Pink tweed miniskirt with a zipper in the back.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/tweed_mini.png',
        'colors': ['Pink'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Tweed mini skirt in a light pink color',
        'onSale': 1,
        'salePrice': 20.00
      },
      {
        'productID': 120,
        'productName': 'Knit Midi Skirt',
        'productDesc': 'Warm knit midi skirt in a dark brown color',
        'productPrice': 30.00,
        'category': 'Bottoms',
        'image': 'assets/products/knit_midi.png',
        'colors': ['Brown'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Knit midi skirt in a dark brown color',
        'onSale': 1,
        'salePrice': 25.00
      },
      {
        'productID': 121,
        'productName': 'Red Aline Skirt',
        'productDesc': 'Red mid-length skirt with an A-line silhouette',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/red_aline.png',
        'colors': ['Red'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Red A-line skirt',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 122,
        'productName': 'Classic Black Pencil Skirt',
        'productDesc': 'Classic black pencil skirt',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/black_pencil_skirt.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Business Casual'],
        'altText': 'Black mid-length pencil skirt',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 123,
        'productName': 'Leather Mini Skirt',
        'productDesc': 'Black leather mini skirt with a zipper in the back.',
        'productPrice': 25.00,
        'category': 'Bottoms',
        'image': 'assets/products/leather_mini.png',
        'colors': ['Black'],
        'styles': ['Casual','Going Out'],
        'altText': 'Black leather mini skirt',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 124,
        'productName': 'Brown Suede Skirt',
        'productDesc': 'Long brown a-line skirt in a suede material.',
        'productPrice': 30.00,
        'category': 'Bottoms',
        'image': 'assets/products/suede_skirt.png',
        'colors': ['Brown'],
        'styles': ['Casual','Going Out'],
        'altText': 'Long brown skirt',
        'onSale': 1,
        'salePrice': 20.00
      },
       {
        'productID': 125,
        'productName': 'Sundress',
        'productDesc': 'Short sundress in a pink floral pattern.',
        'productPrice': 30.00,
        'category': 'Dresses',
        'image': 'assets/products/pink_floral_dress.png',
        'colors': ['Pink'],
        'styles': ['Casual','Going Out'],
        'altText': 'Short sundress in a pink floral pattern',
        'onSale': 0,
        'salePrice': 0.00
      },
       {
        'productID': 126,
        'productName': 'Sleveeless Rib Knit Dress',
        'productDesc': 'Ankle-length black and white striped dress. This dress is sleeveless with a crew neckline and includes a coordinating tie belt.',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/sleeveless_rib_knit_dress.png',
        'colors': ['Black', 'White'],
        'styles': ['Casual', 'Business Casual','Going Out'],
        'altText': 'Ankle-length black and white striped sleeveless dress',
        'onSale': 1,
        'salePrice': 25.00
      },
       {
        'productID': 127,
        'productName': 'Mock Neck Midi Dress',
        'productDesc': 'White mock neck midi dress in a ponte knit fabric.',
        'productPrice': 30.00,
        'category': 'Dresses',
        'image': 'assets/products/ponte_midi.png',
        'colors': ['White'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'White mock neck midi dress in a ponte knit fabric',
        'onSale': 1,
        'salePrice': 20.00
      },
       {
        'productID': 128,
        'productName': 'Sleeveless Midi Dress',
        'productDesc': 'Black midi dress with a mock neck and sleeveless design.',
        'productPrice': 30.00,
        'category': 'Dresses',
        'image': 'assets/products/sleeveless_midi.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Black sleeveless midi dress',
        'onSale': 1,
        'salePrice': 20.00
      },
       {
        'productID': 129,
        'productName': 'Black Mini Dress',
        'productDesc': 'Black mini dress with long sheer sleeves and a high neckline.',
        'productPrice': 45.00,
        'category': 'Dresses',
        'image': 'assets/products/black_minidress.png',
        'colors': ['Black'],
        'styles': ['Going Out'],
        'altText': 'Black mini dress with long sleeves',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 130,
        'productName': 'Red Mini Dress',
        'productDesc': 'Red sleeveless mini dress with an adjustable tie back.',
        'productPrice': 35.00,
        'category': 'Dresses',
        'image': 'assets/products/red_minidress.png',
        'colors': ['Red'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Red sleeveless mini dress',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 131,
        'productName': 'Sweater Dress',
        'productDesc': 'Gray sweater mini dress with a turtle neck and long sleeves.',
        'productPrice': 45.00,
        'category': 'Dresses',
        'image': 'assets/products/sweater_minidress.png',
        'colors': ['Gray'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Gray sweater mini dress',
        'onSale': 1,
        'salePrice': 30.00
      },
      {
        'productID': 132,
        'productName': 'Leather Mini Dress',
        'productDesc': 'Black leather mini shirt dress with long sleeves.',
        'productPrice': 45.00,
        'category': 'Dresses',
        'image': 'assets/products/black_leather_dress.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Black leather mini dress with long sleeves',
        'onSale': 1,
        'salePrice': 30.00
      },
      {
        'productID': 133,
        'productName': 'Tweed Jacket',
        'productDesc': 'Cute pink tweed jacket.',
        'productPrice': 45.00,
        'category': 'Outerwear',
        'image': 'assets/products/tweed_jacket.png',
        'colors': ['Pink'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Pink tweed jacket.',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 134,
        'productName': 'Black Leather Jacket',
        'productDesc': 'Classic moto-style black leather jacket.',
        'productPrice': 60.00,
        'category': 'Outerwear',
        'image': 'assets/products/leather_moto.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Black leather jacket',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 135,
        'productName': 'Classic Blazer',
        'productDesc': 'Classic black blazer in a crepe fabric.',
        'productPrice': 40.00,
        'category': 'Outerwear',
        'image': 'assets/products/black_blazer.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Black blazer',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 136,
        'productName': 'faux Fur Vest',
        'productDesc': 'Cozy and chic faux fur vest in a light brown color.',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/faux_fur_vest.png',
        'colors': ['Brown'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Brown faux fur vest',
        'onSale': 1,
        'salePrice': 30.00
      },
      {
        'productID': 137,
        'productName': 'Trench Coat',
        'productDesc': 'Beige trench coat with a hood and belt.',
        'productPrice': 45.00,
        'category': 'Outerwear',
        'image': 'assets/products/trench_coat.png',
        'colors': ['Brown', 'Beige'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Beige trench coat with hood',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 138,
        'productName': 'Wool Coat',
        'productDesc': 'Long grey wool coat with pockets and a hood.',
        'productPrice': 60.00,
        'category': 'Outerwear',
        'image': 'assets/products/wool_coat.png',
        'colors': ['Gray'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Gray wool coat',
        'onSale': 1,
        'salePrice': 45.00
      },
      {
        'productID': 139,
        'productName': 'Printed Denim Duster',
        'productDesc': 'A denim duster jacket with a cheetah print.',
        'productPrice': 50.00,
        'category': 'Outerwear',
        'image': 'assets/products/duster_coat.png',
        'colors': ['Black', 'Brown', 'Beige'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Cheetah print duster in a denim fabric.',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 140,
        'productName': 'Suit Vest',
        'productDesc': 'White suit vest with a button front and high neck.',
        'productPrice': 35.00,
        'category': 'Outerwear',
        'image': 'assets/products/white_suit_vest.png',
        'colors': ['White'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'White fitted suit vest with button front and high neckline',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 141,
        'productName': 'Pink Crossbody',
        'productDesc': 'Pink vegan leather crossbody bag.',
        'productPrice': 50.00,
        'category': 'Accessories',
        'image': 'assets/products/pink_crossbody.png',
        'colors': ['Pink'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Pink vegan leather crossbody bag',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 142,
        'productName': 'Black Tote',
        'productDesc': 'Oversized black tote bag in a vegan leather material',
        'productPrice': 50.00,
        'category': 'Accessories',
        'image': 'assets/products/black_tote.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Black oversized tote bag',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 143,
        'productName': 'Oval Sunglasses',
        'productDesc': 'Black oval sunglasses with a polycarbonate frame.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/oval_sunglasses.png',
        'colors': ['Black'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Black oval sunglasses',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 144,
        'productName': 'Cateye Sunglasses',
        'productDesc': 'Pink and brown cateye sunglasses with a polycarbonate frame.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/cateye_sunglasses.png',
        'colors': ['Pink', 'Brown'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Pink and brown cateye sunglasses',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 145,
        'productName': 'Wool Beanie',
        'productDesc': 'Brown wool beanie hat with a ribbed knit design.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/wool_beanie.png',
        'colors': ['Brown', 'Beige'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Rib knit beanine in a beige color',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 146,
        'productName': 'Printed Bucket Hat',
        'productDesc': 'Bucket hat with a leopard print design.',
        'productPrice': 25.00,
        'category': 'Accessories',
        'image': 'assets/products/bucket_hat.png',
        'colors': ['Black', 'Brown'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Fuzzy bucket hat in a leopard print',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 147,
        'productName': 'Gray Beret',
        'productDesc': 'Wool blend beret in a gray color.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/gray_beret.png',
        'colors': ['Gray'],
        'styles': ['Casual', 'Going Out'],
        'altText': 'Wool beret in a gray color',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 148,
        'productName': 'Green Fringed Scarf',
        'productDesc': 'Long green scarf with fringed ends.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/green_scarf.png',
        'colors': ['Green'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Green fringed scarf',
        'onSale': 1,
        'salePrice': 15.00
      },
      {
        'productID': 149,
        'productName': 'Polka Dot Scarf',
        'productDesc': 'Long polka dot scarf in black and white.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/polka_dot_scarf.png',
        'colors': ['Black', 'White'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Black and white polka dot scarf',
        'onSale': 0,
        'salePrice': 0.00
      },
      {
        'productID': 150,
        'productName': 'Square Scarf',
        'productDesc': 'Square scarf featuring poppies in a red and pink color.',
        'productPrice': 20.00,
        'category': 'Accessories',
        'image': 'assets/products/floral_square_scarf.png',
        'colors': ['Red', 'Pink'],
        'styles': ['Casual', 'Business Casual', 'Going Out'],
        'altText': 'Pink and red poppy printed square scarf',
        'onSale': 0,
        'salePrice': 0.00
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

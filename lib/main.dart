// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:social_signin_buttons_plugin/social_signin_buttons_plugin.dart';
import 'db_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('userId');

  runApp(MainApp(initialRoute: userId != null ? '/profile' : '/login', userId: userId));
}

class MainApp extends StatelessWidget {
  final String initialRoute;
  final int? userId;
  
  const MainApp({super.key, required this.initialRoute, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Socks & Frocks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF795CAF),
          primary: const Color(0xFF795CAF),
          secondary: const Color(0xFF0FE3D5),
          tertiary: const Color(0xFFF87E07),
          brightness: Brightness.light,
        ),

        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tops': (context) => const ProductsPage(title: 'Tops'),
        '/bottoms': (context) => const ProductsPage(title: 'Bottoms'),
        '/outerwear': (context) => const ProductsPage(title: 'Outerwear'),
        '/accessories': (context) => const ProductsPage(title: 'Accessories'),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/item': (context) => ItemListingPage(product: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>),
        '/profile': (context) => userId != null ? ProfileScreen(userId: userId!) : const LoginPage(),
        '/pastorders': (context) => PastOrdersScreen(userId: ModalRoute.of(context)!.settings.arguments as int),

      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  Widget buildLeftDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary, // Optional background color
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Adding logo from assets
              Image.asset(
                'assets/logo.PNG',  // Replace with your image path
                height: 80,         // Adjust as needed
              ),
              const SizedBox(height: 10),  // Adds spacing below the logo
              const Text(
                'Menu',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ],
          ),
        ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/');
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.category),
            title: const Text('Collections'),
            children: [
              ListTile(
                title: const Text('Tops'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/tops');
                },
              ),
              ListTile(
                title: const Text('Bottoms'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/bottoms');
                },
              ),
              ListTile(
                title: const Text('Outerwear'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/outerwear');
                },
              ),
              ListTile(
                title: const Text('Accessories'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/accessories');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _HomePageState extends State<HomePage> {
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// Featured collections data
final List<Map<String, String>> featuredCollections = [
  {'title': 'Tops', 'route': '/tops'},
  {'title': 'Bottoms', 'route': '/bottoms'},
  {'title': 'Outerwear', 'route': '/outerwear'},
  {'title': 'Accessories', 'route': '/accessories'},
  {'title': 'Sale', 'route': '/'},  // Example, update as needed
];

@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Scaffold(
    key: _scaffoldKey,
    appBar: AppBar(
      backgroundColor: colorScheme.primary,
      title: const Text('Socks & Frocks', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final int? userId = prefs.getInt('userId');
            if (userId != null) {
              // User is logged in, go to the profile page
              Navigator.pushNamed(context, '/profile', arguments: userId);
            } else {
              // No user is logged in, go to the login page
              Navigator.pushNamed(context, '/login');
            }
          },
        )
      ],
    ),
    
    drawer: widget.buildLeftDrawer(context),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),


          //Creates the featured collections carousel
          SizedBox(
height: 180,
child: ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: featuredCollections.length,
  itemBuilder: (context, index) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, featuredCollections[index]['route']!);
      },
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8.0),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 50, color: Colors.white),
            ),
          ),
          Text(
            featuredCollections[index]['title']!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  },
),
),




          //creates the featured items carousel
          const SizedBox(height: 20),
          const Text('Featured Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.all(8.0),
                width: 120,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
//Products page here

class ProductsPage extends StatefulWidget {
  final String title;

  const ProductsPage({super.key, required this.title});

  @override
  ProductsPageState createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  Future<void> _fetchProducts() async {
    _products = await DBHelper().getProductsByCategory(widget.title);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Add filter functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart page
            },
          ),
        ],
      ),
      drawer: const HomePage().buildLeftDrawer(context),
      body: Column(
        children: [
          // You can add a filter or search bar here if needed
          Padding(
            padding: const EdgeInsets.all(16.0),
            
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("No products available"))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(context, _products[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemListingPage(product: product),
          ),
        );
      },
      style: TextButton.styleFrom(padding: EdgeInsets.zero), // Removes extra padding
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Icon(Icons.image, size: 50, color: Theme.of(context).colorScheme.secondary), // Placeholder for image
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    product['productName'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                    style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

class ItemListingPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ItemListingPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['productName'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for product image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.image, size: 80, color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              product['productName'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Product Price
            Text(
              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.tertiary),
            ),

            const SizedBox(height: 16),

            // Product Description
            Text(
              product['productDesc'],
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // Add to Cart Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle add to cart logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${product['productName']} added to cart")),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Add to Cart"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The login page where the user enters their credentials.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for username and password text fields.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Clean up the controllers when the widget is disposed.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to perform login.
  void _login() async {
  final String userName = _usernameController.text.trim();
  final String password = _passwordController.text;

  final dbHelper = DBHelper();
  final matchingUser = await dbHelper.getUserByCredentials(userName, password);

  if (matchingUser != null) {
    int userId = matchingUser['userID']; //  Extract user ID from database

    // Save the userId to shared_preferences so that we know the user is logged in
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);

    //  Navigate to ProfileScreen and pass userId
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  } else {
    //  Show an error message if login fails
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid username or password.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'janesmith1',
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.primary, // Background color
                foregroundColor: Colors.white, // Text color
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            const Text("Don't have an account?"),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Profile screen that is shown upon successful login.
// ====================================================
// Parent Profile Screen with Tabs (Overview, Past Orders, Update Info)
// ====================================================
class ProfileScreen extends StatefulWidget {
  final int userId; // User ID passed from login

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenWithTabsState createState() => _ProfileScreenWithTabsState();
}

class _ProfileScreenWithTabsState extends State<ProfileScreen> {
  // Controllers for username and password (shared by tabs)
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Used to greet the user by their first name
  String _firstName = "";
  bool _isLoading = true;
  final DBHelper _dbHelper = DBHelper();

  // Shared avatar state variables
  File? _avatar; // If user picks from camera/gallery
  String? _selectedPreset; // If user picks one of the preset avatars

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Loads user data from the database (to prefill username and get first name)
  Future<void> _loadUserData() async {
    final user = await _dbHelper.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        _usernameController.text = user['userName'];
        _firstName = user['firstName'];
        _isLoading = false;
      });
      // Call _loadAvatarState here so the saved avatar is loaded when the screen builds.
    _loadAvatarState();
    }
  }

  // Save the avatar state to shared_preferences
  Future<void> _saveAvatarState({File? avatar, String? preset}) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatar != null) {
      await prefs.setString('avatarPath', avatar.path);
      await prefs.remove('presetAvatar');
    } else if (preset != null) {
      await prefs.setString('presetAvatar', preset);
      await prefs.remove('avatarPath');
    } else {
      // If neither is set, clear both.
      await prefs.remove('avatarPath');
      await prefs.remove('presetAvatar');
    }
  }

  // Load the avatar state from shared_preferences and update our state.
  Future<void> _loadAvatarState() async {
    final prefs = await SharedPreferences.getInstance();
    String? avatarPath = prefs.getString('avatarPath');
    String? preset = prefs.getString('presetAvatar');
    setState(() {
      if (avatarPath != null) {
        _avatar = File(avatarPath);
        _selectedPreset = null;
      } else if (preset != null) {
        _selectedPreset = preset;
        _avatar = null;
      }
    });
  }

  // This callback is called from the Update Info tab when the avatar is changed.
  // We update our shared state and then save it.
  void _onAvatarUpdated({File? newAvatar, String? newPreset}) {
    setState(() {
      _avatar = newAvatar;
      _selectedPreset = newPreset;
    });
    _saveAvatarState(avatar: newAvatar, preset: newPreset);
  }


  // ---------------------------
  // LOGOUT FUNCTION
  // ---------------------------
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Clear the stored login state
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to Login page
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3, // Three tabs: Overview, Past Orders, Update Info
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: Text("Hello, $_firstName!"),
          actions: [
            // Logout button now calls our _logout function.
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Past Orders"),
              Tab(text: "Update Info"),
            ],
          ),
        ),
        drawer: const HomePage().buildLeftDrawer(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Overview Tab: Displays current user info and avatar.
                  ProfileOverviewContent(
                    userId: widget.userId,
                    // If a preset is chosen, use it; else if a file is chosen, use that; otherwise use default.
                    avatar: _selectedPreset != null
                        ? AssetImage(_selectedPreset!) as ImageProvider
                        : (_avatar != null
                            ? FileImage(_avatar!)
                            : const AssetImage('assets/default_avatar.png')),
                  ),
                  // Past Orders Tab: Displays the user's past orders.
                  PastOrdersContent(userId: widget.userId),
                  // Update Info Tab: Allows updating username, password, and avatar.
                  UpdateInfoContent(
                    userId: widget.userId,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    onAvatarUpdated: _onAvatarUpdated,
                  ),
                ],
              ),
      ),
    );
  }
}

// ====================================================
// Overview Tab Widget: Displays current user info and avatar
// ====================================================
class ProfileOverviewContent extends StatelessWidget {
  final int userId;
  final ImageProvider avatar; // Shared avatar passed from parent

  const ProfileOverviewContent({Key? key, required this.userId, required this.avatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to load user data from the database
    return FutureBuilder<Map<String, dynamic>?>(
      future: DBHelper().getUserById(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("No user data found."));
        }
        final user = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the shared avatar
              CircleAvatar(
                radius: 50,
                backgroundImage: avatar,
              ),
              const SizedBox(height: 20),
              Text(
                "Hello, ${user['firstName']} ${user['lastName']}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Username: ${user['userName']}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ====================================================
// Past Orders Tab Widget: Displays user's past orders
// ====================================================
class PastOrdersContent extends StatefulWidget {
  final int userId;

  const PastOrdersContent({Key? key, required this.userId}) : super(key: key);

  @override
  _PastOrdersContentState createState() => _PastOrdersContentState();
}

class _PastOrdersContentState extends State<PastOrdersContent> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  Future<void> _fetchOrders() async {
    final orders = await _dbHelper.getOrdersByUser(widget.userId);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty
            ? const Center(child: Text("No past orders found."))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text("Order #${order['orderID']}"),
                      subtitle: Text(
                        "Date: ${order['orderDate']}\nTotal: \$${(order['orderTotal'] as num).toStringAsFixed(2)}",
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
  }
}

// ====================================================
// Update Info Tab Widget: Allows updating user info and avatar
// ====================================================
class UpdateInfoContent extends StatefulWidget {
  final int userId;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Function({File? newAvatar, String? newPreset}) onAvatarUpdated;

  const UpdateInfoContent({
    Key? key,
    required this.userId,
    required this.usernameController,
    required this.passwordController,
    required this.onAvatarUpdated,
  }) : super(key: key);

  @override
  _UpdateInfoContentState createState() => _UpdateInfoContentState();
}

class _UpdateInfoContentState extends State<UpdateInfoContent> {
  final DBHelper _dbHelper = DBHelper();
  File? _avatar;
  String? _selectedPreset;
  final ImagePicker _picker = ImagePicker();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // List of preset avatar asset paths (adjust as needed)
  final List<String> _presetAvatars = [
    'assets/avatar1.jpg',
    'assets/avatar2.jpg',
    'assets/avatar3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // Initialize local notifications for avatar updates
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotificationsPlugin.initialize(initSettings);
  }

  // Update the user's info (username and password) in the database
  Future<void> _updateProfile() async {
    String newUsername = widget.usernameController.text.trim();
    String newPassword = widget.passwordController.text.trim();

    if (newUsername.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username and password cannot be empty")),
      );
      return;
    }

    int result = await _dbHelper.updateUser(widget.userId, newUsername, newPassword);

    if (result > 0) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  // Pick an avatar image from the specified source (camera or gallery)
  Future<void> _pickAvatarFromSource(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedPreset = null; // Clear preset if user picks a file
        _avatar = File(pickedFile.path);
      });
      // Update parent's shared state with the new avatar file
      widget.onAvatarUpdated(newAvatar: _avatar, newPreset: null);
      _showAvatarNotification();
    }
  }

  // Show a dialog with options: take photo, gallery, or choose preset avatar
  Future<void> _showAvatarOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Avatar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option for taking a photo
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarFromSource(ImageSource.camera);
                },
              ),
              // Option for choosing from gallery
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarFromSource(ImageSource.gallery);
                },
              ),
              // Option for choosing a preset avatar
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Choose Preset Avatar"),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPresetAvatarsDialog();
                },
              ),
            ],
          ),
          actions: [
            // Cancel button to dismiss the dialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Show a dialog with a grid of preset avatars to choose from
  Future<void> _showPresetAvatarsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select a Preset Avatar"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _presetAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final preset = _presetAvatars[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = preset;
                      _avatar = null; // Clear any previously picked image
                    });
                    Navigator.of(context).pop();
                    // Update parent's shared state with the preset asset path
                    widget.onAvatarUpdated(newAvatar: null, newPreset: preset);
                    _showAvatarNotification();
                  },
                  child: Image.asset(preset, fit: BoxFit.cover),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Show a local notification indicating the avatar was updated
  Future<void> _showAvatarNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'avatar_channel',
      'Avatar Notifications',
      channelDescription: 'Notification when avatar is updated',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotificationsPlugin.show(
      0,
      'Avatar Updated',
      'Your avatar has been updated!',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar selection widget (tap to open avatar options)
          Center(
            child: InkWell(
              onTap: _showAvatarOptions,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedPreset != null
                    ? AssetImage(_selectedPreset!)
                    : _avatar != null
                        ? FileImage(_avatar!)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                child: (_avatar == null && _selectedPreset == null)
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Username field
          const Text(
            "Update Username",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.usernameController,
            decoration: InputDecoration(
              hintText: "Enter new username",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          // Password field
          const Text(
            "Update Password",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.passwordController,
            decoration: InputDecoration(
              hintText: "Enter new password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 30),
          // Save Changes button
          Center(
            child: ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }
}


// Past orders screen

class PastOrdersScreen extends StatefulWidget {
  final int userId;

  const PastOrdersScreen({super.key, required this.userId});

  @override
  PastOrdersScreenState createState() => PastOrdersScreenState();
}

class PastOrdersScreenState extends State<PastOrdersScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  Future<void> _fetchOrders() async {
    final orders = await _dbHelper.getOrdersByUser(widget.userId);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Past Orders"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text("No past orders found."))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text("Order #${order['orderID']}"),
                        subtitle: Text(
                          "Date: ${order['orderDate']}\nTotal: \$${(order['orderTotal'] as num).toStringAsFixed(2)}",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}


// The sign-up page that allows a user to create an account.

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Global key to manage the form.
  final _formKey = GlobalKey<FormState>();

  // Controllers for the four text fields.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _usernameController  = TextEditingController();
  final TextEditingController _passwordController  = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // This function inserts the user into the database if valid.
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DBHelper();
      
      // Optionally, you can check if a user with the same username already exists.
      // Here, we perform a query using the username (ignoring password for uniqueness).
      final existingUsers = await DBHelper.database.then((db) =>
      db.query('users', where: 'userName = ?', whereArgs: [_usernameController.text.trim()])
      );

      
      if (existingUsers.isNotEmpty) {
        // Show an error message if the username is taken.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists!')),
        );
        return;
      }

      // Prepare the user data with keys matching the database schema.
      final newUser = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'userName': _usernameController.text.trim(), // Note: 'userName' must match the column name in the database.
        'password': _passwordController.text, // In production, never store plain text!
      };

      // Insert the new user into the database.
      await dbHelper.insertUser(newUser);

      // Navigate to the Login screen after a successful sign-up.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the global key to the form.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'Jane',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Smith',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'janesmith1',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:social_signin_buttons_plugin/social_signin_buttons_plugin.dart';
import 'db_helper.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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
        '/profile': (context) => throw UnimplementedError(), // Prevent direct navigation without userId
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
          onPressed: () {
              Navigator.pushNamed(context, '/login');
          },
        ),
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
class ProfileScreen extends StatefulWidget {
  final int userId; // User ID passed from login

  const ProfileScreen({super.key, required this.userId});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DBHelper _dbHelper = DBHelper();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Fetch user details when screen loads
  }

  Future<void> _loadUserData() async {
    final user = await _dbHelper.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        _usernameController.text = user['userName']; // Preload username
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    String newUsername = _usernameController.text.trim();
    String newPassword = _passwordController.text.trim();

    if (newUsername.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username and password cannot be empty")),
      );
      return;
    }

    int result = await _dbHelper.updateUser(widget.userId, newUsername, newPassword);

    if (result > 0) {
      setState(() {}); // Refresh UI after update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text("Profile Settings", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: const HomePage().buildLeftDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Update Username",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Enter new username",
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Update Password",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: "Enter new password",
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
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

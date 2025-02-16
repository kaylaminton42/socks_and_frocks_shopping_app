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

  runApp(MainApp(
    initialRoute: userId != null ? '/profile' : '/login',
    userId: userId,
  ));
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
      // Wrap all pages with an OrientationWrapper
      builder: (context, child) => OrientationWrapper(child: child!),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/tops': (context) => const ProductsPage(title: 'Tops'),
        '/bottoms': (context) => const ProductsPage(title: 'Bottoms'),
        '/outerwear': (context) => const ProductsPage(title: 'Outerwear'),
        '/accessories': (context) => const ProductsPage(title: 'Accessories'),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/item': (context) => ItemListingPage(
              product: ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/profile': (context) =>
            userId != null ? ProfileScreen(userId: userId!) : const LoginPage(),
        '/pastorders': (context) => PastOrdersScreen(
              userId: ModalRoute.of(context)!.settings.arguments as int,
            ),
      },
    );
  }
}

/// A common wrapper that uses OrientationBuilder so that each page can react to orientation.
class OrientationWrapper extends StatelessWidget {
  final Widget child;
  const OrientationWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Customize layout based on orientation if needed.
        return child;
      },
    );
  }
}

/// Creates an app bar to be used across the entire app.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? additionalActions;
  final PreferredSizeWidget? bottom;

  const CommonAppBar({
    Key? key,
    required this.title,
    required this.scaffoldKey,
    this.additionalActions,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.primary,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        // Home button
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        // Profile/Login button
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final int? userId = prefs.getInt('userId');
            if (userId != null) {
              Navigator.pushNamed(context, '/profile', arguments: userId);
            } else {
              Navigator.pushNamed(context, '/login');
            }
          },
        ),
        if (additionalActions != null) ...additionalActions!,
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// A common Navigation Drawer used by every page.
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.PNG', // Adjust the path if needed
                  height: 80,
                ),
                const SizedBox(height: 10),
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

/// -------------------- HOME PAGE --------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  // Use NavigationDrawer for consistency.
  Widget buildLeftDrawer(BuildContext context) => const NavigationDrawer();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample featured collections.
  final List<Map<String, String>> featuredCollections = [
    {'title': 'Tops', 'route': '/tops'},
    {'title': 'Bottoms', 'route': '/bottoms'},
    {'title': 'Outerwear', 'route': '/outerwear'},
    {'title': 'Accessories', 'route': '/accessories'},
    {'title': 'Sale', 'route': '/'}, // Example.
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;

    // Adjust carousel heights and spacing.
    final double firstCarouselHeight = orientation == Orientation.portrait ? 180 : 160;
    final double secondCarouselHeight = orientation == Orientation.portrait ? 180 : 160;
    final double extraSpacing = orientation == Orientation.portrait ? 20 : 10;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Socks & Frocks',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar.
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
            SizedBox(height: extraSpacing),
            // Featured Collections carousel.
            SizedBox(
              height: firstCarouselHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredCollections.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        featuredCollections[index]['route']!,
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.white,
                            ),
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
            SizedBox(height: extraSpacing * 2),
            // Featured Items label.
            const Text(
              'Featured Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Featured Items carousel.
            SizedBox(
              height: secondCarouselHeight,
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
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.white,
                    ),
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

/// -------------------- PRODUCTS PAGE --------------------
class ProductsPage extends StatefulWidget {
  final String title;
  const ProductsPage({super.key, required this.title});

  @override
  ProductsPageState createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
    final double childAspect = orientation == Orientation.portrait ? 0.75 : 0.9;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Socks & Frocks',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(16.0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("No products available"))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspect,
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
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 80,
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 50,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
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
                  const SizedBox(height: 6),
                  Text(
                    "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16,
                    ),
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

/// -------------------- ITEM LISTING PAGE --------------------
class ItemListingPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ItemListingPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: product['productName'],
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['productName'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.tertiary),
            ),
            const SizedBox(height: 16),
            Text(
              product['productDesc'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
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

/// -------------------- LOGIN PAGE --------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final String userName = _usernameController.text.trim();
    final String password = _passwordController.text;

    final dbHelper = DBHelper();
    final matchingUser = await dbHelper.getUserByCredentials(userName, password);

    if (matchingUser != null) {
      int userId = matchingUser['userID'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Login',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
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

/// -------------------- PROFILE SCREEN --------------------
class ProfileScreen extends StatefulWidget {
  final int userId;
  ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenWithTabsState createState() => _ProfileScreenWithTabsState();
}

class _ProfileScreenWithTabsState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _firstName = "";
  bool _isLoading = true;
  final DBHelper _dbHelper = DBHelper();

  File? _avatar;
  String? _selectedPreset;

  // Local notifications plugin instance.
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeNotifications(); // Initialize notifications on startup.
    _loadUserData();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadUserData() async {
    final user = await _dbHelper.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        _usernameController.text = user['userName'];
        _firstName = user['firstName'];
        _isLoading = false;
      });
      _loadAvatarState();
    }
  }

  Future<void> _saveAvatarState({File? avatar, String? preset}) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatar != null) {
      await prefs.setString('avatarPath', avatar.path);
      await prefs.remove('presetAvatar');
    } else if (preset != null) {
      await prefs.setString('presetAvatar', preset);
      await prefs.remove('avatarPath');
    } else {
      await prefs.remove('avatarPath');
      await prefs.remove('presetAvatar');
    }
  }

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

  void _onAvatarUpdated({File? newAvatar, String? newPreset}) {
    setState(() {
      _avatar = newAvatar;
      _selectedPreset = newPreset;
    });
    _saveAvatarState(avatar: newAvatar, preset: newPreset);
    _showAvatarNotification();
  }

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: CommonAppBar(
          title: "Hello, $_firstName!",
          scaffoldKey: _scaffoldKey,
          additionalActions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        drawer: const NavigationDrawer(),
        body: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).colorScheme.tertiary,
              unselectedLabelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: "Overview"),
                Tab(text: "Past Orders"),
                Tab(text: "Update Info"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ProfileOverviewContent(
                    userId: widget.userId,
                    avatar: _selectedPreset != null
                        ? AssetImage(_selectedPreset!) as ImageProvider
                        : (_avatar != null
                            ? FileImage(_avatar!)
                            : const AssetImage('assets/default_avatar.png')),
                  ),
                  PastOrdersContent(userId: widget.userId),
                  UpdateInfoContent(
                    userId: widget.userId,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    onAvatarUpdated: _onAvatarUpdated,
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

/// -------------------- PROFILE OVERVIEW CONTENT --------------------
class ProfileOverviewContent extends StatelessWidget {
  final int userId;
  final ImageProvider avatar;

  const ProfileOverviewContent({Key? key, required this.userId, required this.avatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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

/// -------------------- PAST ORDERS CONTENT --------------------
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

/// -------------------- UPDATE INFO CONTENT --------------------
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

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _updateProfile() async {
    String newUsername = widget.usernameController.text.trim();
    String newPassword = widget.passwordController.text.trim();

    final currentUser = await _dbHelper.getUserById(widget.userId);
    if (newUsername.isEmpty) {
      newUsername = currentUser?['userName'] ?? "";
    }
    if (newPassword.isEmpty) {
      newPassword = currentUser?['password'] ?? "";
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

  Future<void> _pickAvatarFromSource(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedPreset = null;
        _avatar = File(pickedFile.path);
      });
      widget.onAvatarUpdated(newAvatar: _avatar, newPreset: null);
      _showAvatarNotification();
    }
  }

  Future<void> _showAvatarOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Avatar"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarFromSource(ImageSource.gallery);
                },
              ),
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
                      _avatar = null;
                    });
                    Navigator.of(context).pop();
                    widget.onAvatarUpdated(newAvatar: null, newPreset: preset);
                    _showAvatarNotification();
                  },
                  child: Image.asset(
                    preset,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

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

/// -------------------- PAST ORDERS SCREEN --------------------
class PastOrdersScreen extends StatefulWidget {
  final int userId;
  const PastOrdersScreen({super.key, required this.userId});

  @override
  PastOrdersScreenState createState() => PastOrdersScreenState();
}

class PastOrdersScreenState extends State<PastOrdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: "Past Orders",
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
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

/// -------------------- SIGN UP PAGE --------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _usernameController  = TextEditingController();
  final TextEditingController _passwordController  = TextEditingController();

  // State-level GlobalKey for the Scaffold.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DBHelper();

      final existingUsers = await DBHelper.database.then((db) =>
          db.query('users', where: 'userName = ?', whereArgs: [_usernameController.text.trim()])
      );

      if (existingUsers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists!')),
        );
        return;
      }

      final newUser = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'userName': _usernameController.text.trim(),
        'password': _passwordController.text,
      };

      await dbHelper.insertUser(newUser);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Create Account',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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

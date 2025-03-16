// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:social_signin_buttons_plugin/social_signin_buttons_plugin.dart';
import 'db_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io'; //show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socks_and_frocks_shopping_app/runner_game.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


Future<int?> _getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('userId');

  runApp(MainApp(
    initialRoute: '/',
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
        '/allProducts': (context) => const AllProductsPage(title: 'All Items'),
        '/tops': (context) => const ProductsPage(title: 'Tops'),
        '/bottoms': (context) => const ProductsPage(title: 'Bottoms'),
        '/dresses': (context) => const ProductsPage(title: 'Dresses'),
        '/outerwear': (context) => const ProductsPage(title: 'Outerwear'),
        '/accessories': (context) => const ProductsPage(title: 'Accessories'),
        '/sale': (context) => const SaleItemsPage(title: 'On Sale Now'),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/item': (context) => ItemListingPage(
              product: ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>,
            ),
        '/profile': (context) {
          return FutureBuilder<int?>(
            future: _getUserId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData && snapshot.data != null) {
                return ProfileScreen(userId: snapshot.data!);
              }
              return const LoginPage();
            },
          );
        },
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/game': (context) => const RunnerGame(),
        //'/pastorders': (context) => PastOrdersScreen(
        //    userId: ModalRoute.of(context)!.settings.arguments as int,
        //),
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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    // Optionally clear the cart
    Cart().clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    final bool showBackButton =
        currentRoute != '/' && Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: colorScheme.primary,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            ),
      actions: [
        // Home button always visible.
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        // Cart button always visible.
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              if (Cart().items.isNotEmpty)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${Cart().items.fold(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),

        // Overflow menu for additional actions.
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            if (value == 'game') {
              Navigator.pushNamed(context, '/game');
            } else if (value == 'profile') {
              final prefs = await SharedPreferences.getInstance();
              final int? userId = prefs.getInt('userId');
              if (userId != null) {
                Navigator.pushNamed(context, '/profile', arguments: userId);
              } else {
                Navigator.pushNamed(context, '/login');
              }
            } else if (value == 'logout') {
              await _logout(context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'game',
              child: ListTile(
                leading: Icon(Icons.videogame_asset),
                title: Text('Game'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'profile',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Profile'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log Out'),
              ),
            ),
          ],
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

//Widget for Gift Card Link

class GiftCardLink extends StatelessWidget {
  const GiftCardLink({Key? key}) : super(key: key);

  // Determine the URL based on the platform.
  String getGiftCardUrl() {
    if (kIsWeb) {
      // On web, use localhost.
      return "http://localhost/ict4580/registration.html";
    } else {
      if (Platform.isAndroid) {
        // For Android emulator, use 10.0.2.2.
        return "http://10.0.2.2//ict4580/registration.html";
      } else if (Platform.isIOS) {
        // For iOS simulators, localhost is usually correct.
        return "http://localhost/ict4580/registration.html";
      } else {
        return "http://localhost/ict4580/registration.html";
      }
    }
  }

  Future<void> _launchGiftCardWebsite() async {
    final Uri url = Uri.parse(getGiftCardUrl());
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _launchGiftCardWebsite,
      icon: const Icon(Icons.card_giftcard),
      label: const Text('Get Your Free Gift Card'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Creates a footer to be used across the entire app.
class CommonFooter extends StatelessWidget {
  const CommonFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Define your two parts of the footer
        final partOne = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '© 2025 Socks & Frocks, LLC',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              'All rights reserved',
              style: TextStyle(color: Color(0xFFC5C5C5), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        );
        final partTwo = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.facebook, color: Colors.white),
              onPressed: () {
                // Handle Facebook tap
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.twitter, color: Colors.white),
              onPressed: () {
                // Handle Twitter tap
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.white),
              onPressed: () {
                // Handle Instagram tap
              },
            ),
          ],
        );

        // In portrait, display them in a column; in landscape, display side by side.
        return Container(
          color: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          child: orientation == Orientation.portrait
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    partOne,
                    const SizedBox(height: 8),
                    partTwo,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Wrap partOne in an Expanded to allow it to take available space.
                    Expanded(child: partOne),
                    partTwo,
                  ],
                ),
        );
      },
    );
  }
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
                  'assets/logo.PNG',
                  semanticLabel: 'A square purple robot on a teal background', // Alt text for screen readers.
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
                title: const Text('All Items'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/allProducts');
                },
              ),
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
                title: const Text('Dresses'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dresses');
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
              ListTile(
                title: const Text('Sale'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/sale');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -------------------- BEGIN HOME PAGE --------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  // Use NavigationDrawer for consistency.
  Widget buildLeftDrawer(BuildContext context) => const NavigationDrawer();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  // featured collections
  final List<Map<String, String>> featuredCollections = [
    {'title': 'All Items', 'route': '/allProducts', 'image': 'assets/categories/allProducts.png', 'alt': 'All items in stock',},
    {'title': 'Tops', 'route': '/tops', 'image': 'assets/categories/tops.png', 'alt': 'A selection of trendy tops',},
    {'title': 'Bottoms', 'route': '/bottoms', 'image': 'assets/categories/bottoms.png', 'alt': 'Various styles of pants and skirts',},
    {'title': 'Dresses', 'route': '/dresses', 'image': 'assets/categories/dresses.png', 'alt': 'A variety of dresses for all occasions',},
    {'title': 'Outerwear', 'route': '/outerwear', 'image': 'assets/categories/outerwear.png', 'alt': 'Jackets, coats, and sweaters',},
    {'title': 'Accessories', 'route': '/accessories', 'image': 'assets/categories/accessories.png', 'alt': 'Shoes, handbags, jewelry, and more',},
    {'title': 'Sale', 'route': '/sale', 'image': 'assets/categories/sale.png', 'alt': 'Discounted items',},
  ];

  // featured items
  final List<Map<String, dynamic>> featuredItems = [
    {
      'productID': 101,
      'productName': 'Colorful Tie Blouse',
      'productPrice': 20.00,
      'image': 'assets/products/colorful_top.png',
      'productDesc': 'White blouse with a cute colorful pattern and a black ribbon in the back for a bow.',
      'alt': 'Colorful tie blouse',
    },
    {
      'productID': 103,
      'productName': 'Summer Dress',
      'productPrice': 35.00,
      'image': 'assets/products/summer_dress.jpg',
      'productDesc': 'Floral summer dress',
      'alt': 'Floral summer dress',
    },
    {
      'productID': 102,
      'productName': 'Linen Pants',
      'productPrice': 20.00,
      'image': 'assets/products/linen_pants.JPEG',
      'productDesc': 'Khaki-colored linen pants for a casual look.',
      'alt': 'Linen pants in a khaki color',
    },
    {
      'productID': 107,
      'productName': 'Teal Blouse',
      'productPrice': 20.00,
      'image': 'assets/products/teal_blouse.JPEG',
      'productDesc': 'Comfy, casual teal blouse.',
      'alt': 'Teal sleeveless blouse',
    },
    {
      'productID': 109,
      'productName': 'Maxi Dress',
      'productPrice': 35.00,
      'image': 'assets/products/maxi_dress.jpg',
      'productDesc': 'Long, knit dress',
      'alt': 'Long, sleeveless maxi dress in a gray color and knit fabric',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;

    // Calculate dynamic spacing and carousel heights.
    final double extraSpacing = orientation == Orientation.portrait
        ? screenSize.height * 0.02
        : screenSize.height * 0.025;
    final double firstCarouselHeight = orientation == Orientation.portrait
        ? screenSize.height * 0.25
        : screenSize.height * 0.45;
    final double secondCarouselHeight = orientation == Orientation.portrait
        ? screenSize.height * 0.25
        : screenSize.height * 0.45;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Home',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: extraSpacing,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar with onSubmitted handler
            TextField(
              controller: _searchController,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsPage(query: value.trim()),
                    ),
                  );
                }
              },
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
                        Semantics(
                          label: featuredCollections[index]['alt']!,
                          child: Container(
                            margin: EdgeInsets.all(screenSize.width * 0.02),
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(featuredCollections[index]['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          featuredCollections[index]['title']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
          SizedBox(height: extraSpacing),
          // Featured Items carousel.
          SizedBox(
            height: secondCarouselHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredItems.length,
              itemBuilder: (context, index) {
                final product = featuredItems[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to the item listing page with the product details.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemListingPage(product: product),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Semantics(
                        label: product['altText'], // Provide the alt text for the image.
                        child: Container(
                          margin: EdgeInsets.all(screenSize.width * 0.02),
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(product['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        product['productName'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

            // Button to launch the gift card website.
            const Text(
              'Free Gift Card Offer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const GiftCardLink(),
          ],
        ),
      ),

      

      bottomNavigationBar: const CommonFooter(),
    );
  }
}
/// -------------------- END HOME PAGE --------------------

/// -------------------- BEGIN ALL PRODUCTS PAGE --------------------
enum SortOption { priceAsc, priceDesc, nameAsc, nameDesc }

class AllProductsPage extends StatefulWidget {
  final String title;
  const AllProductsPage({Key? key, required this.title}) : super(key: key);

  @override
  _AllProductsPageState createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _displayedProducts = [];
  bool _isLoading = true;

  // Sort state.
  SortOption _selectedSortOption = SortOption.priceAsc;

  // Filter state for colors.
  Set<String> _selectedColors = {};
  final List<String> _availableColors = [
    'Red',
    'Orange',
    'Yellow',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'White',
    'Black',
    'Multicolor',
    'Gray',
    'Khaki',
    'Beige',
    'Cream',
    'Teal',
  ];

  // Filter state for styles.
  Set<String> _selectedStyles = {};
  final List<String> _availableStyles = [
    'Casual',
    'Formal',
    'Business Casual',
    'Business Professional',
    'Loungewear',
    'Going Out'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // Get all products from the database, including colors and styles.
    _products = await DBHelper().getAllProducts();
    _applySortAndFilter();
    setState(() {
      _isLoading = false;
    });
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> temp = List.from(_products);

    // Filter by color if any colors are selected.
    if (_selectedColors.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productColors = (product['colors'] is List)
            ? List<String>.from(product['colors'])
            : [];
        return productColors.any((c) => _selectedColors.contains(c));
      }).toList();
    }

    // Filter by style if any styles are selected.
    if (_selectedStyles.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productStyles = (product['styles'] is List)
            ? List<String>.from(product['styles'])
            : [];
        return productStyles.any((s) => _selectedStyles.contains(s));
      }).toList();
    }

    // Apply sorting.
    switch (_selectedSortOption) {
      case SortOption.priceAsc:
        temp.sort((a, b) {
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceA.compareTo(effectivePriceB);
        });
        break;
      case SortOption.priceDesc:
        temp.sort((a, b) {
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceB.compareTo(effectivePriceA);
        });
        break;
      case SortOption.nameAsc:
        temp.sort((a, b) =>
            (a['productName'] as String).compareTo(b['productName'] as String));
        break;
      case SortOption.nameDesc:
        temp.sort((a, b) =>
            (b['productName'] as String).compareTo(a['productName'] as String));
        break;
    }

    setState(() {
      _displayedProducts = temp;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Sort Options',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: Low to High'),
                              value: SortOption.priceAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: High to Low'),
                              value: SortOption.priceDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: A-Z'),
                              value: SortOption.nameAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: Z-A'),
                              value: SortOption.nameDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Filter Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Expandable filter for Color.
                                ExpansionTile(
                                  title: const Text('Color'),
                                  children: _availableColors.map((color) {
                                    return CheckboxListTile(
                                      title: Text(color),
                                      value: _selectedColors.contains(color),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedColors.add(color);
                                          } else {
                                            _selectedColors.remove(color);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                // Expandable filter for Style.
                                ExpansionTile(
                                  title: const Text('Style'),
                                  children: _availableStyles.map((style) {
                                    return CheckboxListTile(
                                      title: Text(style),
                                      value: _selectedStyles.contains(style),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedStyles.add(style);
                                          } else {
                                            _selectedStyles.remove(style);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedColors.clear();
                                          _selectedStyles.clear();
                                        });
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear Filters'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _applySortAndFilter();
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Apply Filters'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Reusable product card widget updated for sale pricing.
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Semantics(
                  label: product['altText'] ?? 'Product image',
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      product['image'] ?? 'assets/product_placeholder.png',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Text(
                      product['productName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Price display: show both original and sale price if applicable.
                  product['onSale'] == 1
                      ? Column(
                          children: [
                            Text(
                              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "\$${(product['salePrice'] as num).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
    // Adjust the childAspectRatio to ensure the cards are taller.
    final double childAspect = orientation == Orientation.portrait ? 0.65 : 0.70;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: widget.title,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Column(
        children: [
          // Sort and Filter Buttons.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                    onPressed: _showSortOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filter'),
                    onPressed: _showFilterOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(4.0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
                    ? const Center(child: Text("No products available"))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspect,
                          ),
                          itemCount: _displayedProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                                context, _displayedProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// -------------------- END ALL PRODUCTS PAGE --------------------

/// -------------------- BEGIN PRODUCTS PAGE --------------------

class ProductsPage extends StatefulWidget {
  final String title;
  const ProductsPage({super.key, required this.title});

  @override
  ProductsPageState createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _displayedProducts = [];
  bool _isLoading = true;

  // Sort state.
  SortOption _selectedSortOption = SortOption.priceAsc;

  // Filter state.
  Set<String> _selectedColors = {};
  final List<String> _availableColors = [
    'Red',
    'Orange',
    'Yellow',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'White',
    'Black',
    'Multicolor',
    'Gray',
    'Khaki',
    'Beige',
    'Cream',
    'Teal',
  ];

  // Filter for style.
  Set<String> _selectedStyles = {};
  final List<String> _availableStyles = [
    'Casual',
    'Formal',
    'Business Casual',
    'Business Professional',
    'Loungewear',
    'Going Out'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // Get products by category and include colors and styles from join tables.
    _products = await DBHelper().getProductsByCategory(widget.title);
    _applySortAndFilter();
    setState(() {
      _isLoading = false;
    });
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> temp = List.from(_products);

    // Filter by color.
    if (_selectedColors.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productColors = (product['colors'] is List)
            ? List<String>.from(product['colors'])
            : [];
        return productColors.any((c) => _selectedColors.contains(c));
      }).toList();
    }

    // Filter by style.
    if (_selectedStyles.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productStyles = (product['styles'] is List)
            ? List<String>.from(product['styles'])
            : [];
        return productStyles.any((s) => _selectedStyles.contains(s));
      }).toList();
    }

    // Sorting.
    switch (_selectedSortOption) {
      case SortOption.priceAsc:
        temp.sort((a, b) {
          // Determine effective price for product a.
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          // Determine effective price for product b.
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceA.compareTo(effectivePriceB);
        });
        break;
      case SortOption.priceDesc:
        temp.sort((a, b) {
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceB.compareTo(effectivePriceA);
        });
        break;
      case SortOption.nameAsc:
        temp.sort((a, b) =>
            (a['productName'] as String).compareTo(b['productName'] as String));
        break;
      case SortOption.nameDesc:
        temp.sort((a, b) =>
            (b['productName'] as String).compareTo(a['productName'] as String));
        break;
    }

    setState(() {
      _displayedProducts = temp;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Sort Options',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: Low to High'),
                              value: SortOption.priceAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: High to Low'),
                              value: SortOption.priceDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: A-Z'),
                              value: SortOption.nameAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: Z-A'),
                              value: SortOption.nameDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Filter Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Expandable filter for Color.
                                ExpansionTile(
                                  title: const Text('Color'),
                                  children: _availableColors.map((color) {
                                    return CheckboxListTile(
                                      title: Text(color),
                                      value: _selectedColors.contains(color),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedColors.add(color);
                                          } else {
                                            _selectedColors.remove(color);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                // Expandable filter for Style.
                                ExpansionTile(
                                  title: const Text('Style'),
                                  children: _availableStyles.map((style) {
                                    return CheckboxListTile(
                                      title: Text(style),
                                      value: _selectedStyles.contains(style),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedStyles.add(style);
                                          } else {
                                            _selectedStyles.remove(style);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedColors.clear();
                                          _selectedStyles.clear();
                                        });
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear Filters'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _applySortAndFilter();
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Apply Filters'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Reusable product card widget updated for sale pricing.
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Semantics(
                  label: product['altText'] ?? 'Product image',
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      product['image'] ?? 'assets/product_placeholder.png',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Text(
                      product['productName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Price display: show both original and sale price if applicable.
                  product['onSale'] == 1
                      ? Column(
                          children: [
                            Text(
                              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "\$${(product['salePrice'] as num).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
    // Adjust the childAspectRatio to ensure the cards are taller.
    final double childAspect = orientation == Orientation.portrait ? 0.65 : 0.70;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: widget.title,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Column(
        children: [
          // Sort and Filter Buttons.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                    onPressed: _showSortOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filter'),
                    onPressed: _showFilterOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(4.0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
                    ? const Center(child: Text("No products available"))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspect,
                          ),
                          itemCount: _displayedProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                                context, _displayedProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}



/// -------------------- END PRODUCTS PAGE --------------------

/// -------------------- BEGIN SALE ITEMS PAGE --------------------

class SaleItemsPage extends StatefulWidget {
  final String title;
  const SaleItemsPage({super.key, required this.title});

  @override
  _SaleItemsPageState createState() => _SaleItemsPageState();
}

class _SaleItemsPageState extends State<SaleItemsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _displayedProducts = [];
  bool _isLoading = true;

  // Sort state.
  SortOption _selectedSortOption = SortOption.priceAsc;

  // Filter state.
  Set<String> _selectedColors = {};
  final List<String> _availableColors = [
    'Red',
    'Orange',
    'Yellow',
    'Blue',
    'Green',
    'Purple',
    'Pink',
    'White',
    'Black',
    'Multicolor',
    'Gray',
    'Khaki',
    'Beige',
    'Cream',
    'Teal',
  ];

  // Filter for style.
  Set<String> _selectedStyles = {};
  final List<String> _availableStyles = [
    'Casual',
    'Formal',
    'Business Casual',
    'Business Professional',
    'Loungewear',
    'Going Out'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    // Use getSaleProducts() to fetch only sale items.
    _products = await DBHelper().getSaleProducts();
    _applySortAndFilter();
    setState(() {
      _isLoading = false;
    });
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> temp = List.from(_products);

    // Filter by color.
    if (_selectedColors.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productColors = (product['colors'] is List)
            ? List<String>.from(product['colors'])
            : [];
        return productColors.any((c) => _selectedColors.contains(c));
      }).toList();
    }

    // Filter by style.
    if (_selectedStyles.isNotEmpty) {
      temp = temp.where((product) {
        List<String> productStyles = (product['styles'] is List)
            ? List<String>.from(product['styles'])
            : [];
        return productStyles.any((s) => _selectedStyles.contains(s));
      }).toList();
    }

    // Sorting.
    switch (_selectedSortOption) {
      case SortOption.priceAsc:
        temp.sort((a, b) {
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceA.compareTo(effectivePriceB);
        });
        break;
      case SortOption.priceDesc:
        temp.sort((a, b) {
          final double effectivePriceA = (a['onSale'] == 1)
              ? (a['salePrice'] as num).toDouble()
              : (a['productPrice'] as num).toDouble();
          final double effectivePriceB = (b['onSale'] == 1)
              ? (b['salePrice'] as num).toDouble()
              : (b['productPrice'] as num).toDouble();
          return effectivePriceB.compareTo(effectivePriceA);
        });
        break;
      case SortOption.nameAsc:
        temp.sort((a, b) =>
            (a['productName'] as String).compareTo(b['productName'] as String));
        break;
      case SortOption.nameDesc:
        temp.sort((a, b) =>
            (b['productName'] as String).compareTo(a['productName'] as String));
        break;
    }

    setState(() {
      _displayedProducts = temp;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: heightFactor,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Sort Options',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: Low to High'),
                              value: SortOption.priceAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Price: High to Low'),
                              value: SortOption.priceDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: A-Z'),
                              value: SortOption.nameAsc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<SortOption>(
                              title: const Text('Name: Z-A'),
                              value: SortOption.nameDesc,
                              groupValue: _selectedSortOption,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSortOption = value!;
                                });
                                _applySortAndFilter();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final orientation = MediaQuery.of(context).orientation;
        final double heightFactor =
            orientation == Orientation.portrait ? 0.6 : 0.8;
        final double horizontalPadding =
            orientation == Orientation.landscape ? 32.0 : 16.0;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Filter Options',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Expandable filter for Color.
                                ExpansionTile(
                                  title: const Text('Color'),
                                  children: _availableColors.map((color) {
                                    return CheckboxListTile(
                                      title: Text(color),
                                      value: _selectedColors.contains(color),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedColors.add(color);
                                          } else {
                                            _selectedColors.remove(color);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                // Expandable filter for Style.
                                ExpansionTile(
                                  title: const Text('Style'),
                                  children: _availableStyles.map((style) {
                                    return CheckboxListTile(
                                      title: Text(style),
                                      value: _selectedStyles.contains(style),
                                      onChanged: (bool? value) {
                                        setModalState(() {
                                          if (value ?? false) {
                                            _selectedStyles.add(style);
                                          } else {
                                            _selectedStyles.remove(style);
                                          }
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedColors.clear();
                                          _selectedStyles.clear();
                                        });
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear Filters'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _applySortAndFilter();
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Apply Filters'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Reusable product card widget updated for sale pricing.
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: Semantics(
                  label: product['altText'] ?? 'Product image',
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset(
                      product['image'] ?? 'assets/product_placeholder.png',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Text(
                      product['productName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Price display: show both original and sale price if applicable.
                  product['onSale'] == 1
                      ? Column(
                          children: [
                            Text(
                              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "\$${(product['salePrice'] as num).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
    final double childAspect = orientation == Orientation.portrait ? 0.65 : 0.70;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: widget.title,
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Column(
        children: [
          // Sort and Filter Buttons.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                    onPressed: _showSortOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filter'),
                    onPressed: _showFilterOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(4.0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedProducts.isEmpty
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
                          itemCount: _displayedProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(context, _displayedProducts[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


/// -------------------- BEGIN ITEM LISTING PAGE --------------------
class ItemListingPage extends StatelessWidget {
  final Map<String, dynamic> product;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ItemListingPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final double verticalSpacing = screenSize.height * 0.02;
    final double horizontalPadding = screenSize.width * 0.04;
    // Adjust image height based on orientation.
    final double imageHeight = orientation == Orientation.portrait
        ? screenSize.height * 0.50
        : screenSize.height * 0.80;

    // Build image widget.
    Widget imageWidget = Container(
      height: imageHeight,
      width: orientation == Orientation.portrait ? double.infinity : screenSize.width * 0.4,
      child: Semantics(
        label: product['altText'] ?? 'Product image',
        child: Image.asset(
          product['image'] ?? 'assets/product_placeholder.png',
          fit: BoxFit.contain,
        ),
      ),
    );

    // Build price widget.
    Widget priceWidget;
    if (product['onSale'] == 1) {
      priceWidget = Column(
        children: [
          Text(
            "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
            textAlign: orientation == Orientation.landscape ? TextAlign.left : TextAlign.center,
          ),
          Text(
            "\$${(product['salePrice'] as num).toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: orientation == Orientation.landscape ? TextAlign.left : TextAlign.center,
          ),
        ],
      );
    } else {
      priceWidget = Text(
        "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
        style: TextStyle(
          fontSize: 20,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        textAlign: orientation == Orientation.landscape ? TextAlign.left : TextAlign.center,
      );
    }

    // Build details widget.
    Widget details = Column(
      crossAxisAlignment: orientation == Orientation.landscape
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(height: verticalSpacing),
        Text(
          product['productName'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: orientation == Orientation.landscape ? TextAlign.left : TextAlign.center,
        ),
        SizedBox(height: verticalSpacing * 0.5),
        // Use the price widget here.
        priceWidget,
        SizedBox(height: verticalSpacing),
        Text(
          product['productDesc'],
          style: const TextStyle(fontSize: 16),
          textAlign: orientation == Orientation.landscape ? TextAlign.left : TextAlign.center,
        ),
        SizedBox(height: verticalSpacing * 1.5),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Cart().addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${product['productName']} added to cart")),
              );
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text("Add to Cart"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.08,
                vertical: screenSize.height * 0.015,
              ),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );

    // Wrap details in a scrollable widget.
    Widget detailsScrollable = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: details,
      ),
    );

    Widget content;
    if (orientation == Orientation.landscape) {
      // Add extra top padding in landscape mode.
      content = Padding(
        padding: EdgeInsets.only(top: verticalSpacing * 2.5, bottom: verticalSpacing * 2.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageWidget,
            SizedBox(width: screenSize.width * 0.02),
            Expanded(child: detailsScrollable),
          ],
        ),
      );
    } else {
      content = SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              imageWidget,
              SizedBox(height: verticalSpacing),
              details,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: ' ',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: content,
    );
  }
}


/// -------------------- END ITEM LISTING PAGE --------------------

/// -------------------- BEGIN LOGIN PAGE --------------------
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
    // Get orientation and screen size.
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    // Use more horizontal padding in landscape.
    final double horizontalPadding = orientation == Orientation.portrait
        ? 16.0
        : screenSize.width * 0.2;
    // Adjust vertical spacing if needed.
    final double verticalSpacing = orientation == Orientation.portrait ? 20.0 : 12.0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Login',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16.0,
          ),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'janesmith',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              SizedBox(height: verticalSpacing),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
              SizedBox(height: verticalSpacing),
              const Text("Don't have an account?"),
              SizedBox(height: verticalSpacing * 0.5),
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
      ),
    );
  }
}

/// -------------------- END LOGIN PAGE --------------------

/// -------------------- BEGIN PROFILE SCREEN --------------------
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
      _loadAvatarState(widget.userId);
    }
  }

  Future<void> _saveAvatarState({required int userId, File? avatar, String? preset}) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatar != null) {
      await prefs.setString('avatarPath_$userId', avatar.path);
      await prefs.remove('presetAvatar_$userId');
    } else if (preset != null) {
      await prefs.setString('presetAvatar_$userId', preset);
      await prefs.remove('avatarPath_$userId');
    } else {
      await prefs.remove('avatarPath_$userId');
      await prefs.remove('presetAvatar_$userId');
    }
  }

  Future<void> _loadAvatarState(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? avatarPath = prefs.getString('avatarPath_$userId');
    String? preset = prefs.getString('presetAvatar_$userId');
    setState(() {
      if (avatarPath != null) {
        _avatar = File(avatarPath);
        _selectedPreset = null;
      } else if (preset != null) {
        _selectedPreset = preset;
        _avatar = null;
      } else {
        _avatar = null;
        _selectedPreset = null;
      }
    });
  }

  void _onAvatarUpdated({File? newAvatar, String? newPreset}) {
    setState(() {
      _avatar = newAvatar;
      _selectedPreset = newPreset;
    });
    // Pass the user ID along with the new avatar information
    _saveAvatarState(userId: widget.userId, avatar: newAvatar, preset: newPreset);
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
    // Clear the global cart
    Cart().clear();
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
/// -------------------- END PROFILE SCREEN --------------------

/// -------------------- BEGIN PROFILE OVERVIEW CONTENT --------------------
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
/// -------------------- END PROFILE OVERVIEW CONTENT --------------------

/// -------------------- BEGIN PAST ORDERS CONTENT --------------------
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
  }
}
/// -------------------- END PAST ORDERS CONTENT --------------------

/// -------------------- BEGIN UPDATE INFO CONTENT --------------------
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
  final orientation = MediaQuery.of(context).orientation;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        insetPadding: orientation == Orientation.landscape
            ? const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0)
            : const EdgeInsets.all(20.0),
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
  final orientation = MediaQuery.of(context).orientation;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        insetPadding: orientation == Orientation.landscape
            ? const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0)
            : const EdgeInsets.all(20.0),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
                _showAvatarOptions();
              },
            ),
            const SizedBox(width: 8),
            const Text("Select a Preset Avatar"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: _presetAvatars.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: orientation == Orientation.landscape ? 4 : 3,
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
/// -------------------- END UPDATE INFO CONTENT --------------------

/// --------------------  BEGIN SIGN UP PAGE --------------------
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
    final orientation = MediaQuery.of(context).orientation;
    final screenSize = MediaQuery.of(context).size;
    // For portrait: fixed padding; for landscape: use a percentage of screen width.
    final double horizontalPadding = orientation == Orientation.portrait
        ? 16.0
        : screenSize.width * 0.2;
    // Optionally adjust vertical spacing.
    final double verticalSpacing = orientation == Orientation.portrait ? 20.0 : 16.0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Create Account',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16.0,
          ),
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
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Smith',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'janesmith',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'superSecretPassword123',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
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
                SizedBox(height: verticalSpacing),
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
      ),
    );
  }
}

/// ------------------- END SIGN UP PAGE --------------------

/// ------------------- BEGIN ORDER DETAILS SCREEN --------------------
class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _orderedProducts = [];
  bool _isLoading = true;

  Future<void> _fetchOrderedProducts() async {
    final products = await _dbHelper.getOrderedProductsByOrderId(widget.order['orderID']);
    setState(() {
      _orderedProducts = products;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchOrderedProducts();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFF795CAF),
      foregroundColor: Colors.white,
      title: Text("Order #${widget.order['orderID']} Details"),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Number: ${widget.order['orderID']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Order Date: ${widget.order['orderDate']}",
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "Order Total: \$${(widget.order['orderTotal'] as num).toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(height: 32),
          const Text(
            "Receipt",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orderedProducts.isEmpty
                  ? const Text("No products found for this order.")
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _orderedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _orderedProducts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4.0),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Semantics(
                                    label: product['altText'] ?? 'Product image',
                                    child: Image.asset(
                                      product['image'] ?? 'assets/product_placeholder.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(product['productName']),
                              subtitle: Text(
                                "Price: \$${(product['productPrice'] as num).toStringAsFixed(2)}\nQuantity: ${product['quantity']}",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    ),
  );
}

}
/// ------------------- END ORDER DETAILS SCREEN --------------------

/// ------------------- BEGIN CART SCREEN --------------------
  class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);
  
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Cart cart = Cart();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Function to adjust quantity.
  void _updateQuantity(Map<String, dynamic> product, int change) {
    setState(() {
      // Find the existing item.
      final existingItem = cart.items.firstWhere(
          (item) => item.product['productID'] == product['productID'],
          orElse: () => CartItem(product: product, quantity: 0));
      
      int newQuantity = existingItem.quantity + change;
      if (newQuantity <= 0) {
        cart.removeItem(product);
      } else {
        cart.updateQuantity(product, newQuantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: "Your Cart",
        scaffoldKey: _scaffoldKey,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          // Tapping the image or title navigates to the product detail page.
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemListingPage(product: item.product),
                              ),
                            );
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.0),
                              color: Colors.grey[300],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Semantics(
                                label: item.product['altText'] ?? 'Product image',
                                child: Image.asset(
                                  item.product['image'] ??
                                      'assets/product_placeholder.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          title: Text(item.product['productName']),
                          // Price display: show both original and sale price if applicable.
                          subtitle: item.product['onSale'] == 1
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Price: \$${(item.product['productPrice'] as num).toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      "Sale: \$${(item.product['salePrice'] as num).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  "Price: \$${(item.product['productPrice'] as num).toStringAsFixed(2)}",
                                ),
                          trailing: SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Minus button.
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    _updateQuantity(item.product, -1);
                                  },
                                ),
                                // Display quantity.
                                Text(item.quantity.toString(),
                                    style: const TextStyle(fontSize: 16)),
                                // Plus button.
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _updateQuantity(item.product, 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Total: \$${cart.total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Navigation buttons: Continue Shopping and Checkout.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Continue Shopping"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/checkout');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            foregroundColor: const Color(0xFF313131),
                          ),
                          child: const Text("Proceed to Checkout"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// CartItem and Cart classes. ---------------

class CartItem {
  final Map<String, dynamic> product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}

class Cart {
  // Singleton instance.
  static final Cart _instance = Cart._internal();
  factory Cart() => _instance;
  Cart._internal();

  final List<CartItem> items = [];

  // Add product to cart or increase quantity if it exists.
  void addItem(Map<String, dynamic> product) {
    final existingItem = items.firstWhere(
      (item) => item.product['productID'] == product['productID'],
      orElse: () => CartItem(product: product, quantity: 0),
    );
    if (existingItem.quantity > 0) {
      existingItem.quantity++;
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
  }

  // Remove a product from the cart.
  void removeItem(Map<String, dynamic> product) {
    items.removeWhere((item) => item.product['productID'] == product['productID']);
  }

  // Update quantity; if quantity becomes 0, remove the item.
  void updateQuantity(Map<String, dynamic> product, int quantity) {
    final existingItem = items.firstWhere(
      (item) => item.product['productID'] == product['productID'],
      orElse: () => CartItem(product: product, quantity: 0),
    );
    if (quantity <= 0) {
      removeItem(product);
    } else {
      existingItem.quantity = quantity;
    }
  }

  // Compute total price using salePrice if available.
  double get total {
    double sum = 0;
    for (var item in items) {
      final double unitPrice = (item.product['onSale'] == 1)
          ? (item.product['salePrice'] as num).toDouble()
          : (item.product['productPrice'] as num).toDouble();
      sum += unitPrice * item.quantity;
    }
    return sum;
  }

  // Clear the cart.
  void clear() {
    items.clear();
  }
}


/// -------------------- END CART SCREEN --------------------

/// ------------------- BEGIN CHECKOUT SCREEN --------------------
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final screenSize = MediaQuery.of(context).size;
    // Retrieve the current cart. Adjust this if you manage the Cart differently.
    final Cart cart = Cart();

    // Build the order summary items dynamically from the cart.
    List<Widget> _buildOrderSummaryItems() {
      return cart.items.map((item) {
        final String productName = item.product['productName'];
        final int quantity = item.quantity;
        // Determine the unit price: if on sale, use salePrice; otherwise, use productPrice.
        final double unitPrice = (item.product['onSale'] == 1)
            ? (item.product['salePrice'] as double)
            : (item.product['productPrice'] as double);
        // Calculate the extended price for the item.
        final double extendedPrice = unitPrice * quantity;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("$productName x $quantity")),
              Text("\$${extendedPrice.toStringAsFixed(2)}"),
            ],
          ),
        );
      }).toList();
    }

    // Recalculate the overall total using sale prices when applicable.
    final double computedTotal = cart.items.fold(0.0, (sum, item) {
      final double unitPrice = (item.product['onSale'] == 1)
          ? (item.product['salePrice'] as double)
          : (item.product['productPrice'] as double);
      return sum + (unitPrice * item.quantity);
    });

    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: "Checkout",
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const NavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Section.
              const Text(
                "Order Summary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ..._buildOrderSummaryItems(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "\$${computedTotal.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Payment Information Section.
              const Text(
                "Payment Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Card Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Expiry Date",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Shipping Information Section.
              const Text(
                "Shipping Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "City",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Postal Code",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              // Place Order Button.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle the order submission logic here.
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Place Order",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------- END CHECKOUT SCREEN --------------------

/// -------------------- BEGIN SEARCH RESULTS PAGE --------------------
class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({Key? key, required this.query}) : super(key: key);

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  Future<void> _search() async {
    final results = await _dbHelper.searchProducts(widget.query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final int crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
    final double childAspect = orientation == Orientation.portrait ? 0.7 : 0.7;
    return Scaffold(
      key: _scaffoldKey,
      appBar: CommonAppBar(
        title: 'Results for "${widget.query}"',
        scaffoldKey: _scaffoldKey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text("No results found."))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: childAspect,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final product = _results[index];
                      return _buildProductCard(context, product);
                    },
                  ),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Uniform image container with alt text.
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Semantics(
                  label: product['altText'] ?? 'Product image',
                  child: Image.asset(
                    product['image'] ?? 'assets/product_placeholder.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Title and Price section.
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 25,
                    child: Text(
                      product['productName'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  product['onSale'] == 1
                      ? Column(
                          children: [
                            Text(
                              "\$${(product['productPrice'] as num).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              "\$${(product['salePrice'] as num).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
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
/// -------------------- END SEARCH RESULTS PAGE --------------------

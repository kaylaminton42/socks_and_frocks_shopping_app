import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:social_signin_buttons_plugin/social_signin_buttons_plugin.dart';

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

class ProductsPage extends StatelessWidget {
final String title;

const ProductsPage({super.key, required this.title});

@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Scaffold(
    appBar: AppBar(
      backgroundColor: colorScheme.primary,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      ],
    ),
    drawer: const HomePage().buildLeftDrawer(context),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                hint: const Text('Sort By'),
                items: ['Price', 'Popularity', 'Newest']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) {},
              ),
              ElevatedButton(
onPressed: () {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('On Sale'),
              value: false,
              onChanged: (bool? value) {},
            ),
            CheckboxListTile(
              title: const Text('New Arrivals'),
              value: false,
              onChanged: (bool? value) {},
            ),
            DropdownButton<String>(
              hint: const Text('Category'),
              items: ['Tops', 'Bottoms', 'Outerwear', 'Accessories']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filter logic
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
},
child: const Text('Filter'),
)

            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image, size: 50)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class LoginPage extends StatelessWidget {
const LoginPage({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Login')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Email', hintText: 'yourname@email.com'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,  // Background color
            foregroundColor: Colors.white,  // Text color
            ),
            child: const Text('Login'),
          ),
          // Social sign in buttons
          // google
          // facebook
          //add some space
          // sign up button
          SignInButton(
            Buttons.Google,
            onPressed: () => _handleGoogleSignIn(),
            text: 'Sign in with Google',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          SignInButton(
            Buttons.Facebook,
            onPressed: () => _handleFacebookSignIn(),
            text: 'Sign in with Facebook',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ],
      ),
    ),
  );
}
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email', hintText: 'yourname@email.com'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,  // Background color
                foregroundColor: Colors.white,  // Text color
              ),
              child: const Text('Sign Up'),
            )

          ],
        ),
      ),
    );
  }
}
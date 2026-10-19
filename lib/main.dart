import 'package:flutter/material.dart';

void main() {
  runApp(const MeanGreenApp());
}

const Color appGreen = Color(0xFF007A3D);

class MeanGreenApp extends StatelessWidget {
  const MeanGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MeanGreen Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appGreen),
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: appGreen,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

// 1. WELCOME SCREEN

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 90, color: appGreen),
              const SizedBox(height: 20),
              const Text(
                'MeanGreen Marketplace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: appGreen,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Buy, sell, and discover items in your campus community.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(isSignUp: false),
                    ),
                  ),
                  child: const Text('Login'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthScreen(isSignUp: true),
                    ),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                ),
                child: const Text('Explore Demo Marketplace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. SIGN UP AND LOGIN SCREENS
// Demo only: authentication is not connected to Supabase yet.

class AuthScreen extends StatefulWidget {
  final bool isSignUp;

  const AuthScreen({super.key, required this.isSignUp});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Temporary demo login. Replace with real authentication later.
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isSignUp
              ? 'Demo account form completed.'
              : 'Demo login completed.',
        ),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSignUp ? 'Create Account' : 'Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.account_circle, size: 75, color: appGreen),
                const SizedBox(height: 20),
                Text(
                  widget.isSignUp
                      ? 'Join MeanGreen Marketplace'
                      : 'Welcome Back',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'University Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? 'Please wait...'
                          : widget.isSignUp
                              ? 'Create Account'
                              : 'Login',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AuthScreen(isSignUp: !widget.isSignUp),
                    ),
                  ),
                  child: Text(
                    widget.isSignUp
                        ? 'Already have an account? Login'
                        : 'Need an account? Sign Up',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SAMPLE LISTING DATA FOR THE DEMO

class MarketplaceListing {
  final String title;
  final String price;
  final String condition;
  final String location;
  final String description;
  final IconData icon;

  const MarketplaceListing({
    required this.title,
    required this.price,
    required this.condition,
    required this.location,
    required this.description,
    required this.icon,
  });
}

const sampleListings = [
  MarketplaceListing(
    title: 'Computer Science Textbook',
    price: '\$35',
    condition: 'Good',
    location: 'UNT Campus',
    description: 'A used textbook for computer science students.',
    icon: Icons.menu_book,
  ),
  MarketplaceListing(
    title: 'Laptop',
    price: '\$250',
    condition: 'Good',
    location: 'Denton, TX',
    description: 'A laptop suitable for schoolwork and everyday use.',
    icon: Icons.laptop,
  ),
  MarketplaceListing(
    title: 'UNT Hoodie',
    price: '\$20',
    condition: 'Like New',
    location: 'UNT Campus',
    description: 'A comfortable hoodie in good condition.',
    icon: Icons.checkroom,
  ),
  MarketplaceListing(
    title: 'Wireless Headphones',
    price: '\$30',
    condition: 'Good',
    location: 'Denton, TX',
    description: 'Wireless headphones for studying and listening to music.',
    icon: Icons.headphones,
  ),
];

// DEMO MARKETPLACE HOME

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeanGreen Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campus Marketplace',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Discover items from your campus community.'),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: sampleListings.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (context, index) {
                  final listing = sampleListings[index];

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailsScreen(listing: listing),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Icon(
                                  listing.icon,
                                  size: 60,
                                  color: appGreen,
                                ),
                              ),
                            ),
                            Text(
                              listing.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              listing.price,
                              style: const TextStyle(
                                color: appGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              listing.condition,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
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

// 3. LISTING DETAILS SCREEN

class ListingDetailsScreen extends StatelessWidget {
  final MarketplaceListing listing;

  const ListingDetailsScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: appGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(listing.icon, size: 100, color: appGreen),
          ),
          const SizedBox(height: 20),
          Text(
            listing.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            listing.price,
            style: const TextStyle(
              color: appGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 32),
          _detailRow(Icons.verified_outlined, 'Condition', listing.condition),
          _detailRow(Icons.location_on_outlined, 'Location', listing.location),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(listing.description),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Messaging will be available when connected to the team backend.',
                  ),
                ),
              ),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message Seller'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: appGreen),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// 4. PROFILE AND LOGOUT SCREEN

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: appGreen,
                child: Icon(Icons.person, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Marketplace User',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Demo account'),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'create_listing_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'search_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

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
  final _nameController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _loading = true;
  }
  );

  try {
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (widget.isSignUp) {
      final result = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': _nameController.text.trim(),
        },
      );

      if (!mounted) return;

      if (result.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created. Check your email to confirm your account.'),
          ),
        );
        return;
      }
    } else {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  } on AuthException catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
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
                if (widget.isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                   }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                ],
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
  final String? imageUrl;

  const MarketplaceListing({
    required this.title,
    required this.price,
    required this.condition,
    required this.location,
    required this.description,
    required this.icon,
    this.imageUrl,
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


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<MarketplaceListing> listings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final supabase = Supabase.instance.client;

      if (supabase.auth.currentUser == null) {
        throw Exception('Please log in to view marketplace listings.');
      }

      final data = await supabase
        .from('listings')
        .select()
        .eq('status', 'Available')
        .order('created_at', ascending: false);

      List<MarketplaceListing> loadedListings = [];

      for (final item in data) {
        String? photoUrl;

        final photos = await supabase
          .from('listing_images')
          .select('storage_path')
          .eq('listing_id', item['id'])
          .order('display_order')
          .limit(1);

        if (photos.isNotEmpty) {
          try {
            photoUrl = await supabase.storage
              .from('listing-images')
              .createSignedUrl(
                photos.first['storage_path'] as String,
                3600,
              );
          } catch (error) {
            debugPrint('Could not load listing image: $error');
          }
        }

        final isFree = item['is_free'] == true;
        final price = isFree
          ? 'Free'
          : '\$${(item['price'] as num).toStringAsFixed(2)}';

        loadedListings.add(
          MarketplaceListing(
            title: item['title'] as String,
            price: price,
            condition: item['condition'] as String,
            location: item['location'] as String,
            description: item['description'] as String,
            icon: Icons.shopping_bag_outlined,
            imageUrl: photoUrl,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        listings = loadedListings;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> openCreateListing() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateListingScreen(),
      ),
    );

    if (result == true) {
      loadListings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeanGreen Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadListings,
          ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications.'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Discover items from your campus community.',
            ),

            const SizedBox(height: 16),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: loadListings,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : listings.isEmpty
                          ? const Center(
                              child: Text(
                                'No listings available yet.',
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, size) {
                                int columns = 2;

                                if (size.maxWidth > 900) {
                                  columns = 4;
                                } else if (size.maxWidth > 600) {
                                  columns = 3;
                                }

                                return GridView.builder(
                                  itemCount: listings.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.76,
                                  ),
                                  itemBuilder: (context, index) {
                                    final listing = listings[index];

                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ListingDetailsScreen(
                                                listing: listing,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: listing.imageUrl != null
                                                      ? Image.network(
                                                          listing.imageUrl!,
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return const Icon(
                                                              Icons.image_not_supported_outlined,
                                                              size: 50,
                                                              color: appGreen,
                                                            );
                                                          },
                                                        )
                                                      : const Icon(
                                                          Icons.shopping_bag_outlined,
                                                          size: 60,
                                                          color: appGreen,
                                                        ),
                                                ),
                                              ),

                                              const SizedBox(height: 8),

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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchScreen(),
            ),
            );
          } else if (index == 2) {
            openCreateListing();
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
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
            child: listing.imageUrl != null
    ?         Image.network(
                listing.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    listing.icon,
                    size: 100,
                    color: appGreen,
                  );
                },
              )
    : Icon(
      listing.icon,
      size: 100,
      color: appGreen,
    ),
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


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();

  String userName = 'Marketplace User';
  String userEmail = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        userName = 'Guest User';
        userEmail = 'Not logged in';
        isLoading = false;
      });
      return;
    }

    String name = (user.userMetadata?['full_name'] ?? '').toString();

    try {
      final profile = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();

      final savedName = (profile?['display_name'] ?? '').toString();

      if (savedName.trim().isNotEmpty) {
        name = savedName;
      }
    } catch (error) {
      debugPrint('Could not load profile: $error');
    }

    if (!mounted) return;

    setState(() {
      userName = name.trim().isEmpty ? 'Marketplace User' : name;
      userEmail = user.email ?? '';
      nameController.text = name.trim();
      isLoading = false;
    }
    );
  }

  Future<void> saveName() async {
    final user = supabase.auth.currentUser;
    final name = nameController.text.trim();

    if (user == null || name.isEmpty) {
      return;
    }

    try {
      await supabase
        .from('profiles')
        .update({'display_name': name})
        .eq('id', user.id);
 
      await supabase.auth.updateUser(
        UserAttributes(
          data: {'full_name': name},
        ),
      );

      if (!mounted) return;

      setState(() {
        userName = name;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $error')),
      );
    }
  }

  Future<void> editName() async {
    nameController.text = userName == 'Marketplace User' ? '' : userName;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                saveName();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF007A3D),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 55,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Account Information'),
                    subtitle: Text(userEmail),
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    subtitle: const Text('Edit your profile information'),
                    onTap: editName,
                    enabled: supabase.auth.currentUser != null,
                    trailing: const Icon(Icons.chevron_right),
                  ),

                  ListTile(
                    leading: const Icon(Icons.contact_support_outlined),
                    title: const Text('Contact Us'),
                    subtitle: const Text('Questions or need help?'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Contact Us'),
                            content: const Text(
                              'Have a question, experiencing an issue, or need assistance with MeanGreen Marketplace?\n\n'
                              'Please contact us at abir3210rh@icloud.com for any questions, concerns, or technical problems. '
                              'We will do our best to assist you.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


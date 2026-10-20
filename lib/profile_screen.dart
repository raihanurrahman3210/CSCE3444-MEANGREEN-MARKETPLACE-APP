import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_constants.dart';
import 'marketplace_listing.dart';
import 'listing_details_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String userName = 'Marketplace User';
  String userEmail = '';
  String errorMessage = '';
  bool isLoading = true;

  List<Map<String, dynamic>> myListings = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view your profile.';
        myListings = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String name = (user.userMetadata?['full_name'] ?? '').toString();

      final profile = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      final savedName = (profile?['display_name'] ?? '').toString();

      if (savedName.trim().isNotEmpty) {
        name = savedName;
      }

      final data = await supabase
          .from('listings')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      final posts = <Map<String, dynamic>>[];

      for (final item in data) {
        final post = Map<String, dynamic>.from(item);
        String? imageUrl;

        try {
          final images = await supabase
              .from('listing_images')
              .select('storage_path')
              .eq('listing_id', item['id'])
              .order('display_order')
              .limit(1);

          if (images.isNotEmpty) {
            imageUrl = await supabase.storage
                .from('listing-images')
                .createSignedUrl(images.first['storage_path'] as String, 3600);
          }
        } catch (error) {
          debugPrint('Could not load posting photo: $error');
        }

        post['image_url'] = imageUrl;
        posts.add(post);
      }

      if (!mounted) return;

      setState(() {
        userName = name.trim().isEmpty ? 'Marketplace User' : name;
        userEmail = user.email ?? '';
        myListings = posts;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        userEmail = user.email ?? '';
        isLoading = false;
        errorMessage = 'Could not load profile: $error';
      });
    }
  }

  void openListing(Map<String, dynamic> item) {
    final isFree = item['is_free'] == true;
    final price = (item['price'] as num).toDouble();

    final listing = MarketplaceListing(
      id: item['id'] as String,
      sellerId: item['seller_id'] as String,
      title: item['title'].toString(),
      price: isFree ? 'Free' : '\$${price.toStringAsFixed(2)}',
      condition: item['condition'].toString(),
      location: item['location'].toString(),
      description: item['description'].toString(),
      icon: Icons.shopping_bag_outlined,
      imageUrl: item['image_url'] as String?,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingDetailsScreen(listing: listing)),
    );
  }

  Widget buildPosting(Map<String, dynamic> item) {
    final isFree = item['is_free'] == true;
    final price = (item['price'] as num).toDouble();
    final status = (item['status'] ?? 'Available').toString();
    final imageUrl = item['image_url'] as String?;

    Color statusColor = Colors.green;

    if (status == 'Sold') {
      statusColor = Colors.red;
    } else if (status == 'Pending') {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openListing(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 85,
                height: 85,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_outlined,
                            color: appGreen,
                          );
                        },
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: appGreen,
                        size: 45,
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isFree ? 'Free' : '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: appGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item['location'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );

              if (mounted) {
                loadProfile();
              }
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: loadProfile,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 30),

                  const Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF007A3D),
                      child: Icon(Icons.person, color: Colors.white, size: 55),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      userEmail,
                      style: const TextStyle(fontSize: 15, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Postings (${myListings.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (myListings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'You have not posted any listings yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...myListings.map(buildPosting),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

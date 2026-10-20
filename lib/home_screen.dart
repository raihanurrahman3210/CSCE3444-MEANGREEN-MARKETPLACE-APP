import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_constants.dart';
import 'marketplace_listing.dart';
import 'create_listing_screen.dart';
import 'search_screen.dart';
import 'listing_details_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

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
                .createSignedUrl(photos.first['storage_path'] as String, 3600);
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
            id: item['id'] as String,
            sellerId: item['seller_id'] as String,
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
      MaterialPageRoute(builder: (_) => const CreateListingScreen()),
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
                const SnackBar(content: Text('No new notifications.')),
              );
            },
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text('Discover items from your campus community.'),

            const SizedBox(height: 16),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(errorMessage, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: loadListings,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    )
                  : listings.isEmpty
                  ? const Center(child: Text('No listings available yet.'))
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
                                      builder: (_) => ListingDetailsScreen(
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
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Icon(
                                                          Icons
                                                              .image_not_supported_outlined,
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
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          } else if (index == 2) {
            openCreateListing();
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
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

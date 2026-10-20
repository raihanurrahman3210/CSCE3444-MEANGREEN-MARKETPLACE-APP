
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();

  List<MarketplaceListing> listings = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    searchListings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchListings() async {
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentUser == null) {
      setState(() {
        errorMessage = 'Please log in to search marketplace listings.';
        listings = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final searchText = searchController.text.trim().toLowerCase();

      final data = await supabase
        .from('listings')
        .select()
        .eq('status', 'Available')
        .order('created_at', ascending: false);

      List<MarketplaceListing> results = [];

      for (final item in data) {
        final title = (item['title'] ?? '').toString();
        final description = (item['description'] ?? '').toString();
        final courseCode = (item['course_code'] ?? '').toString();

        final searchableText =
          '$title $description $courseCode'.toLowerCase();

        final normalizedCourse =
            courseCode.toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
        final normalizedSearch =
            searchText.replaceAll(RegExp(r'[\s-]'), '');

        bool matches = searchText.isEmpty ||
            searchableText.contains(searchText) ||
            (normalizedSearch.isNotEmpty &&
            normalizedCourse.contains(normalizedSearch));

        if (!matches) {
          continue;
        }

        String? imageUrl;

        final images = await supabase
          .from('listing_images')
          .select('storage_path')
          .eq('listing_id', item['id'])
          .order('display_order')
          .limit(1);

        if (images.isNotEmpty) {
          try {
            imageUrl = await supabase.storage
              .from('listing-images')
              .createSignedUrl(
                images.first['storage_path'] as String,
                3600,
                );
          } catch (error) {
            debugPrint('Image loading failed: $error');
          }
        }

        final isFree = item['is_free'] == true;
        final priceValue = (item['price'] as num).toDouble();

        results.add(
          MarketplaceListing(
            title: title,
            description: description,
            condition: (item['condition'] ?? '').toString(),
            location: (item['location'] ?? '').toString(),
            price: isFree ? 'Free' : '\$${priceValue.toStringAsFixed(2)}',
            icon: Icons.shopping_bag_outlined,
            imageUrl: imageUrl,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        listings = results;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        listings = [];
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Widget buildListingCard(MarketplaceListing listing) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailsScreen(listing: listing),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: listing.imageUrl != null
                      ? Image.network(
                          listing.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
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
                style: const TextStyle(color: Colors.grey),
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
        title: const Text('Search Marketplace'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                searchListings();
              },
              decoration: InputDecoration(
                hintText: 'Search items or course codes',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: searchListings,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Search by product name, description, or UNT course code.',
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
                                onPressed: searchListings,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : listings.isEmpty
                          ? const Center(
                              child: Text('No matching listings found.'),
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
                                    return buildListingCard(listings[index]);
                                  },
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

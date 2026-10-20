import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_constants.dart';
import 'marketplace_listing.dart';
import 'chat_screen.dart';

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
                ? Image.network(
                    listing.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(listing.icon, size: 100, color: appGreen);
                    },
                  )
                : Icon(listing.icon, size: 100, color: appGreen),
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
              onPressed: () async {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in first.')),
                  );
                  return;
                }

                if (listing.id == null || listing.sellerId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seller information is unavailable.'),
                    ),
                  );
                  return;
                }

                if (user.id == listing.sellerId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You cannot message yourself.'),
                    ),
                  );
                  return;
                }

                try {
                  final existing = await supabase
                      .from('conversations')
                      .select('id')
                      .eq('listing_id', listing.id!)
                      .eq('buyer_id', user.id)
                      .eq('seller_id', listing.sellerId!)
                      .maybeSingle();

                  String conversationId;

                  if (existing != null) {
                    conversationId = existing['id'] as String;
                  } else {
                    try {
                      final created = await supabase
                          .from('conversations')
                          .insert({
                            'listing_id': listing.id!,
                            'buyer_id': user.id,
                            'seller_id': listing.sellerId!,
                          })
                          .select('id')
                          .single();

                      conversationId = created['id'] as String;
                    } on PostgrestException catch (error) {
                      if (error.code != '23505') rethrow;

                      final found = await supabase
                          .from('conversations')
                          .select('id')
                          .eq('listing_id', listing.id!)
                          .eq('buyer_id', user.id)
                          .eq('seller_id', listing.sellerId!)
                          .single();

                      conversationId = found['id'] as String;
                    }
                  }

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        conversationId: conversationId,
                        conversationTitle: 'Seller',
                        listingTitle: listing.title,
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open conversation: $error'),
                    ),
                  );
                }
              },

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

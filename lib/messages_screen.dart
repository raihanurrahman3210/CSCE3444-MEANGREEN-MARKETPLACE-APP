import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_constants.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>> conversations = [];

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view messages.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await supabase
          .from('conversations')
          .select()
          .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final results = <Map<String, dynamic>>[];

      for (final conversation in data) {
        final item = Map<String, dynamic>.from(conversation);

        final listing = await supabase
            .from('listings')
            .select('title')
            .eq('id', conversation['listing_id'])
            .maybeSingle();

        final latestMessages = await supabase
            .from('messages')
            .select('content, created_at')
            .eq('conversation_id', conversation['id'])
            .order('created_at', ascending: false)
            .limit(1);

        final isBuyer = conversation['buyer_id'] == user.id;

        item['listing_title'] =
            listing?['title']?.toString() ?? 'Marketplace Listing';

        item['person_name'] = isBuyer ? 'Seller' : 'Buyer';

        item['last_message'] = latestMessages.isEmpty
            ? 'Start a conversation'
            : latestMessages.first['content'].toString();

        results.add(item);
      }

      if (!mounted) return;

      setState(() {
        conversations = results;
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

  Future<void> openChat(Map<String, dynamic> conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'] as String,
          conversationTitle: conversation['person_name'].toString(),
          listingTitle: conversation['listing_title'].toString(),
        ),
      ),
    );

    if (mounted) loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadConversations,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(errorMessage, textAlign: TextAlign.center),
                  ),
                  ElevatedButton(
                    onPressed: loadConversations,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadConversations,
              child: conversations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: appGreen,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Message a seller from a listing to start a conversation.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE1F3E8),
                            child: Icon(Icons.person, color: appGreen),
                          ),
                          title: Text(
                            conversation['person_name'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conversation['listing_title'].toString(),
                                style: const TextStyle(
                                  color: appGreen,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                conversation['last_message'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openChat(conversation),
                        );
                      },
                    ),
            ),
    );
  }
}

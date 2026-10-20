import 'package:flutter/material.dart';

class MarketplaceListing {
  final String title;
  final String price;
  final String condition;
  final String location;
  final String description;
  final IconData icon;
  final String? imageUrl;
  final String? id;
  final String? sellerId;

  const MarketplaceListing({
    required this.title,
    required this.price,
    required this.condition,
    required this.location,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.id,
    this.sellerId,
  });
}

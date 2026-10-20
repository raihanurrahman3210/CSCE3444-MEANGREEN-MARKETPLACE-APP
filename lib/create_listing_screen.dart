import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() {
    return _CreateListingScreenState();
  }
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final courseController = TextEditingController();
  final locationController = TextEditingController();

  String selectedCategory = 'Textbooks';
  String selectedCondition = 'Good';
  bool isFree = false;

  Uint8List? selectedPhoto;
  final ImagePicker imagePicker = ImagePicker();
  XFile? selectedFile;

  Future<void> choosePhoto() async {
    final photo = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (photo == null) return;

    final imageData = await photo.readAsBytes();
    final fileName = photo.name.toLowerCase();

    if (!fileName.endsWith('.jpg') &&
        !fileName.endsWith('.jpeg') &&
        !fileName.endsWith('.png') &&
        !fileName.endsWith('.webp')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a JPG, PNG, or WebP image'),
        ),
      );
      return;
    }

    if (imageData.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo must be smaller than 5 MB')),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      selectedPhoto = imageData;
      selectedFile = photo;
    });
  }

  Future<void> createListing() async {
    if (!formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before creating a listing'),
        ),
      );
      return;
    }

    try {
      final category = await supabase
          .from('categories')
          .select('id')
          .eq('name', selectedCategory)
          .single();

      final price = isFree ? 0.0 : double.parse(priceController.text.trim());

      final listing = await supabase
          .from('listings')
          .insert({
            'seller_id': user.id,
            'category_id': category['id'],
            'title': titleController.text.trim(),
            'description': descriptionController.text.trim(),
            'price': price,
            'is_free': isFree,
            'condition': selectedCondition,
            'course_code': courseController.text.trim().isEmpty
                ? null
                : courseController.text.trim(),
            'location': locationController.text.trim(),
          })
          .select('id')
          .single();

      final listingId = listing['id'] as String;

      if (selectedPhoto != null && selectedFile != null) {
        final fileName = selectedFile!.name.toLowerCase();
        final extension = fileName.split('.').last;

        final contentType = extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

        final path =
            '${user.id}/$listingId/${DateTime.now().millisecondsSinceEpoch}.$extension';

        await supabase.storage
            .from('listing-images')
            .uploadBinary(
              path,
              selectedPhoto!,
              fileOptions: FileOptions(contentType: contentType),
            );

        await supabase.from('listing_images').insert({
          'listing_id': listingId,
          'storage_path': path,
          'display_order': 0,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!')),
      );

      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: ${error.message}')),
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Listing saved, but photo upload failed: ${error.message}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    courseController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Listing')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),

            if (selectedPhoto != null)
              Image.memory(selectedPhoto!, height: 180, fit: BoxFit.contain)
            else
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 80,
                color: Color(0xFF007A3D),
              ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: choosePhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose Photo'),
            ),

            const SizedBox(height: 25),

            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item title';
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items:
                  [
                    'Textbooks',
                    'Furniture',
                    'Electronics',
                    'Clothing',
                    'Appliances',
                    'School Supplies',
                    'Dorm Items',
                    'Other',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Item Condition',
                border: OutlineInputBorder(),
              ),
              items: ['New', 'Like New', 'Good', 'Fair', 'Poor'].map((
                condition,
              ) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCondition = value;
                  });
                }
              },
            ),

            const SizedBox(height: 15),

            SwitchListTile(
              title: const Text('Free / Giveaway'),
              value: isFree,
              onChanged: (value) {
                setState(() {
                  isFree = value;
                });
              },
            ),

            if (!isFree)
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (isFree) {
                    return null;
                  }

                  double? price = double.tryParse(value ?? '');

                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }

                  return null;
                },
              ),

            const SizedBox(height: 15),

            TextFormField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course Code (Optional)',
                hintText: 'Example: CSCE 3444',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                hintText: 'Example: UNT Union',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),

            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: createListing,
                child: const Text('Create Listing'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

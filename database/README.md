# MeanGreen Marketplace Database

This folder contains PostgreSQL scripts for our Supabase database.

Our Flutter app uses Supabase for authentication, database access,
and image storage.

## Folder Structure

- migrations/: Table definitions, constraints, and access policies.
- seeds/: Sample data for development.
- tests/: Buyer and seller permission tests.

## Existing Shared Project

The initial scripts have already been applied to our shared Supabase
project. Do not rerun the table-creation scripts there.

Cloning or pulling this repository downloads the SQL files.
It does not execute them or change the Supabase database.

## Setting Up a New Supabase Project

Run these scripts in the Supabase SQL Editor in this order:

1. migrations/01_create_categories.sql
2. migrations/02_create_profiles.sql
3. migrations/03_create_listings.sql
4. migrations/04_create_listing_images.sql

Next, create a Storage bucket with these settings:

- Name: listing-images
- Public: Off (private)
- Maximum file size: 5 MB
- Allowed MIME types: image/jpeg, image/png, image/webp

Then run:

5. migrations/05_listing_image_storage_policies.sql

These numbered scripts are applied manually. This folder is not
configured for automatic deployment through the Supabase CLI.

## Database Tables

- profiles: Student display names and profile image references.
  Each profile links to an account in Supabase Auth.
- categories: Marketplace item categories.
- listings: Item details, seller, category, price, and status.
- listing_images: Photo paths and display order for each listing.

Supabase Auth manages login credentials.
The profiles table does not store passwords.

## Sample Data

Before running seeds/06_sample_data.sql, create these test accounts
under Authentication > Users:

- seller@example.com
- buyer@example.com

Use private test passwords and auto-confirm these development accounts.
Do not send invitations to these placeholder addresses.

Run seeds/06_sample_data.sql to create their profiles and a sample
textbook listing.

Normal app sign-up still needs a profile-creation step.
The current schema does not automatically create profiles on sign-up.

## Access Rules

- Signed-in users can read categories, profiles, listings, and photos.
- Users can create and edit only their own profiles.
- Sellers can create, edit, and delete only their own listings.
- Sellers can upload photos only for their existing listings.
- Users can delete photos from their own storage folder.

Authentication alone does not verify current UNT enrollment.
Student eligibility verification remains a separate task.

## Listing Photos

Store files in the listing-images bucket using this path format:

seller_id/listing_id/unique_filename.jpg

The app should:

1. Create the listing and obtain its ID.
2. Upload the photo with upsert set to false.
3. Save the path in listing_images.

The bucket is private. Use authenticated downloads or temporary
signed URLs to display photos.

Deleting a database image record does not delete the stored file.
File cleanup must use the Supabase Storage API.

## Permission Tests

Run tests in the SQL Editor as the project administrator.
The scripts temporarily simulate an authenticated user and end
with ROLLBACK so test changes are not saved.

Expected results:

- Buyer: Can view the sample listing but updates zero rows.
- Seller: Updates one row; the temporary test price is 30.00.

The test scripts automatically find the sample listing using the
seller's email and listing title. No manual UUID replacement is needed.
Create the test accounts and run the sample-data script before testing.

These tests check database permissions only.
Flutter login, API access, and photo uploads still require testing.

## Credentials

Never commit passwords, secret/service-role keys, access tokens,
or database connection strings containing passwords.

The Flutter app must use a publishable key, not a secret/service-role key.
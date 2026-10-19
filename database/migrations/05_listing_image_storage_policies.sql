BEGIN;

-- Signed-in students can view listing photos.
CREATE POLICY "Authenticated users can read listing photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'listing-images'
);

-- Sellers can upload photos only for their own listings.
CREATE POLICY "Sellers can upload their listing photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'listing-images'

    AND split_part(name, '/', 1) = (SELECT auth.uid())::text

    AND array_length(string_to_array(name, '/'), 1) = 3

    AND split_part(name, '/', 3) <> ''

    AND EXISTS (
        SELECT 1
        FROM public.listings AS listing
        WHERE listing.id::text = split_part(name, '/', 2)
          AND listing.seller_id = (SELECT auth.uid())
    )
);

-- Sellers can remove files from their own folder,
-- including leftover files after a listing is deleted.
CREATE POLICY "Sellers can delete their listing photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'listing-images'
    AND split_part(name, '/', 1) = (SELECT auth.uid())::text
);

COMMIT;
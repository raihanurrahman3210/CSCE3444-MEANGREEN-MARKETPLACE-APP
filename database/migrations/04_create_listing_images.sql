BEGIN;

CREATE TABLE public.listing_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    listing_id UUID NOT NULL
        REFERENCES public.listings(id) ON DELETE CASCADE,

    storage_path TEXT NOT NULL UNIQUE,

    display_order INTEGER NOT NULL DEFAULT 0
        CHECK (display_order >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Paths must follow: seller_id/listing_id/filename
    CONSTRAINT image_path_matches_listing CHECK (
        split_part(storage_path, '/', 2) = listing_id::text
        AND split_part(storage_path, '/', 3) <> ''
        AND array_length(string_to_array(storage_path, '/'), 1) = 3
    )
);

CREATE INDEX listing_images_listing_id_idx
ON public.listing_images (listing_id);

ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read listing images"
ON public.listing_images
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Sellers can add images to their listings"
ON public.listing_images
FOR INSERT TO authenticated
WITH CHECK (
    split_part(storage_path, '/', 1) = (SELECT auth.uid())::text
    AND EXISTS (
        SELECT 1
        FROM public.listings AS listing
        WHERE listing.id = listing_images.listing_id
          AND listing.seller_id = (SELECT auth.uid())
    )
);

CREATE POLICY "Sellers can reorder their listing images"
ON public.listing_images
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.listings AS listing
        WHERE listing.id = listing_images.listing_id
          AND listing.seller_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.listings AS listing
        WHERE listing.id = listing_images.listing_id
          AND listing.seller_id = (SELECT auth.uid())
    )
);

CREATE POLICY "Sellers can remove their listing images"
ON public.listing_images
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.listings AS listing
        WHERE listing.id = listing_images.listing_id
          AND listing.seller_id = (SELECT auth.uid())
    )
);

REVOKE ALL ON TABLE public.listing_images
FROM anon, authenticated;

GRANT SELECT, DELETE ON TABLE public.listing_images
TO authenticated;

GRANT INSERT (listing_id, storage_path, display_order)
ON public.listing_images TO authenticated;

GRANT UPDATE (display_order)
ON public.listing_images TO authenticated;

COMMIT;
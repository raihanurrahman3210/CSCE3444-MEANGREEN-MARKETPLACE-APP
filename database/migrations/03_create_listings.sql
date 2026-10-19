BEGIN;

CREATE TABLE public.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    seller_id UUID NOT NULL DEFAULT auth.uid()
        REFERENCES public.profiles(id) ON DELETE CASCADE,

    category_id BIGINT NOT NULL
        REFERENCES public.categories(id),

    title TEXT NOT NULL
        CHECK (length(trim(title)) BETWEEN 1 AND 150),

    description TEXT NOT NULL
        CHECK (length(trim(description)) BETWEEN 1 AND 5000),

    price NUMERIC(10, 2) NOT NULL
        CHECK (price >= 0 AND price <> 'NaN'::numeric),

    is_free BOOLEAN NOT NULL DEFAULT false,

    condition TEXT NOT NULL
        CHECK (length(trim(condition)) BETWEEN 1 AND 50),

    course_code TEXT,

    location TEXT NOT NULL
        CHECK (length(trim(location)) BETWEEN 1 AND 200),

    status TEXT NOT NULL DEFAULT 'Available'
        CHECK (status IN ('Available', 'Pending', 'Sold')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT consistent_free_price CHECK (
        (is_free = true AND price = 0)
        OR
        (is_free = false AND price > 0)
    )
);

-- Help retrieve listings by seller and category.
CREATE INDEX listings_seller_id_idx
ON public.listings (seller_id);

CREATE INDEX listings_category_id_idx
ON public.listings (category_id);

-- Automatically record when a listing is edited.
CREATE FUNCTION public.set_listing_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER listing_updated_at
BEFORE UPDATE ON public.listings
FOR EACH ROW
EXECUTE FUNCTION public.set_listing_updated_at();

ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read listings"
ON public.listings
FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Users can create their own listings"
ON public.listings
FOR INSERT TO authenticated
WITH CHECK ((SELECT auth.uid()) = seller_id);

CREATE POLICY "Users can update their own listings"
ON public.listings
FOR UPDATE TO authenticated
USING ((SELECT auth.uid()) = seller_id)
WITH CHECK ((SELECT auth.uid()) = seller_id);

CREATE POLICY "Users can delete their own listings"
ON public.listings
FOR DELETE TO authenticated
USING ((SELECT auth.uid()) = seller_id);

-- Allow only the required operations and editable fields.
REVOKE ALL ON TABLE public.listings FROM anon, authenticated;

GRANT SELECT, DELETE
ON TABLE public.listings TO authenticated;

GRANT INSERT (
    seller_id, category_id, title, description, price,
    is_free, condition, course_code, location
)
ON public.listings TO authenticated;

GRANT UPDATE (
    category_id, title, description, price,
    is_free, condition, course_code, location, status
)
ON public.listings TO authenticated;

COMMIT;
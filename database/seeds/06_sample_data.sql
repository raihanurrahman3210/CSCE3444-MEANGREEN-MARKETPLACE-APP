BEGIN;

-- Check that both test accounts exist.
DO $$
BEGIN
    IF (
        SELECT count(*)
        FROM auth.users
        WHERE email IN ('seller@example.com', 'buyer@example.com')
    ) <> 2 THEN
        RAISE EXCEPTION
            'Create seller@example.com and buyer@example.com in Auth first.';
    END IF;
END;
$$;

-- Create profiles using the actual authentication user IDs.
INSERT INTO public.profiles (id, display_name)
SELECT
    id,
    CASE email
        WHEN 'seller@example.com' THEN 'Test Seller'
        WHEN 'buyer@example.com' THEN 'Test Buyer'
    END
FROM auth.users
WHERE email IN ('seller@example.com', 'buyer@example.com')
ON CONFLICT (id) DO NOTHING;

-- Create one sample listing.
INSERT INTO public.listings (
    seller_id,
    category_id,
    title,
    description,
    price,
    is_free,
    condition,
    course_code,
    location
)
SELECT
    student.id,
    category.id,
    'CSCE 3444 Textbook - Test Listing',
    'Sample textbook listing for testing the marketplace.',
    25.00,
    false,
    'Good',
    'CSCE 3444',
    'Discovery Park'
FROM auth.users AS student
CROSS JOIN public.categories AS category
WHERE student.email = 'seller@example.com'
  AND category.name = 'Textbooks'
  AND NOT EXISTS (
      SELECT 1
      FROM public.listings AS existing
      WHERE existing.seller_id = student.id
        AND existing.title = 'CSCE 3444 Textbook - Test Listing'
  );

COMMIT;
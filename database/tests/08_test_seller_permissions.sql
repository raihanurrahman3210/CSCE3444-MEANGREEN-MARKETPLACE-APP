BEGIN;

-- Find the seller and their sample listing.
DO $$
DECLARE
  seller_user_id UUID;
  sample_listing_id UUID;
BEGIN
  SELECT id INTO STRICT seller_user_id
  FROM auth.users
  WHERE email = 'seller@example.com';

  SELECT id INTO STRICT sample_listing_id
  FROM public.listings
  WHERE seller_id = seller_user_id
    AND title = 'CSCE 3444 Textbook - Test Listing';

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', seller_user_id::text,
      'role', 'authenticated'
    )::text,
    true
  );

  PERFORM set_config(
    'test.listing_id',
    sample_listing_id::text,
    true
  );
END;
$$;

-- Apply the permissions of a signed-in app user.
SET LOCAL ROLE authenticated;

WITH attempted_update AS (
  UPDATE public.listings
  SET price = 30.00
  WHERE id = current_setting('test.listing_id')::uuid
  RETURNING id, price
)
SELECT
  current_user AS database_role,
  auth.uid() AS simulated_seller_id,
  count(*) AS rows_changed,
  max(price) AS test_price
FROM attempted_update;

-- Restore the original price by discarding test changes.
ROLLBACK;
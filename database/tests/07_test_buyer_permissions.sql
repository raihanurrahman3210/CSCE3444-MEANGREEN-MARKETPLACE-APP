BEGIN;

-- Find the buyer and sample listing before switching roles.
DO $$
DECLARE
  buyer_id UUID;
  sample_listing_id UUID;
BEGIN
  SELECT id INTO STRICT buyer_id
  FROM auth.users
  WHERE email = 'buyer@example.com';

  SELECT listing.id INTO STRICT sample_listing_id
  FROM public.listings AS listing
  JOIN auth.users AS seller
    ON seller.id = listing.seller_id
  WHERE seller.email = 'seller@example.com'
    AND listing.title = 'CSCE 3444 Textbook - Test Listing';

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', buyer_id::text,
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
  SET price = 1.00
  WHERE id = current_setting('test.listing_id')::uuid
  RETURNING id
)
SELECT
  current_user AS database_role,
  auth.uid() AS simulated_buyer_id,
  (
    SELECT count(*)
    FROM public.listings
    WHERE id = current_setting('test.listing_id')::uuid
  ) AS visible_listings,
  (SELECT count(*) FROM attempted_update) AS rows_changed;

-- Discard any test changes.
ROLLBACK;
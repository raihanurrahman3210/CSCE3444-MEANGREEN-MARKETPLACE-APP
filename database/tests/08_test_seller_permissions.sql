BEGIN;

-- Simulate the test seller.
SELECT set_config(
    'request.jwt.claims',
    json_build_object(
        'sub', id::text,
        'role', 'authenticated'
    )::text,
    true
)
FROM auth.users
WHERE email = 'seller@example.com';

SET LOCAL ROLE authenticated;

-- Try changing the seller's own listing.
WITH attempted_update AS (
    UPDATE public.listings
    SET price = 30.00
    WHERE id = 'bd18ae53-7716-4125-8486-28c072d099fd'
    RETURNING id, price
)
SELECT
    current_user AS database_role,
    auth.uid() AS simulated_seller_id,
    count(*) AS rows_changed,
    max(price) AS test_price
FROM attempted_update;

-- Undo the test change, keeping the original $25 price.
ROLLBACK;
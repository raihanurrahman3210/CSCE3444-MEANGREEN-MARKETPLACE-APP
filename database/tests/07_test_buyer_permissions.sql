BEGIN;

-- Simulate the test buyer's identity for this transaction.
SELECT set_config(
    'request.jwt.claims',
    json_build_object(
        'sub', id::text,
        'role', 'authenticated'
    )::text,
    true
)
FROM auth.users
WHERE email = 'buyer@example.com';

-- Use the same database role as a signed-in app user.
SET LOCAL ROLE authenticated;

-- Try to change the seller's listing as the buyer.
WITH attempted_update AS (
    UPDATE public.listings
    SET price = 1.00
    WHERE id = 'bd18ae53-7716-4125-8486-28c072d099fd'
    RETURNING id
)
SELECT
    current_user AS database_role,
    auth.uid() AS simulated_buyer_id,

    (
        SELECT count(*)
        FROM public.listings
        WHERE id = 'bd18ae53-7716-4125-8486-28c072d099fd'
    ) AS visible_listings,

    (
        SELECT count(*)
        FROM attempted_update
    ) AS rows_changed;

-- Undo any test changes and restore the previous role.
ROLLBACK;
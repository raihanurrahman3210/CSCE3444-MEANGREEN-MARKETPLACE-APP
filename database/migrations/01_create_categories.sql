BEGIN;

CREATE TABLE public.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    CONSTRAINT category_name_not_empty
        CHECK (length(trim(name)) > 0)
);

-- Enable database access rules.
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Signed-in students can read the categories.
CREATE POLICY "Authenticated users can read categories"
ON public.categories
FOR SELECT
TO authenticated
USING (true);

-- The app can read categories but cannot change them.
REVOKE ALL ON TABLE public.categories FROM anon, authenticated;
GRANT SELECT ON TABLE public.categories TO authenticated;

INSERT INTO public.categories (name)
VALUES
    ('Textbooks'),
    ('Furniture'),
    ('Electronics'),
    ('Clothing'),
    ('Appliances'),
    ('School Supplies'),
    ('Dorm Items'),
    ('Other');

COMMIT;
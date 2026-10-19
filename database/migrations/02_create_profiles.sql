BEGIN;

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id) ON DELETE CASCADE,

    display_name TEXT NOT NULL
        CHECK (length(trim(display_name)) BETWEEN 1 AND 80),

    avatar_path TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Signed-in users can view marketplace profiles.
CREATE POLICY "Authenticated users can read profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (true);

-- Users can create only their own profile.
CREATE POLICY "Users can create their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = id);

-- Users can update only their own profile.
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = id)
WITH CHECK ((SELECT auth.uid()) = id);

-- Limit which operations and columns the app can use.
REVOKE ALL ON TABLE public.profiles FROM anon, authenticated;

GRANT SELECT ON TABLE public.profiles TO authenticated;

GRANT INSERT (id, display_name, avatar_path)
ON public.profiles TO authenticated;

GRANT UPDATE (display_name, avatar_path)
ON public.profiles TO authenticated;

COMMIT;
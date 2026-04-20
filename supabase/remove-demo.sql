-- =====================================================
-- SIMPLIFY TENANT - REMOVE "DEMO" BRANDING
-- =====================================================
-- This removes the "demo" branding from your system
-- Run this in Supabase SQL Editor
-- =====================================================

-- Option 1: Change slug to your business name
-- UPDATE tenants 
-- SET slug = 'yourstore', name = 'Your Store Name'
-- WHERE id = '00000000-0000-0000-0000-000000000001';

-- Option 2: Use generic 'app' slug (recommended)
UPDATE tenants 
SET slug = 'app', name = 'POS System'
WHERE id = '00000000-0000-0000-0000-000000000001';

-- Verify the change
SELECT id, name, slug FROM tenants WHERE id = '00000000-0000-0000-0000-000000000001';

-- Success message
DO $$
DECLARE
    new_slug TEXT;
BEGIN
    SELECT slug INTO new_slug FROM tenants WHERE id = '00000000-0000-0000-0000-000000000001';
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ TENANT UPDATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tenant slug changed from "demo" to "%"', new_slug;
    RAISE NOTICE 'Your dashboard is now at: /%/dashboard', new_slug;
    RAISE NOTICE '';
    RAISE NOTICE 'No more "demo" in your URLs!';
    RAISE NOTICE '========================================';
END $$;

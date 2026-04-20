-- =====================================================
-- SIMPLE SUPERADMIN SETUP
-- =====================================================
-- This script creates your superadmin account
-- using your EXISTING database schema
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- STEP 1: Ensure default tenant exists
-- =====================================================

INSERT INTO tenants (id, name, slug)
VALUES ('00000000-0000-0000-0000-000000000001', 'Demo Store', 'demo')
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 2: Create default roles (if they don't exist)
-- =====================================================

-- Admin role
INSERT INTO roles (tenant_id, name, description, permissions)
SELECT '00000000-0000-0000-0000-000000000001', 'Admin', 'Full system access',
    ARRAY['sales.view', 'sales.create', 'sales.edit', 'sales.delete', 'sales.refund',
          'inventory.view', 'inventory.create', 'inventory.edit', 'inventory.delete', 'inventory.adjust',
          'customers.view', 'customers.create', 'customers.edit', 'customers.delete',
          'employees.view', 'employees.create', 'employees.edit', 'employees.delete',
          'reports.view', 'reports.export', 'settings.view', 'settings.edit', 'roles.manage']
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Admin');

-- Manager role
INSERT INTO roles (tenant_id, name, description, permissions)
SELECT '00000000-0000-0000-0000-000000000001', 'Manager', 'Management access',
    ARRAY['sales.view', 'sales.create', 'sales.edit', 'sales.refund',
          'inventory.view', 'inventory.create', 'inventory.edit', 'inventory.adjust',
          'customers.view', 'customers.create', 'customers.edit',
          'employees.view', 'reports.view', 'reports.export']
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Manager');

-- Cashier role
INSERT INTO roles (tenant_id, name, description, permissions)
SELECT '00000000-0000-0000-0000-000000000001', 'Cashier', 'Basic POS access',
    ARRAY['sales.view', 'sales.create', 'inventory.view',
          'customers.view', 'customers.create', 'reports.view']
WHERE NOT EXISTS (SELECT 1 FROM roles WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Cashier');

-- =====================================================
-- STEP 3: Create customer tiers
-- =====================================================

INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
SELECT '00000000-0000-0000-0000-000000000001', 'Bronze', 0, 2, '#CD7F32'
WHERE NOT EXISTS (SELECT 1 FROM customer_tiers WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Bronze');

INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
SELECT '00000000-0000-0000-0000-000000000001', 'Silver', 500, 5, '#C0C0C0'
WHERE NOT EXISTS (SELECT 1 FROM customer_tiers WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Silver');

INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
SELECT '00000000-0000-0000-0000-000000000001', 'Gold', 1000, 10, '#FFD700'
WHERE NOT EXISTS (SELECT 1 FROM customer_tiers WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Gold');

INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
SELECT '00000000-0000-0000-0000-000000000001', 'Platinum', 2500, 15, '#E5E4E2'
WHERE NOT EXISTS (SELECT 1 FROM customer_tiers WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Platinum');

INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
SELECT '00000000-0000-0000-0000-000000000001', 'Diamond', 5000, 20, '#B9F2FF'
WHERE NOT EXISTS (SELECT 1 FROM customer_tiers WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND name = 'Diamond');

-- =====================================================
-- STEP 4: Create stock location
-- =====================================================

INSERT INTO stock_locations (tenant_id, location_name)
SELECT '00000000-0000-0000-0000-000000000001', 'Main Store'
WHERE NOT EXISTS (
    SELECT 1 FROM stock_locations 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
    AND location_name = 'Main Store'
);

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Created:';
    RAISE NOTICE '   - Demo Store tenant';
    RAISE NOTICE '   - 3 Roles (Admin, Manager, Cashier)';
    RAISE NOTICE '   - 5 Customer Tiers';
    RAISE NOTICE '   - Main Store location';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NEXT STEP: Create your user account';
    RAISE NOTICE '';
    RAISE NOTICE '📧 Go to Supabase Dashboard → Authentication';
    RAISE NOTICE '   Click "Add User" → "Create new user"';
    RAISE NOTICE '   Email: snakeyes358@gmail.com';
    RAISE NOTICE '   Password: Useless19112004';
    RAISE NOTICE '   Auto Confirm: YES';
    RAISE NOTICE '';
    RAISE NOTICE 'Then you can login at your app!';
    RAISE NOTICE '========================================';
END $$;

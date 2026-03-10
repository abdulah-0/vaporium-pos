-- =====================================================
-- POS System - Simple Data Setup
-- =====================================================
-- This script adds default data and superadmin account
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- STEP 1: Create Default Tenant
-- =====================================================

DO $$
DECLARE
    tenant_exists BOOLEAN;
BEGIN
    -- Check if tenant exists
    SELECT EXISTS(SELECT 1 FROM tenants WHERE id = '00000000-0000-0000-0000-000000000001') INTO tenant_exists;
    
    IF NOT tenant_exists THEN
        INSERT INTO tenants (id, name, slug)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Demo Store',
            'demo'
        );
        RAISE NOTICE '✅ Created default tenant';
    ELSE
        RAISE NOTICE '✅ Tenant already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 2: Create Default Stock Location
-- =====================================================

DO $$
DECLARE
    location_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM stock_locations 
        WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
        AND location_name = 'Main Store'
    ) INTO location_exists;
    
    IF NOT location_exists THEN
        INSERT INTO stock_locations (tenant_id, location_name)
        VALUES ('00000000-0000-0000-0000-000000000001', 'Main Store');
        RAISE NOTICE '✅ Created default stock location';
    ELSE
        RAISE NOTICE '✅ Stock location already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 3: Create Default Roles
-- =====================================================

DO $$
DECLARE
    admin_exists BOOLEAN;
    manager_exists BOOLEAN;
    cashier_exists BOOLEAN;
BEGIN
    -- Check Admin role
    SELECT EXISTS(
        SELECT 1 FROM roles 
        WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
        AND name = 'Admin'
    ) INTO admin_exists;
    
    IF NOT admin_exists THEN
        INSERT INTO roles (tenant_id, name, description, permissions)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Admin',
            'Full system access',
            ARRAY[
                'sales.view', 'sales.create', 'sales.edit', 'sales.delete', 'sales.refund',
                'inventory.view', 'inventory.create', 'inventory.edit', 'inventory.delete', 'inventory.adjust',
                'customers.view', 'customers.create', 'customers.edit', 'customers.delete',
                'employees.view', 'employees.create', 'employees.edit', 'employees.delete',
                'reports.view', 'reports.export',
                'settings.view', 'settings.edit', 'roles.manage'
            ]
        );
        RAISE NOTICE '✅ Created Admin role';
    ELSE
        RAISE NOTICE '✅ Admin role already exists';
    END IF;
    
    -- Check Manager role
    SELECT EXISTS(
        SELECT 1 FROM roles 
        WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
        AND name = 'Manager'
    ) INTO manager_exists;
    
    IF NOT manager_exists THEN
        INSERT INTO roles (tenant_id, name, description, permissions)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Manager',
            'Management access',
            ARRAY[
                'sales.view', 'sales.create', 'sales.edit', 'sales.refund',
                'inventory.view', 'inventory.create', 'inventory.edit', 'inventory.adjust',
                'customers.view', 'customers.create', 'customers.edit',
                'employees.view',
                'reports.view', 'reports.export'
            ]
        );
        RAISE NOTICE '✅ Created Manager role';
    ELSE
        RAISE NOTICE '✅ Manager role already exists';
    END IF;
    
    -- Check Cashier role
    SELECT EXISTS(
        SELECT 1 FROM roles 
        WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
        AND name = 'Cashier'
    ) INTO cashier_exists;
    
    IF NOT cashier_exists THEN
        INSERT INTO roles (tenant_id, name, description, permissions)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Cashier',
            'Basic POS access',
            ARRAY[
                'sales.view', 'sales.create',
                'inventory.view',
                'customers.view', 'customers.create',
                'reports.view'
            ]
        );
        RAISE NOTICE '✅ Created Cashier role';
    ELSE
        RAISE NOTICE '✅ Cashier role already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 4: Create Customer Tiers
-- =====================================================

DO $$
DECLARE
    tier_names TEXT[] := ARRAY['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'];
    tier_points INT[] := ARRAY[0, 500, 1000, 2500, 5000];
    tier_discounts DECIMAL[] := ARRAY[2, 5, 10, 15, 20];
    tier_colors TEXT[] := ARRAY['#CD7F32', '#C0C0C0', '#FFD700', '#E5E4E2', '#B9F2FF'];
    i INT;
    tier_exists BOOLEAN;
BEGIN
    FOR i IN 1..5 LOOP
        SELECT EXISTS(
            SELECT 1 FROM customer_tiers 
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
            AND name = tier_names[i]
        ) INTO tier_exists;
        
        IF NOT tier_exists THEN
            INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
            VALUES (
                '00000000-0000-0000-0000-000000000001',
                tier_names[i],
                tier_points[i],
                tier_discounts[i],
                tier_colors[i]
            );
            RAISE NOTICE '✅ Created % tier', tier_names[i];
        ELSE
            RAISE NOTICE '✅ % tier already exists', tier_names[i];
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- STEP 5: Create Superadmin Account
-- =====================================================

DO $$
DECLARE
    admin_role_id INTEGER;
    person_id INTEGER;
    person_exists BOOLEAN;
    employee_exists BOOLEAN;
BEGIN
    -- Get Admin role ID
    SELECT id INTO admin_role_id 
    FROM roles 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
    AND name = 'Admin'
    LIMIT 1;
    
    IF admin_role_id IS NULL THEN
        RAISE EXCEPTION 'Admin role not found! Please ensure roles were created.';
    END IF;
    
    -- Check if person exists
    SELECT EXISTS(
        SELECT 1 FROM people WHERE email = 'snakeyes358@gmail.com'
    ) INTO person_exists;
    
    IF NOT person_exists THEN
        INSERT INTO people (tenant_id, first_name, last_name, email)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Super',
            'Admin',
            'snakeyes358@gmail.com'
        )
        RETURNING id INTO person_id;
        RAISE NOTICE '✅ Created person record for superadmin';
    ELSE
        SELECT id INTO person_id FROM people WHERE email = 'snakeyes358@gmail.com' LIMIT 1;
        RAISE NOTICE '✅ Person record already exists';
    END IF;
    
    -- Check if employee exists
    SELECT EXISTS(
        SELECT 1 FROM employees WHERE username = 'superadmin'
    ) INTO employee_exists;
    
    IF NOT employee_exists THEN
        INSERT INTO employees (tenant_id, person_id, username, password, role_id, deleted)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            person_id,
            'superadmin',
            crypt('Useless19112004', gen_salt('bf')),
            admin_role_id,
            FALSE
        );
        RAISE NOTICE '✅ Created superadmin employee account';
    ELSE
        -- Update password if employee exists
        UPDATE employees 
        SET 
            password = crypt('Useless19112004', gen_salt('bf')),
            role_id = admin_role_id,
            deleted = FALSE
        WHERE username = 'superadmin';
        RAISE NOTICE '✅ Updated superadmin password';
    END IF;
END $$;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ DATABASE SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '� SUPERADMIN LOGIN CREDENTIALS:';
    RAISE NOTICE '   Email: snakeyes358@gmail.com';
    RAISE NOTICE '   Username: superadmin';
    RAISE NOTICE '   Password: Useless19112004';
    RAISE NOTICE '';
    RAISE NOTICE '🏢 Tenant: Demo Store (slug: demo)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Created:';
    RAISE NOTICE '   - 3 Roles (Admin, Manager, Cashier)';
    RAISE NOTICE '   - 5 Customer Tiers (Bronze to Diamond)';
    RAISE NOTICE '   - 1 Stock Location (Main Store)';
    RAISE NOTICE '   - 1 Superadmin Account';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Login at: https://your-app.vercel.app/login';
    RAISE NOTICE '========================================';
END $$;

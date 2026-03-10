-- =====================================================
-- LINK YOUR AUTH USER TO EMPLOYEE RECORD
-- =====================================================
-- Run this to fix the redirect issue
-- This creates an employee record for your auth user
-- =====================================================

-- First, let's see your user ID
-- Copy the id from the result and use it below
SELECT id, email FROM auth.users WHERE email = 'snakeyes358@gmail.com';

-- =====================================================
-- CREATE EMPLOYEE RECORD
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID from above
-- =====================================================

DO $$
DECLARE
    v_user_id UUID;
    v_person_id INTEGER;
    v_admin_role_id INTEGER;
    v_employee_exists BOOLEAN;
BEGIN
    -- Get the user ID
    SELECT id INTO v_user_id 
    FROM auth.users 
    WHERE email = 'snakeyes358@gmail.com' 
    LIMIT 1;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found! Please create user in Supabase Auth first.';
    END IF;
    
    RAISE NOTICE 'Found user ID: %', v_user_id;
    
    -- Check if employee already exists for this user
    SELECT EXISTS(
        SELECT 1 FROM employees WHERE user_id = v_user_id
    ) INTO v_employee_exists;
    
    IF v_employee_exists THEN
        RAISE NOTICE 'Employee record already exists for this user';
        RETURN;
    END IF;
    
    -- Get Admin role ID
    SELECT id INTO v_admin_role_id 
    FROM roles 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
    AND name = 'Admin' 
    LIMIT 1;
    
    IF v_admin_role_id IS NULL THEN
        RAISE EXCEPTION 'Admin role not found!';
    END IF;
    
    -- Check if person record exists
    SELECT id INTO v_person_id 
    FROM people 
    WHERE email = 'snakeyes358@gmail.com' 
    LIMIT 1;
    
    -- Create person record if doesn't exist
    IF v_person_id IS NULL THEN
        INSERT INTO people (tenant_id, first_name, last_name, email)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'Super',
            'Admin',
            'snakeyes358@gmail.com'
        )
        RETURNING id INTO v_person_id;
        
        RAISE NOTICE 'Created person record with ID: %', v_person_id;
    ELSE
        RAISE NOTICE 'Person record already exists with ID: %', v_person_id;
    END IF;
    
    -- Create employee record
    INSERT INTO employees (
        tenant_id, 
        person_id, 
        user_id, 
        username, 
        role_id, 
        deleted
    )
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        v_person_id,
        v_user_id,
        'superadmin',
        v_admin_role_id,
        FALSE
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ EMPLOYEE RECORD CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'User ID: %', v_user_id;
    RAISE NOTICE 'Person ID: %', v_person_id;
    RAISE NOTICE 'Role: Admin';
    RAISE NOTICE 'Username: superadmin';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 You can now login successfully!';
    RAISE NOTICE '========================================';
    
END $$;

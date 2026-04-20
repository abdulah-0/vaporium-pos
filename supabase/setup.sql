-- =====================================================
-- VAPORIUM POS - COMPLETE SUPABASE SETUP
-- =====================================================
-- Run this ONCE in your Supabase SQL Editor.
-- Go to: https://supabase.com/dashboard → Your Project → SQL Editor
--
-- After running:
--   1. Create a user in Supabase Auth (Authentication → Users → Add user)
--   2. Replace the email below and run Part 2 to link the user as Admin
-- =====================================================

-- =====================================================
-- PART 1: CREATE ALL TABLES
-- =====================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tenants (one per business)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    subscription_plan VARCHAR(50) DEFAULT 'professional',
    subscription_status VARCHAR(50) DEFAULT 'trial',
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tenant users (relationship between auth users and tenants)
CREATE TABLE IF NOT EXISTS tenant_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'employee',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, user_id)
);

-- Profiles
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    current_tenant_id UUID REFERENCES tenants(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- People (shared between customers, suppliers, employees)
CREATE TABLE IF NOT EXISTS people (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(50),
    address_1 VARCHAR(255),
    address_2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip VARCHAR(20),
    country VARCHAR(100),
    comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Roles
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);

-- Employees
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    username VARCHAR(100) UNIQUE,
    role_id INTEGER REFERENCES roles(id),
    commission_rate DECIMAL(5,2) DEFAULT 0,
    commission_type VARCHAR(20) DEFAULT 'percentage',
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    account_number VARCHAR(100),
    taxable BOOLEAN DEFAULT TRUE,
    tax_id VARCHAR(100),
    discount_percent DECIMAL(5,2) DEFAULT 0,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    company_name VARCHAR(255),
    account_number VARCHAR(100),
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customer tiers (loyalty)
CREATE TABLE IF NOT EXISTS customer_tiers (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    min_points INTEGER NOT NULL DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    color VARCHAR(7) DEFAULT '#3B82F6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);

-- Loyalty points
CREATE TABLE IF NOT EXISTS loyalty_points (
    customer_id INTEGER PRIMARY KEY REFERENCES customers(id) ON DELETE CASCADE,
    points INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Loyalty transactions
CREATE TABLE IF NOT EXISTS loyalty_transactions (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    reference_id INTEGER,
    reference_type VARCHAR(50),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Items (products)
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    item_number VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(100),
    description TEXT,
    cost_price DECIMAL(10,2) DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL,
    reorder_level INTEGER DEFAULT 0,
    allow_alt_description BOOLEAN DEFAULT FALSE,
    is_serialized BOOLEAN DEFAULT FALSE,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stock locations
CREATE TABLE IF NOT EXISTS stock_locations (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    location_name VARCHAR(255) NOT NULL,
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, location_name)
);

-- Inventory (items × locations)
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    location_id INTEGER NOT NULL REFERENCES stock_locations(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(item_id, location_id)
);

-- Inventory transactions
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    location_id INTEGER REFERENCES stock_locations(id),
    quantity INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    reference_id INTEGER,
    reference_type VARCHAR(50),
    employee_id INTEGER REFERENCES employees(id),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sales
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sale_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    customer_id INTEGER REFERENCES customers(id),
    employee_id INTEGER REFERENCES employees(id),
    comment TEXT,
    invoice_number VARCHAR(100) UNIQUE,
    sale_status VARCHAR(50) DEFAULT 'completed',
    sale_total DECIMAL(10,2) NOT NULL,
    tax DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sales items (line items)
CREATE TABLE IF NOT EXISTS sales_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(id),
    description TEXT,
    serialnumber VARCHAR(255),
    line INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    item_cost_price DECIMAL(10,2) DEFAULT 0,
    item_unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sales payments
CREATE TABLE IF NOT EXISTS sales_payments (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    payment_type VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Receivings (stock arrivals)
CREATE TABLE IF NOT EXISTS receivings (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    receiving_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    supplier_id INTEGER REFERENCES suppliers(id),
    employee_id INTEGER REFERENCES employees(id),
    comment TEXT,
    payment_type VARCHAR(50),
    reference VARCHAR(100),
    total_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Receiving items
CREATE TABLE IF NOT EXISTS receivings_items (
    id SERIAL PRIMARY KEY,
    receiving_id INTEGER NOT NULL REFERENCES receivings(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items(id),
    description TEXT,
    serialnumber VARCHAR(255),
    line INTEGER NOT NULL,
    quantity_purchased INTEGER NOT NULL,
    item_cost_price DECIMAL(10,2) NOT NULL,
    item_unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    receiving_quantity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Time entries
CREATE TABLE IF NOT EXISTS time_entries (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    break_minutes INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Commissions
CREATE TABLE IF NOT EXISTS commissions (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    sale_id INTEGER,
    sale_amount DECIMAL(10,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    paid BOOLEAN DEFAULT FALSE,
    paid_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_people_tenant         ON people(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_tenant      ON employees(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_user        ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant      ON customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant      ON suppliers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_items_tenant          ON items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_tenant          ON sales(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_time            ON sales(sale_time);
CREATE INDEX IF NOT EXISTS idx_inventory_item        ON inventory(item_id);
CREATE INDEX IF NOT EXISTS idx_tenant_users_tenant   ON tenant_users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_users_user     ON tenant_users(user_id);

-- =====================================================
-- DEFAULT TENANT DATA
-- =====================================================

-- !! CHANGE 'My Store' and 'my-store' to your actual business name !!
INSERT INTO tenants (id, name, slug, subscription_status, trial_ends_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'My Store',
    'my-store',
    'trial',
    NOW() + INTERVAL '365 days'
)
ON CONFLICT (id) DO NOTHING;

-- Default roles
INSERT INTO roles (tenant_id, name, description, permissions) VALUES
('00000000-0000-0000-0000-000000000001', 'Admin', 'Full system access',
 ARRAY['sales.view','sales.create','sales.edit','sales.delete','sales.refund',
       'inventory.view','inventory.create','inventory.edit','inventory.delete','inventory.adjust',
       'customers.view','customers.create','customers.edit','customers.delete',
       'employees.view','employees.create','employees.edit','employees.delete',
       'reports.view','reports.export','settings.view','settings.edit','roles.manage']),
('00000000-0000-0000-0000-000000000001', 'Manager', 'Management access',
 ARRAY['sales.view','sales.create','sales.edit','sales.refund',
       'inventory.view','inventory.create','inventory.edit','inventory.adjust',
       'customers.view','customers.create','customers.edit',
       'employees.view','reports.view','reports.export']),
('00000000-0000-0000-0000-000000000001', 'Cashier', 'Basic POS access',
 ARRAY['sales.view','sales.create','inventory.view','customers.view','customers.create'])
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Customer tiers
INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color) VALUES
('00000000-0000-0000-0000-000000000001', 'Bronze',   0,    2,  '#CD7F32'),
('00000000-0000-0000-0000-000000000001', 'Silver',   500,  5,  '#C0C0C0'),
('00000000-0000-0000-0000-000000000001', 'Gold',     1000, 10, '#FFD700'),
('00000000-0000-0000-0000-000000000001', 'Platinum', 2500, 15, '#E5E4E2'),
('00000000-0000-0000-0000-000000000001', 'Diamond',  5000, 20, '#B9F2FF')
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Default stock location
INSERT INTO stock_locations (tenant_id, location_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'Main Store')
ON CONFLICT (tenant_id, location_name) DO NOTHING;


-- =====================================================
-- PART 2: LINK YOUR ADMIN USER
-- =====================================================
-- Run this AFTER creating a user in Supabase Auth.
-- Replace the email below with YOUR actual email address.
-- =====================================================

DO $$
DECLARE
    v_email      TEXT    := 'YOUR_EMAIL@example.com';  -- << CHANGE THIS
    v_user_id    UUID;
    v_person_id  INTEGER;
    v_role_id    INTEGER;
    v_tenant_id  UUID    := '00000000-0000-0000-0000-000000000001';
BEGIN
    -- Look up auth user
    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email LIMIT 1;
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User "%" not found. Create the user in Supabase Auth → Users first.', v_email;
    END IF;

    -- Get Admin role
    SELECT id INTO v_role_id FROM roles WHERE tenant_id = v_tenant_id AND name = 'Admin' LIMIT 1;

    -- Create person record if needed
    SELECT id INTO v_person_id FROM people WHERE email = v_email AND tenant_id = v_tenant_id LIMIT 1;
    IF v_person_id IS NULL THEN
        INSERT INTO people (tenant_id, first_name, last_name, email)
        VALUES (v_tenant_id, 'Admin', 'User', v_email)
        RETURNING id INTO v_person_id;
    END IF;

    -- Create employee record
    INSERT INTO employees (tenant_id, person_id, user_id, username, role_id, deleted)
    VALUES (v_tenant_id, v_person_id, v_user_id, 'admin', v_role_id, FALSE)
    ON CONFLICT DO NOTHING;

    -- Create profile
    INSERT INTO profiles (id, full_name, current_tenant_id)
    VALUES (v_user_id, 'Admin User', v_tenant_id)
    ON CONFLICT (id) DO NOTHING;

    -- Link tenant_user
    INSERT INTO tenant_users (tenant_id, user_id, role, joined_at)
    VALUES (v_tenant_id, v_user_id, 'owner', NOW())
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Admin user linked successfully!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Email:  %', v_email;
    RAISE NOTICE 'Tenant: my-store';
    RAISE NOTICE 'Role:   Admin';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Login at your app URL with this email!';
    RAISE NOTICE 'After login the app will go to /my-store/dashboard';
    RAISE NOTICE '========================================';
END $$;

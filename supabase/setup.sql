-- =====================================================
-- Complete POS System Database Setup Script
-- =====================================================
-- This script creates all tables, relationships, policies,
-- and initial data for the POS system
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- CORE TABLES
-- =====================================================

-- Tenants table (multi-tenant support)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    logo_url TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- People table (shared for customers, suppliers, employees)
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

-- =====================================================
-- EMPLOYEE & ROLES TABLES
-- =====================================================

-- Roles table (RBAC)
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);

-- Employees table
CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id INTEGER REFERENCES roles(id),
    commission_rate DECIMAL(5,2) DEFAULT 0,
    commission_type VARCHAR(20) DEFAULT 'percentage',
    deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Time entries (clock in/out)
CREATE TABLE IF NOT EXISTS time_entries (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
    clock_out TIMESTAMP WITH TIME ZONE,
    break_minutes INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Commissions table
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
-- CUSTOMER TABLES
-- =====================================================

-- Customers table
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

-- =====================================================
-- SUPPLIER TABLES
-- =====================================================

-- Suppliers table
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

-- =====================================================
-- INVENTORY TABLES
-- =====================================================

-- Items table
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

-- Inventory (stock levels)
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
    location_id INTEGER NOT NULL REFERENCES stock_locations(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(item_id, location_id)
);

-- Inventory transactions (audit trail)
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

-- =====================================================
-- SALES TABLES
-- =====================================================

-- Sales table
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

-- =====================================================
-- RECEIVING TABLES
-- =====================================================

-- Receivings (purchase orders)
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

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_people_tenant ON people(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_tenant ON employees(tenant_id);
CREATE INDEX IF NOT EXISTS idx_employees_username ON employees(username);
CREATE INDEX IF NOT EXISTS idx_customers_tenant ON customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant ON suppliers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_items_tenant ON items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_items_number ON items(item_number);
CREATE INDEX IF NOT EXISTS idx_sales_tenant ON sales(tenant_id);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_employee ON sales(employee_id);
CREATE INDEX IF NOT EXISTS idx_sales_time ON sales(sale_time);
CREATE INDEX IF NOT EXISTS idx_inventory_item ON inventory(item_id);
CREATE INDEX IF NOT EXISTS idx_inventory_location ON inventory(location_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policies (example for tenants table)
CREATE POLICY tenant_isolation ON tenants
    FOR ALL
    USING (auth.uid() IN (
        SELECT e.id::text::uuid FROM employees e WHERE e.tenant_id = tenants.id
    ));

-- =====================================================
-- INITIAL DATA SETUP
-- =====================================================

-- Create default tenant
INSERT INTO tenants (id, name, slug, email)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Demo Store',
    'demo',
    'demo@posystem.com'
) ON CONFLICT (id) DO NOTHING;

-- Create default stock location
INSERT INTO stock_locations (tenant_id, location_name)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Main Store'
) ON CONFLICT DO NOTHING;

-- Create default roles
INSERT INTO roles (tenant_id, name, description, permissions)
VALUES 
    (
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
    ),
    (
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
    ),
    (
        '00000000-0000-0000-0000-000000000001',
        'Cashier',
        'Basic POS access',
        ARRAY[
            'sales.view', 'sales.create',
            'inventory.view',
            'customers.view', 'customers.create',
            'reports.view'
        ]
    )
ON CONFLICT DO NOTHING;

-- Create default customer tiers
INSERT INTO customer_tiers (tenant_id, name, min_points, discount_percent, color)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Bronze', 0, 2, '#CD7F32'),
    ('00000000-0000-0000-0000-000000000001', 'Silver', 500, 5, '#C0C0C0'),
    ('00000000-0000-0000-0000-000000000001', 'Gold', 1000, 10, '#FFD700'),
    ('00000000-0000-0000-0000-000000000001', 'Platinum', 2500, 15, '#E5E4E2'),
    ('00000000-0000-0000-0000-000000000001', 'Diamond', 5000, 20, '#B9F2FF')
ON CONFLICT DO NOTHING;

-- =====================================================
-- CREATE SUPERADMIN USER
-- =====================================================

-- Create person record for superadmin
INSERT INTO people (tenant_id, first_name, last_name, email)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Super',
    'Admin',
    'snakeyes358@gmail.com'
) ON CONFLICT DO NOTHING
RETURNING id;

-- Get the Admin role ID
DO $$
DECLARE
    admin_role_id INTEGER;
    person_id INTEGER;
BEGIN
    -- Get Admin role ID
    SELECT id INTO admin_role_id 
    FROM roles 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001' 
    AND name = 'Admin';
    
    -- Get person ID
    SELECT id INTO person_id 
    FROM people 
    WHERE email = 'snakeyes358@gmail.com';
    
    -- Create superadmin employee
    INSERT INTO employees (tenant_id, person_id, username, password, role_id, deleted)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        person_id,
        'superadmin',
        crypt('Useless19112004', gen_salt('bf')), -- Encrypted password
        admin_role_id,
        FALSE
    ) ON CONFLICT (username) DO NOTHING;
END $$;

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_people_updated_at BEFORE UPDATE ON people
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at BEFORE UPDATE ON items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database setup complete!';
    RAISE NOTICE '✅ Superadmin created: snakeyes358@gmail.com';
    RAISE NOTICE '✅ Username: superadmin';
    RAISE NOTICE '✅ Password: Useless19112004';
    RAISE NOTICE '✅ Tenant: demo (slug: demo)';
    RAISE NOTICE '✅ All tables, indexes, and policies created';
END $$;

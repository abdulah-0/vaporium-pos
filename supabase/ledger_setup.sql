-- =====================================================
-- VAPORIUM POS - LEDGER & FINANCE SYSTEM SETUP
-- =====================================================
-- Run this in your Supabase SQL Editor.
-- =====================================================

-- Supplier Ledger Entries
CREATE TABLE IF NOT EXISTS supplier_ledger_entries (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    transaction_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    transaction_type VARCHAR(50) NOT NULL, -- 'credit', 'payment', 'adjustment', 'advance'
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    payment_method VARCHAR(50), -- 'cash', 'card', 'check', 'bank_transfer', etc.
    reference_id INTEGER, -- e.g. receiving_id
    reference_type VARCHAR(50), -- e.g. 'receiving'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customer Ledger Entries
CREATE TABLE IF NOT EXISTS customer_ledger_entries (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    transaction_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    transaction_type VARCHAR(50) NOT NULL, -- 'credit', 'payment', 'adjustment', 'advance'
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    payment_method VARCHAR(50),
    reference_id INTEGER, -- e.g. sale_id
    reference_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shop Expenses
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    expense_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    payment_method VARCHAR(50),
    employee_id INTEGER REFERENCES employees(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_supplier_ledger_tenant    ON supplier_ledger_entries(tenant_id);
CREATE INDEX IF NOT EXISTS idx_supplier_ledger_supplier  ON supplier_ledger_entries(supplier_id);
CREATE INDEX IF NOT EXISTS idx_customer_ledger_tenant    ON customer_ledger_entries(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_ledger_customer  ON customer_ledger_entries(customer_id);
CREATE INDEX IF NOT EXISTS idx_expenses_tenant           ON expenses(tenant_id);
CREATE INDEX IF NOT EXISTS idx_expenses_time             ON expenses(expense_time);

-- =====================================================
-- ENABLE RLS (Row Level Security)
-- =====================================================

ALTER TABLE supplier_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Policies (Simplified: Tenant members can view/manage their data)
CREATE POLICY "Tenant users can manage supplier ledger" ON supplier_ledger_entries
    FOR ALL USING (tenant_id IN (SELECT current_tenant_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Tenant users can manage customer ledger" ON customer_ledger_entries
    FOR ALL USING (tenant_id IN (SELECT current_tenant_id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Tenant users can manage expenses" ON expenses
    FOR ALL USING (tenant_id IN (SELECT current_tenant_id FROM profiles WHERE id = auth.uid()));

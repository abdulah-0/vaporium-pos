-- =====================================================
-- Migration: Fix missing DB columns & tables
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Add discount columns to sales table
ALTER TABLE sales
    ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS discount_type   VARCHAR(20)   DEFAULT 'percent';

-- 2. Add tax_id to suppliers table (was missing from original schema)
ALTER TABLE suppliers
    ADD COLUMN IF NOT EXISTS tax_id VARCHAR(100);

-- 3. Create app_config table for company settings (receipt printing, etc.)
CREATE TABLE IF NOT EXISTS app_config (
    id          SERIAL PRIMARY KEY,
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    key         VARCHAR(100) NOT NULL,
    value       TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, key)
);

CREATE INDEX IF NOT EXISTS idx_app_config_tenant ON app_config(tenant_id);

-- 4. Seed default company info for Demo Store tenant
INSERT INTO app_config (tenant_id, key, value) VALUES
    ('00000000-0000-0000-0000-000000000001', 'company_name',    'Demo Store'),
    ('00000000-0000-0000-0000-000000000001', 'company_address', '123 Main St, City'),
    ('00000000-0000-0000-0000-000000000001', 'company_phone',   '+1 (555) 000-0000'),
    ('00000000-0000-0000-0000-000000000001', 'company_email',   'demo@store.com'),
    ('00000000-0000-0000-0000-000000000001', 'tax_id',          '')
ON CONFLICT (tenant_id, key) DO NOTHING;

-- =====================================================
-- Migration: Add discount columns to sales table
-- Run this in Supabase SQL Editor if you haven't yet
-- =====================================================

ALTER TABLE sales
    ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS discount_type   VARCHAR(20)   DEFAULT 'percent';

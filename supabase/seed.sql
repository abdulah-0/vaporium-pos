-- Seed data for development/testing

-- Insert a default admin person
INSERT INTO people (first_name, last_name, phone_number, email, address_1, city, state, zip, country)
VALUES ('Admin', 'User', '555-555-5555', 'admin@pos.com', '123 Main St', 'New York', 'NY', '10001', 'USA');

-- Create admin employee (person_id will be 1 from above)
INSERT INTO employees (person_id, username, deleted)
VALUES (1, 'admin', FALSE);

-- Insert sample customers
INSERT INTO people (first_name, last_name, phone_number, email, address_1, city, state, zip, country)
VALUES 
    ('John', 'Doe', '555-123-4567', 'john.doe@email.com', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA'),
    ('Jane', 'Smith', '555-987-6543', 'jane.smith@email.com', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA');

INSERT INTO customers (person_id, company_name, account_number, taxable, discount_percent)
VALUES 
    (2, 'Doe Enterprises', 'CUST001', TRUE, 5.00),
    (3, NULL, 'CUST002', TRUE, 0.00);

-- Insert sample supplier
INSERT INTO people (first_name, last_name, phone_number, email, address_1, city, state, zip, country)
VALUES ('Supplier', 'Company', '555-111-2222', 'contact@supplier.com', '321 Business Blvd', 'Houston', 'TX', '77001', 'USA');

INSERT INTO suppliers (person_id, company_name, agency_name, account_number)
VALUES (4, 'ABC Wholesale', 'ABC Distribution', 'SUPP001');

-- Insert sample items
INSERT INTO items (name, category, supplier_id, item_number, description, cost_price, unit_price, reorder_level, allow_alt_description, is_serialized)
VALUES 
    ('Laptop Computer', 'Electronics', 1, 'ITEM001', 'High-performance laptop', 800.00, 1200.00, 5, FALSE, TRUE),
    ('Wireless Mouse', 'Electronics', 1, 'ITEM002', 'Ergonomic wireless mouse', 15.00, 29.99, 20, FALSE, FALSE),
    ('Office Chair', 'Furniture', 1, 'ITEM003', 'Comfortable office chair', 150.00, 299.99, 10, FALSE, FALSE),
    ('Notebook', 'Stationery', 1, 'ITEM004', 'A4 ruled notebook', 1.50, 4.99, 50, FALSE, FALSE),
    ('Pen Set', 'Stationery', 1, 'ITEM005', 'Pack of 10 ballpoint pens', 3.00, 7.99, 30, FALSE, FALSE);

-- Add stock quantities for items
INSERT INTO item_quantities (item_id, location_id, quantity)
VALUES 
    (1, 1, 10),
    (2, 1, 50),
    (3, 1, 15),
    (4, 1, 100),
    (5, 1, 75);

-- Insert a sample gift card
INSERT INTO giftcards (giftcard_number, value, person_id)
VALUES (1234567890, 100.00, 2);

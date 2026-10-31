CREATE TABLE IF NOT EXISTS customers (customer_id TEXT PRIMARY KEY, basic_json TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS customer_pans (customer_id TEXT PRIMARY KEY REFERENCES customers(customer_id), pan_number TEXT NOT NULL UNIQUE, details_json TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS customer_addresses (customer_id TEXT PRIMARY KEY REFERENCES customers(customer_id), details_json TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS customer_employment (customer_id TEXT PRIMARY KEY REFERENCES customers(customer_id), details_json TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS customer_credit_profiles (customer_id TEXT PRIMARY KEY REFERENCES customers(customer_id), details_json TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS customer_loans (id INTEGER PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers(customer_id), details_json TEXT NOT NULL);
CREATE INDEX IF NOT EXISTS idx_customer_loans_customer ON customer_loans(customer_id);

#!/bin/bash

# Script to drop existing tables, create new ones, and insert sample data into MySQL database "mcp"

# Source the database credentials
source /home/ec2-user/mcp/demo_mcp_on_amazon_bedrock/set_db_credentials.sh

# Function to execute MySQL commands
execute_mysql() {
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "$1"
}

echo "Dropping existing tables..."
execute_mysql "
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS persons;"

echo "Creating tables and inserting sample data into MySQL database 'mcp'..."

# Create persons table (we'll keep the existing 'user' table and add a new 'persons' table)
echo "Creating persons table..."
execute_mysql "
CREATE TABLE IF NOT EXISTS persons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    age INT NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    city VARCHAR(50),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Create customers table
echo "Creating customers table..."
execute_mysql "
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Create products table
echo "Creating products table..."
execute_mysql "
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Create orders table
echo "Creating orders table..."
execute_mysql "
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled') DEFAULT 'Pending',
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_address VARCHAR(255),
    shipping_city VARCHAR(50),
    shipping_state VARCHAR(50),
    shipping_postal_code VARCHAR(20),
    shipping_country VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);"

# Create order_items table (to establish many-to-many relationship between orders and products)
echo "Creating order_items table..."
execute_mysql "
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);"

# Insert sample data into persons table
echo "Inserting sample data into persons table..."
execute_mysql "
INSERT INTO persons (first_name, last_name, email, age, gender, city, country) VALUES
('John', 'Smith', 'john.smith@example.com', 32, 'Male', 'New York', 'USA'),
('Emma', 'Johnson', 'emma.johnson@example.com', 28, 'Female', 'London', 'UK'),
('Michael', 'Williams', 'michael.williams@example.com', 45, 'Male', 'Toronto', 'Canada'),
('Sophia', 'Brown', 'sophia.brown@example.com', 22, 'Female', 'Sydney', 'Australia'),
('William', 'Jones', 'william.jones@example.com', 38, 'Male', 'Chicago', 'USA'),
('Olivia', 'Garcia', 'olivia.garcia@example.com', 29, 'Female', 'Madrid', 'Spain'),
('James', 'Miller', 'james.miller@example.com', 41, 'Male', 'Berlin', 'Germany'),
('Ava', 'Davis', 'ava.davis@example.com', 25, 'Female', 'Paris', 'France'),
('Alexander', 'Rodriguez', 'alexander.rodriguez@example.com', 33, 'Male', 'Mexico City', 'Mexico'),
('Isabella', 'Martinez', 'isabella.martinez@example.com', 27, 'Female', 'Rome', 'Italy'),
('Ethan', 'Hernandez', 'ethan.hernandez@example.com', 36, 'Male', 'Tokyo', 'Japan'),
('Mia', 'Lopez', 'mia.lopez@example.com', 24, 'Female', 'Seoul', 'South Korea'),
('Daniel', 'Gonzalez', 'daniel.gonzalez@example.com', 39, 'Male', 'Beijing', 'China'),
('Charlotte', 'Wilson', 'charlotte.wilson@example.com', 31, 'Female', 'Moscow', 'Russia'),
('Matthew', 'Anderson', 'matthew.anderson@example.com', 43, 'Male', 'Cairo', 'Egypt'),
('Amelia', 'Thomas', 'amelia.thomas@example.com', 26, 'Female', 'Cape Town', 'South Africa'),
('Benjamin', 'Taylor', 'benjamin.taylor@example.com', 34, 'Male', 'Rio de Janeiro', 'Brazil'),
('Harper', 'Moore', 'harper.moore@example.com', 23, 'Female', 'Bangkok', 'Thailand'),
('Jacob', 'Jackson', 'jacob.jackson@example.com', 37, 'Male', 'Dubai', 'UAE'),
('Evelyn', 'Martin', 'evelyn.martin@example.com', 30, 'Female', 'Singapore', 'Singapore');"

# Insert sample data into customers table
echo "Inserting sample data into customers table..."
execute_mysql "
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, postal_code, country) VALUES
('Robert', 'Johnson', 'robert.johnson@example.com', '555-123-4567', '123 Main St', 'New York', 'NY', '10001', 'USA'),
('Jennifer', 'Smith', 'jennifer.smith@example.com', '555-234-5678', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA'),
('David', 'Williams', 'david.williams@example.com', '555-345-6789', '789 Pine Rd', 'Chicago', 'IL', '60007', 'USA'),
('Sarah', 'Brown', 'sarah.brown@example.com', '555-456-7890', '101 Maple Dr', 'Houston', 'TX', '77001', 'USA'),
('Michael', 'Jones', 'michael.jones@example.com', '555-567-8901', '202 Cedar Ln', 'Phoenix', 'AZ', '85001', 'USA'),
('Emily', 'Garcia', 'emily.garcia@example.com', '555-678-9012', '303 Birch Blvd', 'Philadelphia', 'PA', '19019', 'USA'),
('Christopher', 'Miller', 'christopher.miller@example.com', '555-789-0123', '404 Elm St', 'San Antonio', 'TX', '78201', 'USA'),
('Jessica', 'Davis', 'jessica.davis@example.com', '555-890-1234', '505 Walnut Ave', 'San Diego', 'CA', '92101', 'USA'),
('Matthew', 'Rodriguez', 'matthew.rodriguez@example.com', '555-901-2345', '606 Cherry Rd', 'Dallas', 'TX', '75201', 'USA'),
('Amanda', 'Martinez', 'amanda.martinez@example.com', '555-012-3456', '707 Spruce Dr', 'San Jose', 'CA', '95101', 'USA');"

# Insert sample data into products table
echo "Inserting sample data into products table..."
execute_mysql "
INSERT INTO products (name, description, category, price, stock_quantity) VALUES
('Smartphone X', 'Latest smartphone with advanced features', 'Electronics', 999.99, 50),
('Laptop Pro', 'High-performance laptop for professionals', 'Electronics', 1499.99, 30),
('Wireless Headphones', 'Noise-cancelling wireless headphones', 'Electronics', 199.99, 100),
('Smart Watch', 'Fitness and health tracking smartwatch', 'Electronics', 249.99, 75),
('Coffee Maker', 'Programmable coffee maker with timer', 'Home Appliances', 89.99, 40),
('Blender', 'High-speed blender for smoothies and more', 'Home Appliances', 79.99, 35),
('Toaster Oven', 'Compact toaster oven with multiple functions', 'Home Appliances', 69.99, 25),
('Running Shoes', 'Lightweight running shoes with cushioning', 'Clothing', 129.99, 60),
('Winter Jacket', 'Waterproof and insulated winter jacket', 'Clothing', 179.99, 45),
('Backpack', 'Durable backpack with laptop compartment', 'Accessories', 59.99, 80),
('Water Bottle', 'Insulated stainless steel water bottle', 'Accessories', 24.99, 120),
('Yoga Mat', 'Non-slip yoga mat with carrying strap', 'Fitness', 39.99, 55),
('Dumbbells Set', 'Adjustable dumbbells set for home workouts', 'Fitness', 149.99, 20),
('Air Purifier', 'HEPA air purifier for allergen removal', 'Home Appliances', 199.99, 15),
('Desk Lamp', 'LED desk lamp with adjustable brightness', 'Home Decor', 49.99, 70);"

# Insert sample data into orders table
echo "Inserting sample data into orders table..."
execute_mysql "
INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address, shipping_city, shipping_state, shipping_postal_code, shipping_country) VALUES
(1, '2025-01-15 10:30:00', 'Delivered', 1199.98, '123 Main St', 'New York', 'NY', '10001', 'USA'),
(2, '2025-01-20 14:45:00', 'Shipped', 279.98, '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA'),
(3, '2025-01-25 09:15:00', 'Processing', 1499.99, '789 Pine Rd', 'Chicago', 'IL', '60007', 'USA'),
(4, '2025-02-01 16:20:00', 'Pending', 114.98, '101 Maple Dr', 'Houston', 'TX', '77001', 'USA'),
(5, '2025-02-05 11:10:00', 'Delivered', 249.99, '202 Cedar Ln', 'Phoenix', 'AZ', '85001', 'USA'),
(6, '2025-02-10 13:25:00', 'Cancelled', 179.99, '303 Birch Blvd', 'Philadelphia', 'PA', '19019', 'USA'),
(7, '2025-02-15 15:40:00', 'Processing', 329.97, '404 Elm St', 'San Antonio', 'TX', '78201', 'USA'),
(8, '2025-02-20 10:05:00', 'Shipped', 199.99, '505 Walnut Ave', 'San Diego', 'CA', '92101', 'USA'),
(9, '2025-02-25 12:30:00', 'Pending', 189.98, '606 Cherry Rd', 'Dallas', 'TX', '75201', 'USA'),
(10, '2025-03-01 09:50:00', 'Processing', 1549.98, '707 Spruce Dr', 'San Jose', 'CA', '95101', 'USA');"

# Insert sample data into order_items table
echo "Inserting sample data into order_items table..."
execute_mysql "
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 999.99),
(1, 11, 2, 24.99),
(2, 3, 1, 199.99),
(2, 10, 1, 59.99),
(3, 2, 1, 1499.99),
(4, 11, 2, 24.99),
(4, 12, 1, 39.99),
(5, 4, 1, 249.99),
(6, 9, 1, 179.99),
(7, 7, 1, 69.99),
(7, 8, 2, 129.99),
(8, 3, 1, 199.99),
(9, 5, 1, 89.99),
(9, 6, 1, 79.99),
(10, 2, 1, 1499.99),
(10, 10, 1, 59.99);"

echo "Sample data insertion complete!"
echo "The following tables have been created or updated:"
echo "- persons: 20 records"
echo "- customers: 10 records"
echo "- products: 15 records"
echo "- orders: 10 records"
echo "- order_items: 16 records"

# Show table counts
echo -e "\nTable record counts:"
execute_mysql "SELECT 'persons' AS table_name, COUNT(*) AS record_count FROM persons
               UNION ALL
               SELECT 'customers', COUNT(*) FROM customers
               UNION ALL
               SELECT 'products', COUNT(*) FROM products
               UNION ALL
               SELECT 'orders', COUNT(*) FROM orders
               UNION ALL
               SELECT 'order_items', COUNT(*) FROM order_items;"

#!/usr/bin/env python3

import sys
import getpass
import pymysql
from pymysql.cursors import DictCursor

def check_requirements():
    """Check if required modules are installed."""
    try:
        import pymysql
    except ImportError:
        print("Error: pymysql module is required but not installed.")
        print("Please install it using: pip install pymysql")
        sys.exit(1)

def get_connection_details():
    """Prompt user for database connection details."""
    rds_endpoint = input("Enter RDS endpoint: ")
    db_name = input("Enter database name: ")
    db_user = input("Enter username: ")
    db_password = getpass.getpass("Enter password: ")

    return rds_endpoint, db_name, db_user, db_password

def confirm_operation():
    """Ask user for confirmation before proceeding."""
    confirm = input("Continue? (y/n): ")
    return confirm.lower() in ['y', 'yes']

def execute_sql_commands(connection):
    """Execute SQL commands to create and populate tables."""
    with connection.cursor() as cursor:
        # Drop tables if they exist
        cursor.execute("DROP TABLE IF EXISTS orders")
        cursor.execute("DROP TABLE IF EXISTS customers")
        cursor.execute("DROP TABLE IF EXISTS products")

        # Create tables
        cursor.execute("""
        CREATE TABLE customers (
            customer_id INT AUTO_INCREMENT PRIMARY KEY,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            email VARCHAR(100) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """)

        cursor.execute("""
        CREATE TABLE products (
            product_id INT AUTO_INCREMENT PRIMARY KEY,
            product_name VARCHAR(100) NOT NULL,
            description TEXT,
            price DECIMAL(10, 2) NOT NULL,
            stock_quantity INT NOT NULL DEFAULT 0
        )
        """)

        cursor.execute("""
        CREATE TABLE orders (
            order_id INT AUTO_INCREMENT PRIMARY KEY,
            customer_id INT NOT NULL,
            order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            total_amount DECIMAL(10, 2) NOT NULL,
            status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        )
        """)

        # Insert sample data into customers
        cursor.execute("""
        INSERT INTO customers (first_name, last_name, email) VALUES
        ('John', 'Doe', 'john.doe@example.com'),
        ('Jane', 'Smith', 'jane.smith@example.com'),
        ('Robert', 'Johnson', 'robert.johnson@example.com'),
        ('Emily', 'Williams', 'emily.williams@example.com'),
        ('Michael', 'Brown', 'michael.brown@example.com')
        """)

        # Insert sample data into products
        cursor.execute("""
        INSERT INTO products (product_name, description, price, stock_quantity) VALUES
        ('Laptop', 'High-performance laptop with 16GB RAM', 1299.99, 50),
        ('Smartphone', 'Latest model with 128GB storage', 899.99, 100),
        ('Headphones', 'Noise-cancelling wireless headphones', 249.99, 75),
        ('Tablet', '10-inch tablet with retina display', 499.99, 30),
        ('Smart Watch', 'Fitness tracking and notifications', 199.99, 60)
        """)

        # Insert sample data into orders
        cursor.execute("""
        INSERT INTO orders (customer_id, total_amount, status) VALUES
        (1, 1299.99, 'delivered'),
        (2, 899.99, 'shipped'),
        (3, 249.99, 'processing'),
        (4, 699.98, 'pending'),
        (5, 199.99, 'delivered'),
        (1, 499.99, 'shipped')
        """)

    # Commit the changes
    connection.commit()

def display_sample_data(connection):
    """Display sample data from the tables."""
    with connection.cursor(DictCursor) as cursor:
        # Show customers table
        print("\nCustomers Table:")
        cursor.execute("SELECT * FROM customers LIMIT 5")
        customers = cursor.fetchall()
        for customer in customers:
            print(customer)

        # Show products table
        print("\nProducts Table:")
        cursor.execute("SELECT * FROM products LIMIT 5")
        products = cursor.fetchall()
        for product in products:
            print(product)

        # Show orders table
        print("\nOrders Table:")
        cursor.execute("SELECT * FROM orders LIMIT 5")
        orders = cursor.fetchall()
        for order in orders:
            print(order)

        # Show JOIN example
        print("\nCustomer Orders:")
        cursor.execute("""
        SELECT
            c.first_name,
            c.last_name,
            o.order_id,
            o.total_amount,
            o.status
        FROM
            customers c
        JOIN
            orders o ON c.customer_id = o.customer_id
        LIMIT 10
        """)
        customer_orders = cursor.fetchall()
        for order in customer_orders:
            print(order)

def create_database_if_not_exists(host, user, password, db_name):
    """Create the database if it doesn't exist."""
    try:
        # Connect without specifying a database
        connection = pymysql.connect(
            host=host,
            user=user,
            password=password,
            charset='utf8mb4'
        )

        with connection.cursor() as cursor:
            # Check if database exists
            cursor.execute("SHOW DATABASES LIKE %s", (db_name,))
            result = cursor.fetchone()

            # If database doesn't exist, create it
            if not result:
                print(f"Database '{db_name}' does not exist. Creating it...")
                cursor.execute(f"CREATE DATABASE `{db_name}`")
                print(f"Database '{db_name}' created successfully.")
            else:
                print(f"Database '{db_name}' already exists.")

        connection.close()
        return True
    except pymysql.MySQLError as e:
        print(f"Error: Failed to create database: {e}")
        return False

def main():
    """Main function to execute the script."""
    check_requirements()

    print("Script to insert test data into RDS MySQL database")

    # Get connection details
    rds_endpoint, db_name, db_user, db_password = get_connection_details()

    # Confirm before proceeding
    print(f"You are about to reset and insert test data into database '{db_name}' at '{rds_endpoint}'")
    if not confirm_operation():
        print("Operation cancelled.")
        sys.exit(0)

    try:
        # Create database if it doesn't exist
        if not create_database_if_not_exists(rds_endpoint, db_user, db_password, db_name):
            print("Failed to create/verify database. Exiting.")
            sys.exit(1)

        # Connect to the database
        print("Connecting to database and executing SQL commands...")
        connection = pymysql.connect(
            host=rds_endpoint,
            user=db_user,
            password=db_password,
            database=db_name,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )

        # Execute SQL commands
        execute_sql_commands(connection)

        # Display sample data
        display_sample_data(connection)

        # Close the connection
        connection.close()

        print("\nSuccess! Test data has been inserted into the database.")
        print("Script completed successfully.")

    except pymysql.MySQLError as e:
        print(f"Error: MySQL error occurred: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

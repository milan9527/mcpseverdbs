#!/usr/bin/env python3

import sys
import boto3
import json
from botocore.exceptions import ClientError, BotoCoreError

# Aurora cluster configuration
RESOURCE_ARN = "arn:aws:rds:us-east-1:632930644527:cluster:mcpdemo"
SECRET_ARN = "arn:aws:secretsmanager:us-east-1:632930644527:secret:aurora/mcpdemo-QOU5uE"
DATABASE_NAME = None  # Will be determined at runtime

def check_requirements():
    """Check if required modules are installed."""
    try:
        import boto3
    except ImportError:
        print("Error: boto3 module is required but not installed.")
        print("Please install it using: pip install boto3")
        sys.exit(1)

def get_rds_data_client():
    """Create and return RDS Data Service client."""
    try:
        client = boto3.client('rds-data', region_name='us-east-1')
        return client
    except Exception as e:
        print(f"Error creating RDS Data client: {e}")
        sys.exit(1)

def execute_statement(client, sql, parameters=None, database=None):
    """Execute a SQL statement using RDS Data API."""
    try:
        request_params = {
            'resourceArn': RESOURCE_ARN,
            'secretArn': SECRET_ARN,
            'sql': sql
        }

        # Only include database if specified
        if database:
            request_params['database'] = database
        elif DATABASE_NAME:
            request_params['database'] = DATABASE_NAME

        if parameters:
            request_params['parameters'] = parameters

        response = client.execute_statement(**request_params)
        return response
    except ClientError as e:
        print(f"AWS Client Error: {e}")
        raise
    except Exception as e:
        print(f"Error executing SQL statement: {e}")
        raise

def execute_batch_statement(client, sql, parameter_sets, database=None):
    """Execute a batch SQL statement using RDS Data API."""
    try:
        request_params = {
            'resourceArn': RESOURCE_ARN,
            'secretArn': SECRET_ARN,
            'sql': sql,
            'parameterSets': parameter_sets
        }

        # Only include database if specified
        if database:
            request_params['database'] = database
        elif DATABASE_NAME:
            request_params['database'] = DATABASE_NAME

        response = client.batch_execute_statement(**request_params)
        return response
    except ClientError as e:
        print(f"AWS Client Error: {e}")
        raise
    except Exception as e:
        print(f"Error executing batch SQL statement: {e}")
        raise

def get_or_create_database(client):
    """Get available databases and create one if needed."""
    global DATABASE_NAME

    try:
        print("Checking available databases...")

        # List existing databases (without specifying a database)
        response = execute_statement(client, "SHOW DATABASES")

        databases = []
        if 'records' in response:
            for record in response['records']:
                db_name = record[0]['stringValue']
                # Skip system databases
                if db_name not in ['information_schema', 'mysql', 'performance_schema', 'sys']:
                    databases.append(db_name)

        print(f"Available databases: {databases}")

        if databases:
            # Use the first available database
            DATABASE_NAME = databases[0]
            print(f"Using existing database: {DATABASE_NAME}")
        else:
            # Create a new database
            DATABASE_NAME = "mcpdemo_testdb"
            print(f"Creating new database: {DATABASE_NAME}")
            execute_statement(client, f"CREATE DATABASE `{DATABASE_NAME}`")
            print(f"Database '{DATABASE_NAME}' created successfully.")

        return DATABASE_NAME

    except Exception as e:
        print(f"Error managing database: {e}")
        # Fallback: try to create a default database
        DATABASE_NAME = "mcpdemo_testdb"
        try:
            print(f"Attempting to create fallback database: {DATABASE_NAME}")
            execute_statement(client, f"CREATE DATABASE `{DATABASE_NAME}`")
            print(f"Fallback database '{DATABASE_NAME}' created successfully.")
            return DATABASE_NAME
        except Exception as create_error:
            print(f"Failed to create fallback database: {create_error}")
            raise
def confirm_operation():
    """Ask user for confirmation before proceeding."""
    print(f"You are about to reset and insert test data into Aurora cluster:")
    print(f"Resource ARN: {RESOURCE_ARN}")
    if DATABASE_NAME:
        print(f"Database: {DATABASE_NAME}")
    confirm = input("Continue? (y/n): ")
    return confirm.lower() in ['y', 'yes']

def create_tables(client):
    """Create tables using RDS Data API."""
    print("Creating tables...")

    # Drop tables if they exist
    drop_statements = [
        "DROP TABLE IF EXISTS orders",
        "DROP TABLE IF EXISTS customers",
        "DROP TABLE IF EXISTS products"
    ]

    for sql in drop_statements:
        execute_statement(client, sql)

    # Create customers table
    customers_sql = """
    CREATE TABLE customers (
        customer_id INT AUTO_INCREMENT PRIMARY KEY,
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """
    execute_statement(client, customers_sql)

    # Create products table
    products_sql = """
    CREATE TABLE products (
        product_id INT AUTO_INCREMENT PRIMARY KEY,
        product_name VARCHAR(100) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL,
        stock_quantity INT NOT NULL DEFAULT 0
    )
    """
    execute_statement(client, products_sql)

    # Create orders table
    orders_sql = """
    CREATE TABLE orders (
        order_id INT AUTO_INCREMENT PRIMARY KEY,
        customer_id INT NOT NULL,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        total_amount DECIMAL(10, 2) NOT NULL,
        status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    )
    """
    execute_statement(client, orders_sql)

    print("Tables created successfully.")

def insert_sample_data(client):
    """Insert sample data into tables using RDS Data API."""
    print("Inserting sample data...")

    # Insert customers data using batch execution
    customers_sql = "INSERT INTO customers (first_name, last_name, email) VALUES (:first_name, :last_name, :email)"
    customers_data = [
        [
            {'name': 'first_name', 'value': {'stringValue': 'John'}},
            {'name': 'last_name', 'value': {'stringValue': 'Doe'}},
            {'name': 'email', 'value': {'stringValue': 'john.doe@example.com'}}
        ],
        [
            {'name': 'first_name', 'value': {'stringValue': 'Jane'}},
            {'name': 'last_name', 'value': {'stringValue': 'Smith'}},
            {'name': 'email', 'value': {'stringValue': 'jane.smith@example.com'}}
        ],
        [
            {'name': 'first_name', 'value': {'stringValue': 'Robert'}},
            {'name': 'last_name', 'value': {'stringValue': 'Johnson'}},
            {'name': 'email', 'value': {'stringValue': 'robert.johnson@example.com'}}
        ],
        [
            {'name': 'first_name', 'value': {'stringValue': 'Emily'}},
            {'name': 'last_name', 'value': {'stringValue': 'Williams'}},
            {'name': 'email', 'value': {'stringValue': 'emily.williams@example.com'}}
        ],
        [
            {'name': 'first_name', 'value': {'stringValue': 'Michael'}},
            {'name': 'last_name', 'value': {'stringValue': 'Brown'}},
            {'name': 'email', 'value': {'stringValue': 'michael.brown@example.com'}}
        ]
    ]
    execute_batch_statement(client, customers_sql, customers_data)

    # Insert products data using batch execution
    products_sql = "INSERT INTO products (product_name, description, price, stock_quantity) VALUES (:product_name, :description, :price, :stock_quantity)"
    products_data = [
        [
            {'name': 'product_name', 'value': {'stringValue': 'Laptop'}},
            {'name': 'description', 'value': {'stringValue': 'High-performance laptop with 16GB RAM'}},
            {'name': 'price', 'value': {'doubleValue': 1299.99}},
            {'name': 'stock_quantity', 'value': {'longValue': 50}}
        ],
        [
            {'name': 'product_name', 'value': {'stringValue': 'Smartphone'}},
            {'name': 'description', 'value': {'stringValue': 'Latest model with 128GB storage'}},
            {'name': 'price', 'value': {'doubleValue': 899.99}},
            {'name': 'stock_quantity', 'value': {'longValue': 100}}
        ],
        [
            {'name': 'product_name', 'value': {'stringValue': 'Headphones'}},
            {'name': 'description', 'value': {'stringValue': 'Noise-cancelling wireless headphones'}},
            {'name': 'price', 'value': {'doubleValue': 249.99}},
            {'name': 'stock_quantity', 'value': {'longValue': 75}}
        ],
        [
            {'name': 'product_name', 'value': {'stringValue': 'Tablet'}},
            {'name': 'description', 'value': {'stringValue': '10-inch tablet with retina display'}},
            {'name': 'price', 'value': {'doubleValue': 499.99}},
            {'name': 'stock_quantity', 'value': {'longValue': 30}}
        ],
        [
            {'name': 'product_name', 'value': {'stringValue': 'Smart Watch'}},
            {'name': 'description', 'value': {'stringValue': 'Fitness tracking and notifications'}},
            {'name': 'price', 'value': {'doubleValue': 199.99}},
            {'name': 'stock_quantity', 'value': {'longValue': 60}}
        ]
    ]
    execute_batch_statement(client, products_sql, products_data)

    # Insert orders data using batch execution
    orders_sql = "INSERT INTO orders (customer_id, total_amount, status) VALUES (:customer_id, :total_amount, :status)"
    orders_data = [
        [
            {'name': 'customer_id', 'value': {'longValue': 1}},
            {'name': 'total_amount', 'value': {'doubleValue': 1299.99}},
            {'name': 'status', 'value': {'stringValue': 'delivered'}}
        ],
        [
            {'name': 'customer_id', 'value': {'longValue': 2}},
            {'name': 'total_amount', 'value': {'doubleValue': 899.99}},
            {'name': 'status', 'value': {'stringValue': 'shipped'}}
        ],
        [
            {'name': 'customer_id', 'value': {'longValue': 3}},
            {'name': 'total_amount', 'value': {'doubleValue': 249.99}},
            {'name': 'status', 'value': {'stringValue': 'processing'}}
        ],
        [
            {'name': 'customer_id', 'value': {'longValue': 4}},
            {'name': 'total_amount', 'value': {'doubleValue': 699.98}},
            {'name': 'status', 'value': {'stringValue': 'pending'}}
        ],
        [
            {'name': 'customer_id', 'value': {'longValue': 5}},
            {'name': 'total_amount', 'value': {'doubleValue': 199.99}},
            {'name': 'status', 'value': {'stringValue': 'delivered'}}
        ],
        [
            {'name': 'customer_id', 'value': {'longValue': 1}},
            {'name': 'total_amount', 'value': {'doubleValue': 499.99}},
            {'name': 'status', 'value': {'stringValue': 'shipped'}}
        ]
    ]
    execute_batch_statement(client, orders_sql, orders_data)

    print("Sample data inserted successfully.")

def display_sample_data(client):
    """Display sample data from the tables."""
    print("\n" + "="*50)
    print("SAMPLE DATA FROM TABLES")
    print("="*50)

    # Show customers table
    print("\nCustomers Table:")
    print("-" * 30)
    response = execute_statement(client, "SELECT * FROM customers LIMIT 5")
    if 'records' in response:
        for record in response['records']:
            customer_id = record[0]['longValue'] if 'longValue' in record[0] else record[0]['stringValue']
            first_name = record[1]['stringValue']
            last_name = record[2]['stringValue']
            email = record[3]['stringValue']
            created_at = record[4]['stringValue']
            print(f"ID: {customer_id}, Name: {first_name} {last_name}, Email: {email}, Created: {created_at}")

    # Show products table
    print("\nProducts Table:")
    print("-" * 30)
    response = execute_statement(client, "SELECT * FROM products LIMIT 5")
    if 'records' in response:
        for record in response['records']:
            product_id = record[0]['longValue'] if 'longValue' in record[0] else record[0]['stringValue']
            product_name = record[1]['stringValue']
            description = record[2]['stringValue']
            price = record[3]['doubleValue'] if 'doubleValue' in record[3] else record[3]['stringValue']
            stock = record[4]['longValue'] if 'longValue' in record[4] else record[4]['stringValue']
            print(f"ID: {product_id}, Name: {product_name}, Price: ${price}, Stock: {stock}")

    # Show orders table
    print("\nOrders Table:")
    print("-" * 30)
    response = execute_statement(client, "SELECT * FROM orders LIMIT 6")
    if 'records' in response:
        for record in response['records']:
            order_id = record[0]['longValue'] if 'longValue' in record[0] else record[0]['stringValue']
            customer_id = record[1]['longValue'] if 'longValue' in record[1] else record[1]['stringValue']
            order_date = record[2]['stringValue']
            total_amount = record[3]['doubleValue'] if 'doubleValue' in record[3] else record[3]['stringValue']
            status = record[4]['stringValue']
            print(f"Order ID: {order_id}, Customer: {customer_id}, Amount: ${total_amount}, Status: {status}")

    # Show JOIN example
    print("\nCustomer Orders (JOIN Example):")
    print("-" * 40)
    join_sql = """
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
    """
    response = execute_statement(client, join_sql)
    if 'records' in response:
        for record in response['records']:
            first_name = record[0]['stringValue']
            last_name = record[1]['stringValue']
            order_id = record[2]['longValue'] if 'longValue' in record[2] else record[2]['stringValue']
            total_amount = record[3]['doubleValue'] if 'doubleValue' in record[3] else record[3]['stringValue']
            status = record[4]['stringValue']
            print(f"{first_name} {last_name} - Order #{order_id}: ${total_amount} ({status})")

def main():
    """Main function to execute the script."""
    global DATABASE_NAME

    check_requirements()

    print("Script to insert test data into Aurora MySQL using Data API")
    print(f"Target Aurora Cluster: {RESOURCE_ARN}")

    try:
        # Get RDS Data client
        client = get_rds_data_client()

        # Get or create database
        DATABASE_NAME = get_or_create_database(client)

        # Confirm before proceeding
        if not confirm_operation():
            print("Operation cancelled.")
            sys.exit(0)

        # Create tables
        create_tables(client)

        # Insert sample data
        insert_sample_data(client)

        # Display sample data
        display_sample_data(client)

        print("\n" + "="*50)
        print("SUCCESS! Test data has been inserted into Aurora MySQL.")
        print(f"Database used: {DATABASE_NAME}")
        print("Script completed successfully.")
        print("="*50)

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        print(f"AWS Error ({error_code}): {error_message}")

        if error_code == 'BadRequestException':
            print("\nTroubleshooting tips:")
            print("- Verify the Aurora cluster is running and Data API is enabled")
            print("- Check that the resource ARN and secret ARN are correct")
            print("- Ensure your AWS credentials have the necessary permissions")
        elif error_code == 'DatabaseErrorException':
            print("\nDatabase Error - Possible causes:")
            print("- Database doesn't exist or name is incorrect")
            print("- Insufficient permissions to create/access database")
            print("- Aurora cluster may not be fully initialized")

        sys.exit(1)
    except Exception as e:
        print(f"Error: An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

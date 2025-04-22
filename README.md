# Database MCP Servers Setup Guide

This guide explains how to set up Model Context Protocol (MCP) servers for various AWS database services to use with Amazon Bedrock models.

## Supported Databases

- **Amazon RDS MySQL**: SQL database service
- **Amazon DocumentDB**: MongoDB-compatible document database
- **Amazon DynamoDB**: NoSQL key-value and document database
- **Amazon Redshift**: Data warehouse service
- **Amazon ElastiCache Redis**: In-memory data store

## Prerequisites

Before setting up the MCP servers, ensure you have:

1. Access to AWS services and appropriate permissions
2. Database instances already created and accessible
3. Node.js and npm installed
4. Python 3 installed
5. Git installed
6. Docker installed (optional, for containerized MCP servers)

You can check and install prerequisites using:

```bash
chmod +x check_prerequisites.sh
./check_prerequisites.sh
```

## Setup Process

### 1. Configure Database Credentials

Create a credentials file with your database connection information:

```bash
cp db_credentials_template.sh set_db_credentials.sh
```

Edit `set_db_credentials.sh` and fill in your actual database credentials.

### 2. Validate Database Connections

Before setting up the MCP servers, validate that your database connections work:

```bash
chmod +x validate_db_connections.sh
source ./set_db_credentials.sh
./validate_db_connections.sh
```

This script will test connections to all configured databases and report any issues.

### 3. Set Up MCP Servers

Run the secure setup script to install and configure all database MCP servers:

```bash
chmod +x setup_db_mcp_servers_secure.sh
./setup_db_mcp_servers_secure.sh
```

This script will:
- Clone necessary repositories
- Build required components
- Update the MCP configuration
- Restart the MCP services

### 4. Test MCP Servers

After setup, test that all MCP servers are working correctly:

```bash
chmod +x test_mcp_servers.sh
./test_mcp_servers.sh
```

## Usage Examples

Once the MCP servers are set up, you can use them with Amazon Bedrock models through the MCP framework. Here are some example prompts:

### MySQL

```
Show me all tables in the MySQL database.
Run a query to select the first 10 rows from the customers table.
What are the column names and data types in the orders table?
```

### MongoDB/DocumentDB

```
List all collections in the MongoDB database.
Find documents in the users collection where age is greater than 30.
Show me the schema of the products collection.
```

### DynamoDB

```
List all tables in DynamoDB.
Get items from the Orders table where CustomerId equals 'CUST001'.
What are the primary key attributes for the Products table?
```

### Redshift

```
Show me all tables in the Redshift database.
Run a query to analyze sales data by region.
Explain the schema of the customer_transactions table.
```

### Redis

```
Get all keys in Redis.
What is the value of the key 'session:user123'?
Show me all members of the set 'active_users'.
```

## Security Considerations

- Never commit credentials to version control
- Consider using AWS Secrets Manager or Parameter Store for credential management
- Use IAM roles instead of access keys when possible
- Implement least privilege access for database users
- Set appropriate read/write permissions in MCP server configurations

## Troubleshooting

If you encounter issues:

1. Check the logs in the `logs` directory
2. Verify database connectivity using the validation script
3. Ensure all required environment variables are set
4. Check that the MCP service is running (`http://127.0.0.1:7002`)
5. Verify that the Chatbot UI is accessible (`http://localhost:8502`)

## Additional Resources

- [MCP Protocol Documentation](https://github.com/modelcontextprotocol/servers)
- [Amazon Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Database Services](https://aws.amazon.com/products/databases/)

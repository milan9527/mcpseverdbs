#!/bin/bash

# Template for database credentials
# Copy this file to set_db_credentials.sh and fill in your actual credentials

# MySQL/RDS credentials
export MYSQL_HOST="your-mysql-host.region.rds.amazonaws.com"
export MYSQL_PORT="3306"
export MYSQL_USER="your-username"
export MYSQL_PASS="your-password"
export MYSQL_DB="your-database"
export ALLOW_INSERT_OPERATION="false"  # Set to "true" to allow inserts
export ALLOW_UPDATE_OPERATION="false"  # Set to "true" to allow updates
export ALLOW_DELETE_OPERATION="false"  # Set to "true" to allow deletes

# MongoDB/DocumentDB credentials
export MONGODB_URI="mongodb://username:password@your-docdb-cluster.region.docdb.amazonaws.com:27017/your-database?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"

# AWS credentials for DynamoDB
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_REGION="us-east-1"

# Redshift credentials
export REDSHIFT_URL="redshift://username:password@your-cluster.region.redshift.amazonaws.com:5439/your-database"

# Redis credentials
export REDIS_HOST="your-redis-cluster.region.cache.amazonaws.com"
export REDIS_PORT="6379"

echo "Database credentials have been set as environment variables."
echo "Now you can run ./setup_db_mcp_servers_secure.sh"

#!/bin/bash

# This script sets up MCP servers for various databases
# It requires environment variables to be set for sensitive credentials

echo "Setting up MCP servers for various databases..."

# Check if required environment variables are set
if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASS" ] || \
   [ -z "$MONGODB_URI" ] || [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || \
   [ -z "$REDSHIFT_URL" ] || [ -z "$REDIS_HOST" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please set the following environment variables:"
    echo "  MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB"
    echo "  MONGODB_URI"
    echo "  AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION"
    echo "  REDSHIFT_URL"
    echo "  REDIS_HOST, REDIS_PORT"
    exit 1
fi

# Create mcp directory if it doesn't exist
mkdir -p ~/mcp

# Clone Redis MCP server
echo "Cloning Redis MCP server..."
cd ~/mcp
if [ ! -d "mcp-redis" ]; then
    git clone https://github.com/redis/mcp-redis.git
else
    echo "mcp-redis directory already exists, skipping clone"
fi

# Clone Redshift MCP server
echo "Cloning Redshift MCP server..."
if [ ! -d "redshift-mcp-server" ]; then
    git clone https://github.com/paschmaria/redshift-mcp-server.git
    cd ~/mcp/redshift-mcp-server
    npm run build
else
    echo "redshift-mcp-server directory already exists, skipping clone"
    cd ~/mcp/redshift-mcp-server
    npm run build
fi

# Clone DynamoDB MCP server (assuming it needs to be cloned)
echo "Setting up DynamoDB MCP server..."
cd ~/mcp
if [ ! -d "dynamodb-mcp-server" ]; then
    git clone https://github.com/aws-samples/aws-mcp-servers-samples.git
    # Assuming dynamodb-mcp-server is part of this repo or needs to be set up separately
    # Add additional setup steps if needed
else
    echo "dynamodb-mcp-server directory already exists, skipping clone"
fi

# Update config.json with the provided MCP server configurations
echo "Updating config.json with MCP server configurations..."
cd ~/mcp/demo_mcp_on_amazon_bedrock

# Backup the original config file
cp conf/config.json conf/config.json.bak

# Now update the config file
python3 -c "
import json
import os

config_path = 'conf/config.json'
with open(config_path, 'r') as f:
    config = json.load(f)

# Add new MCP server configurations
new_configs = {
    'mcp_server_mysql': {
        'command': 'npx',
        'args': [
            '-y',
            '@benborla29/mcp-server-mysql'
        ],
        'env': {
            'MYSQL_HOST': os.environ.get('MYSQL_HOST', ''),
            'MYSQL_PORT': os.environ.get('MYSQL_PORT', '3306'),
            'MYSQL_USER': os.environ.get('MYSQL_USER', ''),
            'MYSQL_PASS': os.environ.get('MYSQL_PASS', ''),
            'MYSQL_DB': os.environ.get('MYSQL_DB', ''),
            'ALLOW_INSERT_OPERATION': os.environ.get('ALLOW_INSERT_OPERATION', 'true'),
            'ALLOW_UPDATE_OPERATION': os.environ.get('ALLOW_UPDATE_OPERATION', 'true'),
            'ALLOW_DELETE_OPERATION': os.environ.get('ALLOW_DELETE_OPERATION', 'true'),
            'PATH': '/usr/bin:/bin',
            'NODE_PATH': '/usr/lib/node_modules'
        },
        'description': 'MySQL Database with Write Access'
    },
    'mongodb': {
        'command': 'npx',
        'args': [
            '-y',
            '@pash1986/mcp-server-mongodb'
        ],
        'env': {
            'MONGODB_URI': os.environ.get('MONGODB_URI', '')
        },
        'description': 'MongoDB/DocumentDB Database'
    },
    'dynamodb': {
        'command': 'node',
        'args': [
            '/home/ec2-user/mcp/dynamodb-mcp-server/dist/index.js'
        ],
        'env': {
            'AWS_ACCESS_KEY_ID': os.environ.get('AWS_ACCESS_KEY_ID', ''),
            'AWS_SECRET_ACCESS_KEY': os.environ.get('AWS_SECRET_ACCESS_KEY', ''),
            'AWS_REGION': os.environ.get('AWS_REGION', 'us-east-1')
        },
        'description': 'Amazon DynamoDB'
    },
    'redshift-mcp': {
        'command': 'node',
        'args': [
            '/home/ec2-user/mcp/redshift-mcp-server/dist/index.js'
        ],
        'env': {
            'DATABASE_URL': os.environ.get('REDSHIFT_URL', '')
        },
        'description': 'Amazon Redshift Data Warehouse'
    },
    'redis': {
        'command': 'uv',
        'args': [
            '--directory',
            '/home/ec2-user/mcp/mcp-redis',
            'run',
            'src/main.py'
        ],
        'env': {
            'REDIS_HOST': os.environ.get('REDIS_HOST', ''),
            'REDIS_PORT': os.environ.get('REDIS_PORT', '6379')
        },
        'description': 'Redis Cache'
    }
}

# Update the mcpServers section with the new configurations
if 'mcpServers' in config:
    config['mcpServers'].update(new_configs)
else:
    config['mcpServers'] = new_configs

# Write the updated config back to the file
with open(config_path, 'w') as f:
    json.dump(config, f, indent=4)

print('Config file updated successfully!')
"

echo "Restarting MCP services..."
cd ~/mcp/demo_mcp_on_amazon_bedrock
./stop_all.sh
./start_all.sh

echo "Setup complete! MCP servers for databases are now configured and running."
echo "MySQL write operations (INSERT, UPDATE, DELETE) are enabled."

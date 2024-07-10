#!/bin/bash

LOG_FILE="/var/log/metabase_init.log"

echo "Starting metabase_init.sh" >> $LOG_FILE

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "Docker not found, installing Docker..."
    apt-get update && apt-get install -y docker.io
    if [ $? -ne 0 ]; then
        log "Failed to install Docker. Exiting."
        exit 1
    fi
fi

# Ensure Docker service is running
systemctl start docker
systemctl enable docker

# Pull the Metabase Docker image
log "Pulling Metabase Docker image..."
if ! docker pull metabase/metabase; then
    log "Failed to pull Metabase image. Exiting."
    exit 1
fi

# Run Metabase Docker container
log "Starting Metabase container..."
if ! docker run -d -p 3000:3000 --name metabase \
    -v /opt/metabase:/metabase-data \
    metabase/metabase; then
    log "Failed to start Metabase container. Exiting."
    exit 1
fi

# Install jq if not present
if ! command -v jq &> /dev/null; then
    log "Installing jq..."
    apt-get update && apt-get install -y jq
fi

# Function to check if Metabase is ready
wait_for_metabase() {
    log "Waiting for Metabase to start..."
    while ! curl -s http://localhost:3000/api/health | grep -q "ok"; do
        sleep 10
    done
    log "Metabase is ready!"
}

# Wait for Metabase to start
wait_for_metabase

# Get setup token
log "Getting setup token..."
SETUP_TOKEN=$(curl -s -m 5 -X GET \
    -H "Content-Type: application/json" \
    http://localhost:3000/api/session/properties \
    | jq -r '.["setup-token"]')

if [ -z "$SETUP_TOKEN" ]; then
    log "Failed to get setup token. Exiting."
    exit 1
fi

# Set up admin account
log "Setting up admin account..."
SETUP_RESPONSE=$(curl -s -X POST http://localhost:3000/api/setup \
    -H "Content-Type: application/json" \
    -d '{
        "token": "'$SETUP_TOKEN'",
        "user": {
            "first_name": "augusto",
            "last_name": "kark",
            "email": "av.kark@alumno.um.edu.ar",
            "password": "'"${metabase_password}"'",
            "password_confirm": "'"${metabase_password}"'"
        },
        "prefs": {
            "site_name": "UM",
            "site_locale": "en"
        }
    }')

log "Setup response: $SETUP_RESPONSE"

# Get session token
log "Getting session token..."
SESSION_TOKEN=$(curl -s -X POST http://localhost:3000/api/session \
    -H "Content-Type: application/json" \
    -d '{
        "username": "av.kark@alumno.um.edu.ar",
        "password": "'"${metabase_password}"'"
    }' | jq -r '.id')

if [ -z "$SESSION_TOKEN" ]; then
    log "Failed to get session token. Exiting."
    exit 1
fi

# Add database connection
log "Adding database connection..."
DB_ID=$(curl -s -X POST http://localhost:3000/api/database \
    -H "Content-Type: application/json" \
    -H "X-Metabase-Session: $SESSION_TOKEN" \
    -d '{
        "is_on_demand": false,
        "is_full_sync": true,
        "is_sample": false,
        "cache_ttl": null,
        "refingerprint": false,
        "auto_run_queries": true,
        "schedules": {},
        "details": {
            "host": "'"${db_host}"'",
            "port": 3306,
            "dbname": "'"${db_name}"'",
            "user": "'"${db_user}"'",
            "password": "'"${db_password}"'",
            "ssl": false,
            "tunnel-enabled": false,
            "advanced-options": false
        },
        "name": "mobility",
        "engine": "mysql"
    }' | jq -r '.id')

if [ -z "$DB_ID" ]; then
    log "Failed to add database connection. Exiting."
    exit 1
fi

# Create dashboard
log "Creating dashboard..."
DASHBOARD_ID=$(curl -s -X POST http://localhost:3000/api/dashboard \
    -H "Content-Type: application/json" \
    -H "X-Metabase-Session: $SESSION_TOKEN" \
    -d '{
        "name": "Mobility Dashboard",
        "description": "Mobility data for Mendoza Province, Capital Department"
    }' | jq -r '.id')

if [ -z "$DASHBOARD_ID" ]; then
    log "Failed to create dashboard. Exiting."
    exit 1
fi

# Create question with the provided SQL
log "Creating question..."
QUESTION_ID=$(curl -s -X POST http://localhost:3000/api/card \
    -H "Content-Type: application/json" \
    -H "X-Metabase-Session: $SESSION_TOKEN" \
    -d '{
        "name": "average mendoza",
        "type": "question",
        "dataset_query": {
            "database": '"$DB_ID"',
            "type": "query",
            "query": {
                "source-table": 9,
                "aggregation": [
                    ["avg", ["field", 83, {"base-type": "type/Integer"}]],
                    ["avg", ["field", 81, {"base-type": "type/Integer"}]],
                    ["avg", ["field", 72, {"base-type": "type/Integer"}]],
                    ["avg", ["field", 80, {"base-type": "type/Integer"}]],
                    ["avg", ["field", 78, {"base-type": "type/Integer"}]],
                    ["avg", ["field", 86, {"base-type": "type/Integer"}]]
                ],
                "breakout": [["field", 73, {"base-type": "type/DateTime", "temporal-unit": "day"}]],
                "filter": ["and",
                    ["=", ["field", 85, {"base-type": "type/Text"}], "Mendoza Province"],
                    ["=", ["field", 75, {"base-type": "type/Text"}], "Capital Department"],
                    ["between", ["field", 73, {"base-type": "type/DateTime"}], "2020-01-01", "2020-12-31"]
                ]
            }
        },
        "display": "area",
        "description": null,
        "visualization_settings": {
            "stackable.stack_type": null,
            "graph.dimensions": ["date"],
            "graph.metrics": ["avg", "avg_2", "avg_3", "avg_4", "avg_5", "avg_6"]
        },
        "collection_id": null,
        "collection_position": null,
        "result_metadata": [
            {"description": null, "semantic_type": null, "coercion_strategy": null, "unit": "day", "name": "date", "settings": null, "fk_target_field_id": null, "field_ref": ["field", 73, {"base-type": "type/DateTime", "temporal-unit": "day"}], "effective_type": "type/Date", "id": 73, "visibility_type": "normal", "display_name": "Date", "fingerprint": {"global": {"distinct-count": 321, "nil%": 0},

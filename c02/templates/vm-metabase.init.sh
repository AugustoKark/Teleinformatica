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
            "email": "'"${admin_email}"'",
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
        "username": "'"${admin_email}"'",
        "password": "'"${metabase_password}"'"
    }' | jq -r '.id')

if [ -z "$SESSION_TOKEN" ]; then
    log "Failed to get session token. Exiting."
    exit 1
fi

# # Add database connection
# log "Adding database connection..."
# DB_ID=$(curl -s -X POST http://localhost:3000/api/database \
#     -H "Content-Type: application/json" \
#     -H "X-Metabase-Session: $SESSION_TOKEN" \
#     -d '{
#         "is_on_demand": false,
#         "is_full_sync": true,
#         "is_sample": false,
#         "cache_ttl": null,
#         "refingerprint": false,
#         "auto_run_queries": true,
#         "schedules": {},
#         "details": {
#             "host": "'"${db_host}"'",
#             "port": 3306,
#             "dbname": "'"${db_name}"'",
#             "user": "'"${db_user}"'",
#             "password": "'"${db_password}"'",
#             "ssl": false,
#             "tunnel-enabled": false,
#             "advanced-options": false
#         },
#         "name": "mobility",
#         "engine": "mysql"
#     }' | jq -r '.id')

# if [ -z "$DB_ID" ]; then
#     log "Failed to add database connection. Exiting."
#     exit 1
# fi

# # Create dashboard
# log "Creating dashboard..."
# DASHBOARD_ID=$(curl -s -X POST http://localhost:3000/api/dashboard \
#     -H "Content-Type: application/json" \
#     -H "X-Metabase-Session: $SESSION_TOKEN" \
#     -d '{
#         "name": "Mobility Dashboard",
#         "description": "Mobility data for Mendoza Province, Capital Department"
#     }' | jq -r '.id')

# if [ -z "$DASHBOARD_ID" ]; then
#     log "Failed to create dashboard. Exiting."
#     exit 1
# fi

# Create question with the provided SQL
# log "Creating question..."
# QUESTION_ID=$(curl -s -X POST http://localhost:3000/api/card \
#     -H "Content-Type: application/json" \
#     -H "X-Metabase-Session: $SESSION_TOKEN" \
#     -d '{"name":"AugustoFilter","type":"question","dataset_query":{"database":'"$DB_ID"',"type":"query","query":{"source-table":9,"aggregation":[["avg",["field",83,{"base-type":"type/Integer"}]],["avg",["field",81,{"base-type":"type/Integer"}]],["distinct",["field",72,{"base-type":"type/Integer"}]],["avg",["field",80,{"base-type":"type/Integer"}]],["avg",["field",78,{"base-type":"type/Integer"}]],["avg",["field",86,{"base-type":"type/Integer"}]]],"breakout":[["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}]],"filter":["and",["=",["field",85,{"base-type":"type/Text"}],"Mendoza Province"],["=",["field",75,{"base-type":"type/Text"}],"Capital Department"],["between",["field",73,{"base-type":"type/DateTime"}],"2020-01-01","2021-12-31"]]}},"display":"area","description":null,"visualization_settings":{"stackable.stack_type":null,"graph.dimensions":["date"],"graph.metrics":["avg","avg_2","count","avg_3","avg_4","avg_5"]},"collection_id":null,"collection_position":null,"result_metadata":[{"description":null,"semantic_type":null,"coercion_strategy":null,"unit":"day","name":"date","settings":null,"fk_target_field_id":null,"field_ref":["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}],"effective_type":"type/Date","id":73,"visibility_type":"normal","display_name":"Date","fingerprint":{"global":{"distinct-count":321,"nil%":0},"type":{"type/DateTime":{"earliest":"2020-02-15T00:00:00Z","latest":"2020-12-31T00:00:00Z"}}},"base_type":"type/Date"},{"display_name":"Average of Retail And Recreation Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",0],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg","fingerprint":{"global":{"distinct-count":121,"nil%":0},"type":{"type/Number":{"min":-96,"q1":-54.501173574994326,"q3":-14.413732654605337,"max":41,"sd":28.429270359453263,"avg":-35.57725947521866}}}},{"display_name":"Average of Grocery And Pharmacy Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",1],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_2","fingerprint":{"global":{"distinct-count":145,"nil%":0},"type":{"type/Number":{"min":-91,"q1":-17.141478882874143,"q3":24.863232743416326,"max":125,"sd":31.876395018904773,"avg":3.865889212827989}}}},{"display_name":"Distinct values of Parks Percent Change From Baseline","semantic_type":"type/Quantity","settings":null,"field_ref":["aggregation",2],"base_type":"type/BigInteger","effective_type":"type/BigInteger","name":"count","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1,"q1":1,"q3":1,"max":1,"sd":0,"avg":1}}}},{"display_name":"Average of Transit Stations Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",3],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_3","fingerprint":{"global":{"distinct-count":111,"nil%":0},"type":{"type/Number":{"min":-90,"q1":-49.043913155226676,"q3":-17.454915028125264,"max":29,"sd":23.911622786978146,"avg":-33.01603498542274}}}},{"display_name":"Average of Workplaces Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",4],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_4","fingerprint":{"global":{"distinct-count":114,"nil%":0},"type":{"type/Number":{"min":-83,"q1":-21.095426438662365,"q3":7.588578852617459,"max":41,"sd":26.248078564520227,"avg":-7.067055393586005}}}},{"display_name":"Average of Residential Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",5],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_5","fingerprint":{"global":{"distinct-count":42,"nil%":0},"type":{"type/Number":{"min":-3,"q1":4.299847084432539,"q3":16.58257569495584,"max":40,"sd":8.448040846214184,"avg":10.650145772594753}}}}]}'
#      | jq -r '.id')


# # curl 'http://192.168.3.188/api/card' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0' -H 'Accept: application/json' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/json' -H 'Origin: http://192.168.3.188' -H 'Connection: keep-alive' -H 'Referer: http://192.168.3.188/question' -H 'Cookie: metabase.DEVICE=631617bc-e877-4ceb-8770-cb535fae162f; metabase.TIMEOUT=alive; metabase.SESSION=328c7a10-48db-444d-8bbe-24ff57ed2475' -H 'Priority: u=1' --data-raw '{"name":"AugustoFilter","type":"question","dataset_query":{"database":2,"type":"query","query":{"source-table":9,"aggregation":[["avg",["field",83,{"base-type":"type/Integer"}]],["avg",["field",81,{"base-type":"type/Integer"}]],["distinct",["field",72,{"base-type":"type/Integer"}]],["avg",["field",80,{"base-type":"type/Integer"}]],["avg",["field",78,{"base-type":"type/Integer"}]],["avg",["field",86,{"base-type":"type/Integer"}]]],"breakout":[["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}]],"filter":["and",["=",["field",85,{"base-type":"type/Text"}],"Mendoza Province"],["=",["field",75,{"base-type":"type/Text"}],"Capital Department"],["between",["field",73,{"base-type":"type/DateTime"}],"2020-01-01","2021-12-31"]]}},"display":"area","description":null,"visualization_settings":{"stackable.stack_type":null,"graph.dimensions":["date"],"graph.metrics":["avg","avg_2","count","avg_3","avg_4","avg_5"]},"collection_id":null,"collection_position":null,"result_metadata":[{"description":null,"semantic_type":null,"coercion_strategy":null,"unit":"day","name":"date","settings":null,"fk_target_field_id":null,"field_ref":["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}],"effective_type":"type/Date","id":73,"visibility_type":"normal","display_name":"Date","fingerprint":{"global":{"distinct-count":321,"nil%":0},"type":{"type/DateTime":{"earliest":"2020-02-15T00:00:00Z","latest":"2020-12-31T00:00:00Z"}}},"base_type":"type/Date"},{"display_name":"Average of Retail And Recreation Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",0],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg","fingerprint":{"global":{"distinct-count":121,"nil%":0},"type":{"type/Number":{"min":-96,"q1":-54.501173574994326,"q3":-14.413732654605337,"max":41,"sd":28.429270359453263,"avg":-35.57725947521866}}}},{"display_name":"Average of Grocery And Pharmacy Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",1],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_2","fingerprint":{"global":{"distinct-count":145,"nil%":0},"type":{"type/Number":{"min":-91,"q1":-17.141478882874143,"q3":24.863232743416326,"max":125,"sd":31.876395018904773,"avg":3.865889212827989}}}},{"display_name":"Distinct values of Parks Percent Change From Baseline","semantic_type":"type/Quantity","settings":null,"field_ref":["aggregation",2],"base_type":"type/BigInteger","effective_type":"type/BigInteger","name":"count","fingerprint":{"global":{"distinct-count":1,"nil%":0},"type":{"type/Number":{"min":1,"q1":1,"q3":1,"max":1,"sd":0,"avg":1}}}},{"display_name":"Average of Transit Stations Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",3],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_3","fingerprint":{"global":{"distinct-count":111,"nil%":0},"type":{"type/Number":{"min":-90,"q1":-49.043913155226676,"q3":-17.454915028125264,"max":29,"sd":23.911622786978146,"avg":-33.01603498542274}}}},{"display_name":"Average of Workplaces Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",4],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_4","fingerprint":{"global":{"distinct-count":114,"nil%":0},"type":{"type/Number":{"min":-83,"q1":-21.095426438662365,"q3":7.588578852617459,"max":41,"sd":26.248078564520227,"avg":-7.067055393586005}}}},{"display_name":"Average of Residential Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",5],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_5","fingerprint":{"global":{"distinct-count":42,"nil%":0},"type":{"type/Number":{"min":-3,"q1":4.299847084432539,"q3":16.58257569495584,"max":40,"sd":8.448040846214184,"avg":10.650145772594753}}}}]}'



# log "Question creada en teoria"

# if [ -z "$QUESTION_ID" ]; then
#     log "Failed to create question. Exiting."
#     exit 1
# fi
# Add database connection
log "Adding database connection..."
DB_ID=$(curl -X POST http://localhost:3000/api/database \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"is_on_demand":false,"is_full_sync":true,"is_sample":false,"cache_ttl":null,"refingerprint":false,"auto_run_queries":true,"schedules":{},"details":{"host":"'${db_host}'","port":3306,"dbname":"'${db_name}'","user":"'${db_user}'","password":"'${db_password}'","ssl":false,"tunnel-enabled":false,"advanced-options":false},"name":"mobility","engine":"mysql"}' | jq -r '.id')

if [ -z "$DB_ID" ]; then
    log "Failed to add database connection. Exiting."
    exit 1
fi

# Create dashboard
log "Creating dashboard..."
DASHBOARD_ID=$(curl -X POST http://localhost:3000/api/dashboard \
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
QUESTION_ID=$(curl -X POST http://localhost:3000/api/card \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: $SESSION_TOKEN" \
  -d '{"name":"average mendoza","type":"question","dataset_query":{"database": '"$DB_ID"',"type":"query","query":{"source-table":9,"aggregation":[["avg",["field",83,{"base-type":"type/Integer"}]],["avg",["field",81,{"base-type":"type/Integer"}]],["avg",["field",72,{"base-type":"type/Integer"}]],["avg",["field",80,{"base-type":"type/Integer"}]],["avg",["field",78,{"base-type":"type/Integer"}]],["avg",["field",86,{"base-type":"type/Integer"}]]],"breakout":[["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}]],"filter":["and",["=",["field",85,{"base-type":"type/Text"}],"Mendoza Province"],["=",["field",75,{"base-type":"type/Text"}],"Capital Department"],["between",["field",73,{"base-type":"type/DateTime"}],"2020-01-01","2020-12-31"]]}},"display":"area","description":null,"visualization_settings":{"stackable.stack_type":null,"graph.dimensions":["date"],"graph.metrics":["avg","avg_2","avg_3","avg_4","avg_5","avg_6"]},"collection_id":null,"collection_position":null,"result_metadata":[{"description":null,"semantic_type":null,"coercion_strategy":null,"unit":"day","name":"date","settings":null,"fk_target_field_id":null,"field_ref":["field",73,{"base-type":"type/DateTime","temporal-unit":"day"}],"effective_type":"type/Date","id":73,"visibility_type":"normal","display_name":"Date","fingerprint":{"global":{"distinct-count":321,"nil%":0},"type":{"type/DateTime":{"earliest":"2020-02-15T00:00:00Z","latest":"2020-12-31T00:00:00Z"}}},"base_type":"type/Date"},{"display_name":"Average of Retail And Recreation Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",0],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg","fingerprint":{"global":{"distinct-count":95,"nil%":0},"type":{"type/Number":{"min":-96,"q1":-69.0857716560905,"q3":-42.84139629549865,"max":41,"sd":27.658547670628238,"avg":-52.29283489096573}}}},{"display_name":"Average of Grocery And Pharmacy Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",1],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_2","fingerprint":{"global":{"distinct-count":101,"nil%":0},"type":{"type/Number":{"min":-91,"q1":-30.805717884568125,"q3":0.5971624461628744,"max":83,"sd":26.054557250362603,"avg":-16.31152647975078}}}},{"display_name":"Average of Parks Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",2],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_3","fingerprint":{"global":{"distinct-count":94,"nil%":0},"type":{"type/Number":{"min":-99,"q1":-90.42656981021216,"q3":-50.86001194493218,"max":59,"sd":32.48307885753726,"avg":-60.49844236760124}}}},{"display_name":"Average of Transit Stations Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",3],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_4","fingerprint":{"global":{"distinct-count":86,"nil%":0},"type":{"type/Number":{"min":-90,"q1":-56.375,"q3":-39.62201759733446,"max":29,"sd":23.83605137258345,"avg":-45.16822429906542}}}},{"display_name":"Average of Workplaces Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",4],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_5","fingerprint":{"global":{"distinct-count":91,"nil%":0},"type":{"type/Number":{"min":-83,"q1":-29.76356457060072,"q3":-6.708333333333333,"max":33,"sd":24.104273707172357,"avg":-21.40809968847352}}}},{"display_name":"Average of Residential Percent Change From Baseline","semantic_type":null,"settings":null,"field_ref":["aggregation",5],"base_type":"type/Decimal","effective_type":"type/Decimal","name":"avg_6","fingerprint":{"global":{"distinct-count":42,"nil%":0},"type":{"type/Number":{"min":-3,"q1":11.41332798286476,"q3":20.054308789731966,"max":40,"sd":8.746244187259899,"avg":16.009345794392523}}}}]}' | jq -r '.id')

if [ -z "$QUESTION_ID" ]; then
    log "Failed to create question. Exiting."
    exit 1
fi
#!/bin/bash

export PGHOST="postgres"
export PGUSER="postgres"
export PGPASSWORD="polyflix"
export PGDATABASE="usermanagement"

export POLYFLIX_API="http://gateway"

export KEYCLOAK_HOST="http://keycloak"
export KEYCLOAK_REALM="Polyflix"
export KEYCLOAK_ADMIN_USER="polyflix"
export KEYCLOAK_ADMIN_PASSWORD="polyflix"

export KAFKA_BOOTSTRAP_SERVERS="kafka-0.kafka-headless:9092"
export KAFKA_KEYCLOAK_TOPIC="polyflix.keycloak.user"

CURL_COMMON_ARGS="-sf"

# Authenticate to Keycloak using the administrator account and retrieve an access token.
function kc_admin_token() {
    curl "${CURL_COMMON_ARGS}" -X POST "${KEYCLOAK_HOST}/realms/master/protocol/openid-connect/token" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "username=${KEYCLOAK_ADMIN_USER}" \
        --data-urlencode "password=${KEYCLOAK_ADMIN_PASSWORD}" \
        --data-urlencode 'grant_type=password' \
        --data-urlencode 'client_id=admin-cli' \
        | jq -r ".access_token"
}

# Authenticate a specific user to the Keycloak Realm
function kc_user_token() {
    local role=$1
    curl "${CURL_COMMON_ARGS}" -X POST "${KEYCLOAK_HOST}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token" \
            -H 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode "username=${role}@polyflix.local" \
            --data-urlencode "password=${role}" \
            --data-urlencode 'grant_type=password' \
            --data-urlencode 'client_id=admin-cli' \
            | jq -r '.access_token'
}

# Create a user using the Keycloak admin API
function kc_create_user() {
    local role=$1
    curl "${CURL_COMMON_ARGS}" -X POST "${KEYCLOAK_HOST}/admin/realms/${KEYCLOAK_REALM}/users" \
        -H "Content-Type: application/json" \
        --header "Authorization: Bearer $(kc_admin_token)" \
        --data-raw "
            {
                \"firstName\": \"polyflix\",
                \"lastName\": \"${role}\",
                \"email\": \"${role}@polyflix.local\",
                \"username\": \"${role}\",
                \"enabled\": \"true\",
                \"credentials\":[
                    {
                        \"type\":\"password\",
                        \"value\":\"${role}\",
                        \"temporary\": \"false\"
                    }
                ]
            }"
}

# Retrieve a user by username for the current Realm
function kc_get_user() {
    local role=$1
    curl "${CURL_COMMON_ARGS}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KEYCLOAK_REALM}/users" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer $(kc_admin_token)" | jq -c ".[] | select(.username | contains(\"$role\"))"
}

function kafka_dispatch_user() {
    local id=$(echo "$1" | jq -r '.id')
    local email=$(echo "$1" | jq -r '.email')
    local firstName=$(echo "$1" | jq -r '.firstName')
    local lastName=$(echo "$1" | jq -r '.lastName')
    local username=$(echo "$1" | jq -r '.username')

    local payload=$(jq -c --null-input \
        --arg id "$id" \
        --arg email "$email" \
        --arg firstName "$firstName" \
        --arg lastName "$lastName" \
        --arg username "$username" \
        '{"trigger": "CREATE", "data": {"id": $id, "email": $email, "firstName": $firstName, "lastName": $lastName, "username": $username}}')

    echo "$payload" | kafka-console-producer.sh --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" --topic "${KAFKA_KEYCLOAK_TOPIC}"
}

function register_user() {
    echo "Provisioning user '$1'..."
    kc_create_user "$1"
    kafka_dispatch_user $(kc_get_user "$1")
    # Update the roles of the user
    psql -c "INSERT INTO users_roles VALUES ((SELECT id from users where \"email\" = '$1@polyflix.local'), (SELECT id as roleId from roles where LOWER(name) = '$1'))"
}

function polyflix_create_youtube_video() {
    local role=$1
    local url=$2
    local title=$3
    local thumbnail=$4

    echo "Sending POST request for video '$title'"
    curl "${CURL_COMMON_ARGS}" -X POST "${POLYFLIX_API}/api/v2.0.0/videos" \
        -H "Content-Type: application/json" \
        --header "Authorization: Bearer $(kc_user_token $role)" \
        --data-raw "
            {
                \"source\": \"$url\",
                \"thumbnail\": \"$thumbnail\",
                \"title\": \"$title\",
                \"visibility\": \"public\",
                \"description\": \"This video was provisioned during the environment bootstrap.\",
                \"draft\": \"false\"
            }"
}

echo "Seeding environment with users (1/2)"
register_user "administrator"
register_user "contributor"
register_user "member"

echo "Seeding environment with videos (2/2)"
polyflix_create_youtube_video "administrator" "https://www.youtube.com/watch?v=uvb00oaa3k8" "Kafka in 100 Seconds" "https://i.ytimg.com/vi/uvb00oaa3k8/hqdefault.jpg"
polyflix_create_youtube_video "administrator" "https://www.youtube.com/watch?v=hdHjjBS4cs8" "Brainf**k in 100 Seconds" "https://i.ytimg.com/vi/hdHjjBS4cs8/hqdefault.jpg"
polyflix_create_youtube_video "administrator" "https://www.youtube.com/watch?v=zBZgdTb-dns" "Supabase in 100 Seconds" "https://i.ytimg.com/vi/zBZgdTb-dns/hqdefault.jpg"
polyflix_create_youtube_video "contributor" "https://www.youtube.com/watch?v=QKgTZWbwD1U" "Godot in 100 Seconds" "https://i.ytimg.com/vi/QKgTZWbwD1U/hqdefault.jpg"
polyflix_create_youtube_video "contributor" "https://www.youtube.com/watch?v=rIfdg_Ot-LI" "Laravel in 100 Seconds" "https://i.ytimg.com/vi/rIfdg_Ot-LI/hqdefault.jpg"
polyflix_create_youtube_video "contributor" "https://www.youtube.com/watch?v=C7WFwgDRStM" "SurrealDB in 100 Seconds" "https://i.ytimg.com/vi/C7WFwgDRStM/hqdefault.jpg"


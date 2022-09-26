#!/bin/bash

# function
replace_in_file() {
    local filename="${1:?filename is required}"
    local match_regex="${2:?match regex is required}"
    local substitute_regex="${3:?substitute regex is required}"
    local posix_regex=${4:-true}

    local result

    # We should avoid using 'sed in-place' substitutions
    # 1) They are not compatible with files mounted from ConfigMap(s)
    # 2) We found incompatibility issues with Debian10 and "in-place" substitutions
    local -r del=$'\001' # Use a non-printable character as a 'sed' delimiter to avoid issues
    if [[ $posix_regex = true ]]; then
        result="$(sed -E "s${del}${match_regex}${del}${substitute_regex}${del}g" "$filename")"
    else
        result="$(sed "s${del}${match_regex}${del}${substitute_regex}${del}g" "$filename")"
    fi
    echo "$result" > "$filename"
}

# Kafka runtime settings
export KAFKA_BASE_DIR="/opt/kafka"
export KAFKA_CFG_LOG_DIRS="${KAFKA_LOG_DIR:-/var/lib/kafka}"

if [ -z ${KAFKA_CONF_FILE} ]; then
     export KAFKA_CONF_FILE="${KAFKA_BASE_DIR}/config/kraft/server.properties"
fi

if [ -z ${KAFKA_CLUSTER_ID} ]; then
     # RANDOM_UUID=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 22 | base64`
     export KAFKA_CLUSTER_ID="c893lCCXQcGD8xV9pCYRvg"
fi

export KAFKA_CFG_NODE_ID="${POD_NAME##*-}"

ID="${POD_NAME##*-}"
if [[ -f "${KAFKA_CFG_LOG_DIRS}/meta.properties" ]]; then
    export KAFKA_CFG_BROKER_ID="$(grep "node.id" ${KAFKA_CFG_LOG_DIRS}/meta.properties | awk -F '=' '{print $2}')"
else
    export KAFKA_CFG_BROKER_ID="${ID}"
fi


# Kafka configuration overrides
for env_var in `env|grep KAFKA_CFG_`; do
    Kafka_configuration_name=`echo ${env_var} |sed 's/=.*$//g' | sed  -e 's/^KAFKA_CFG_//g' -e  's/_/\./g' | tr '[:upper:]' '[:lower:]'`
    Kafka_configuration_value=$(eval echo \$$(echo ${env_var}| sed 's/=.*$//g'))

    # processing variables containing variables
    result=$(echo $Kafka_configuration_value | grep '\$')
    if [[ "$result" != "" ]] ; then
       Kafka_configuration_value=`eval echo ${Kafka_configuration_value}`
    fi


    # Check if the value was set before
    if grep -q "^[#\\s]*$Kafka_configuration_name\s*=.*" "${KAFKA_CONF_FILE}"; then
        # Update the existing key
        replace_in_file "${KAFKA_CONF_FILE}" "^[#\\s]*${Kafka_configuration_name}\s*=.*" "${Kafka_configuration_name}=${Kafka_configuration_value}" false
    else
        # Add a new key
        printf '\n%s=%s' "$Kafka_configuration_name" "$Kafka_configuration_value" >>"${KAFKA_CONF_FILE}"
    fi

done

# Kafka format
if [[ ! -f "${KAFKA_CFG_LOG_DIRS}/meta.properties" ]]; then
    ${KAFKA_BASE_DIR}/bin/kafka-storage.sh format -t ${KAFKA_CLUSTER_ID} -c ${KAFKA_CONF_FILE}
fi

# Java settings
export KAFKA_HEAP_OPTS="${KAFKA_HEAP_OPTS:--Xmx1024m -Xms1024m}"

# Starting Kafka
flags=("$KAFKA_CONF_FILE")
START_COMMAND=("$KAFKA_BASE_DIR/bin/kafka-server-start.sh" "${flags[@]}" "$@")

exec "${START_COMMAND[@]}"
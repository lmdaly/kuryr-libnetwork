#!/bin/bash

if [ ! -d /etc/kuryr ]; then
    mkdir -p /etc/kuryr
    cat > /etc/kuryr/kuryr.conf << EOF
[DEFAULT]

bindir = /usr/libexec/kuryr
capability_scope = $CAPABILITY_SCOPE

[neutron]
project_domain_name = $USER_DOMAIN_NAME
project_name = $SERVICE_PROJECT_NAME
user_domain_name = $SERVICE_DOMAIN_NAME
password = $SERVICE_PASSWORD
username = $SERVICE_USER
auth_url = $IDENTITY_URL
auth_type = password
EOF

fi

/usr/sbin/uwsgi \
    --plugin /usr/lib/uwsgi/python \
    --http-socket :23750 \
    -w kuryr_libnetwork.server:app \
    --master \
    --processes "$PROCESSES" \
    --threads "$THREADS"

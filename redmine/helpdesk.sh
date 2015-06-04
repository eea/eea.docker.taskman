#!/bin/bash

LOG_DIR=/var/log/helpdesk
REDMINE_PATH=/var/local/redmine

source /var/local/environment/vars

/usr/local/bin/bundle exec rake -f $REDMINE_PATH/Rakefile redmine:email:receive_imap RAILS_ENV="production" \
host=$H_EMAIL_HOST username=$H_EMAIL_USER password=$H_EMAIL_PASS ssl=$H_EMAIL_SSL port=$H_EMAIL_PORT folder=$H_EMAIL_FOLDER \
project=it-helpdesk move_on_success=processed move_on_failure=failed tracker=task no_permission_check=1 \
unknown_user=accept >> $LOG_DIR/helpdesk.log 2>&1

#!/bin/bash

LOG_DIR=/var/log/helpdesk
REDMINE_PATH=/var/local/redmine

source /var/local/environment/vars

/usr/local/bin/bundle exec rake -f $REDMINE_PATH/Rakefile redmine:email:receive_imap RAILS_ENV="production" \
host=$T_EMAIL_HOST username=$T_EMAIL_USER password=$T_EMAIL_PASS ssl=$T_EMAIL_SSL port=$T_EMAIL_PORT folder=$T_EMAIL_FOLDER \
project=it-helpdesk move_on_success=read move_on_failure=failed \
allow_override=project,tracker,priority,status,category,fixed_version >> $LOG_DIR/helpdesk.log 2>&1

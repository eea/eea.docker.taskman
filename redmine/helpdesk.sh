#!/bin/bash

LOG_DIR=/var/log/helpdesk
REDMINE_PATH=/var/local/redmine

#TODO replace with production values
EMAIL_HOST=host
EMAIL_USERNAME=user
EMAIL_PASSWORD=pass
EMAIL_FOLDER=Inbox

/usr/local/bin/bundle exec rake -f $REDMINE_PATH/Rakefile redmine:email:receive_imap RAILS_ENV="production" \
host=$EMAIL_HOST username=$EMAIL_USERNAME password=$EMAIL_PASSWORD port=143 folder=$EMAIL_FOLDER \
project=it-helpdesk move_on_success=read move_on_failure=failed \
allow_override=project,tracker,priority,assigned_to,status,category,fixed_version >> $LOG_DIR/helpdesk.log 2>&1

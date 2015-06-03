#!/bin/bash

LOG_DIR=/var/log/helpdesk
REDMINE_PATH=/var/local/redmine

#TODO replace with production values
EMAIL_HOST=host
PORT=143
SSL=false
EMAIL_USERNAME=user
EMAIL_PASSWORD=pass
EMAIL_FOLDER=Inbox

/usr/local/bin/bundle exec rake -f $REDMINE_PATH/Rakefile redmine:email:receive_imap RAILS_ENV="production" \
host=$EMAIL_HOST username=$EMAIL_USERNAME password=$EMAIL_PASSWORD ssl=$SSL port=$PORT folder=$EMAIL_FOLDER \
project=it-helpdesk move_on_success=processed move_on_failure=failed tracker=task no_permission_check=1 \
unknown_user=accept >> $LOG_DIR/helpdesk.log 2>&1

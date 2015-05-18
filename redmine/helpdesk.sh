!# /bin/bash

cd /var/local/redmine
bundle exec rake -f /var/local/redmine/Rakefile redmine:email:receive_imap RAILS_ENV="production" \
host=$REDMINE_EMAIL_HOST username=$REDMINE_EMAIL_USERNAME password=$REDMINE_EMAIL_PASSWORD port=143 folder=Inbox \
project=it-helpdesk move_on_success=read move_on_failure=failed \
allow_override=project,tracker,priority,assigned_to,status,category,fixed_version >> /var/log/httpd/cronapache.log 2>&1

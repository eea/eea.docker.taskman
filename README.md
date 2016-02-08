## EEA Taskman docker setup
Taskman is a web application based on [Redmine](http://www.redmine.org) that facilitates Agile project management for EEA and Eionet software projects. It comes with some plugins and specific Eionet redmine theme.

### Prerequisites

- Install [Docker](https://docs.docker.com/installation/)
- Install [Compose](https://docs.docker.com/compose/install/)

### First time installation

Clone the repository
    
    $ git clone https://github.com/eea/eea.docker.taskman
    $ cd eea.docker.taskman
    
During the first time deployement, create the secret environment files

    $ # copy the .secret.example files
    $ cp .mysql.secret.example .mysql.secret
    $ cp .redmine.secret.example .redmine.secret
    $ cp .postfix.secret.example .postfix.secret
    $ cp .memcached.secret.example .memcached.secret
    $ cp .email.secret.example .email.secret

Edit the secret files with real settings

    $ vim .mysql.secret
    $ vim .redmine.secret
    $ # edit email configuration for helpdesk and taskman accounts
    $ vim .email.secret
    $ # edit email configuration for redmine
    $ vim .postfix.secret
    $ # edit memcached configuration
    $ vim .memcached.secret

Follow [import existing data](#import-existing-data) if you need to import existing data

Start containers

    $ docker-compose up -d
    
Update the database
    
    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ # update database
    $ bundle exec rake db:migrate RAILS_ENV=production
    $ # update plugins
    $ bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    $ # Clean up - Clear the cache and the existing sessions
    $ bundle exec rake tmp:cache:clear tmp:sessions:clear RAILS_ENV=production
    
#### Import existing data

If you already have a normal redmine installation (not dockerised) than follow the steps below to import the files and mysql db into the data container.

Import files
    
    $ mkdir /var/data && cp -R /path/example/files/ data/
    $ docker run -it --rm --volumes-from eeadockertaskman_data_1 -v \
      /var/data/:/mnt debian /bin/bash -c \
      "cp -R /mnt/files /home/redmine/data/files && chown -R 500:500 /home/redmine/data/files"

Import database (replace db_production, user, pass with your values)
    
    $ docker-compose up -d mysql
    
    if you have a backup in tgz
    
    $ cp /path/database/dump.sql.tgz backup/
    $ docker exec -i eeadockertaskman_mysql_1 /bin/bash -c \
      "tar xvf /var/local/backup/dump.sql.tgz && mysql -u<mysql_user> -p<mysql_pass> <db_name> < dump.sql"
    $ docker-compose stop mysql
    
    or if you have a simple dump file
    
    $ cp /path/database/dump.sql backup/
    $ docker exec -i eeadockertaskman_mysql_1 /bin/bash -c \
      "mysql -u<mysql_user> -p<mysql_pass> <db_name> < /var/local/backup/dump.sql"
    $ docker-compose stop mysql
    
Start containers

    $ docker-compose up -d


### Upgrade procedure

make a backup of database

    $ docker exec eeadockertaskman_mysql_1 mysqldump -h localhost --add-drop-table redmine_production_db > redmine.sql
    
pull latest version of redmine so to minimize waiting time during the next step

    $ docker pull eeacms/redmine:<imagetag>
    
stop all servicies
    
    $ docker-compose stop

update repository
    
    $ git pull

start all
    
    $ docker-compose up -d

Finally go to "Admin -> Roles & permissions" to check/set permissions for the new features, if any.

Follow any other manual steps via redmine UI needed e.g. when adding new plugins.

## How-tos
### How to add repository to redmine

*Prerequisites*: You have "Manager"/"Product Owner"-role in your <Project>.

1. Within Redmine Web Interface > Projects > <Project> > Settings > Repositories add New repository

* SCM: Git
* Identifier: eea-mypackage
* Path to repository: /var/local/redmine/github/eea.mypackage.git
* "Read more":http://www.redmine.org/projects/redmine/wiki/HowTo_keep_in_sync_your_git_repository_for_redmine

2. Update users mapping for your new repository:
 
* Within Redmine Web Interface > Projects > <Project> > Settings > Repositories click on *Users* link available for your new repository and Update missing users

<pre>
All local repositories within */var/local/redmine/github* folder are synced automatically
from https://github.com/eea every 5 minutes (see */etc/cron.d/sync_git_repos* and
*/var/local/redmine/github/redmine.py*) so you don't have to add them manually on server side.
</pre>

If it still doesn't update automatically after a while:
* login to the docker host and become root
* enter the redmine container (docker exec -it eeadockertaskman_redmine_1 bash)
* cd /var/local/redmine/github
* git clone --mirror https://github.com/eea/eea.mypackage.git
* cd eea.mypackage.git
* git fetch --all
* chown -R apache.apache .

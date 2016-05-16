## EEA Taskman docker setup
Taskman is a web application based on [Redmine](http://www.redmine.org) that facilitates Agile project management for EEA and Eionet software projects. It comes with some plugins and specific Eionet redmine theme.

### Prerequisites

- Install [Docker](https://docs.docker.com/installation/)
- Install [Compose](https://docs.docker.com/compose/install/)

### First time installation

Clone the repository

    $ cd /var/local/deploy
    $ git clone https://github.com/eea/eea.docker.taskman
    $ cd eea.docker.taskman

During the first time deployement, create the secret environment files

    $ cp .mysql.secret.example .mysql.secret
    $ cp .redmine.secret.example .redmine.secret
    $ cp .memcached.secret.example .memcached.secret
    $ cp .postfix.secret.example .postfix.secret
    $ cp .email.secret.example .email.secret

Edit the secret files with real settings, email settings will be setup at the end

    $ vim .mysql.secret
    $ vim .redmine.secret
    $ vim .memcached.secret

Follow [import existing data](#import-existing-data) if you need to import existing data

Start Taskman servicies

    $ docker-compose up -d

[Start updating Taskman](#start-updating-taskman) if you updated the Redmine version or if you updated the Redmine's plugins.

#### Import existing data

If you already have a Taskman installation than follow the steps below to import the files and mysql db into the data containers.

##### Import Taskman files

Get existing files from production.

1. Start **rsync client** on host where do you want to migrate eggrepo data.

  ```
    $ docker-compose up data
    $ docker run -it --rm --name=r-client --volumes-from=eeadockertaskman_data_1 eeacms/rsync sh
  ```

2. Start **rsync server** on host from where do you want to migrate data.

  ```
    $ docker run -it --rm --name=r-server -p 2222:22 --volumes-from=eeadockertaskman_data_1 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" eeacms/rsync server
  ```

3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz root@<SOURCE HOST IP>:/home/redmine/data/ /home/redmine/data/
    $ rsync -e 'ssh -p 2222' -avz root@<SOURCE HOST IP>:/home/redmine/redmine/github/ /home/redmine/redmine/github/
  ```

4. Close **rsync client**

  ```
    $ CTRL+d
  ```

5. Close **rsync server**

  ```
    $ docker kill r-server
  ```

##### Import Taskman database

Replace the < MYSQL_DB_NAME >, < MYSQL_USER > and < MYSQL_PASSWORD > with your values.

Make a dump of the database (from production / < PRODUCTION_HOST >)

    $ #ssh on <PRODUCTION_HOST> with you local account
    $ docker exec eeadockertaskman_mysql_1 mysqldump -h localhost --add-drop-table <MYSQL_DB_NAME> > taskman.sql
    $ #copy the dump file to <NEW_HOST>
    $ scp -i /root/.ssh/<SSH_TASKMAN_IMPORT_KEY> /var/local/deploy/eea.docker.taskman/backup/taskman.sql root@<NEW_HOST>:<NEW_VOLUME_PATH>

Start the MySQL server

    $ docker-compose up -d mysql

Import the dump file

    $ cp <NEW_VOLUME_PATH>taskman.sql backup/
    $ docker exec -i eeadockertaskman_mysql_1 /bin/bash -c "mysql -u<MYSQL_USER> -p<MYSQL_PASSWORD> <MYSQL_DB_NAME> < /var/local/backup/taskman.sql"
    $ docker-compose stop mysql

#### Email settings

Edit email configuration for helpdesk and taskman accounts

    $ vim .email.secret

Edit email configuration for redmine

    $ vim .postfix.secret

IMPORTANT: test if the email notification are sent!

### Upgrade procedure

Make a backup of database

    $ docker exec eeadockertaskman_mysql_1 mysqldump -h localhost --add-drop-table <MYSQL_DB_NAME> > taskman.sql

Pull latest version of redmine so to minimize waiting time during the next step

    $ docker pull eeacms/redmine:<imagetag>

Stop all servicies

    $ docker-compose stop

Update repository

    $ git pull

Start all

    $ docker-compose up -d

#### Start updating Taskman

Start updating Taskman

    $ docker exec -it eeadockertaskman_redmine_1 bash

Run this only if you updated the Redmine version

    $ bundle exec rake db:migrate RAILS_ENV=production

Run this only if you updated the Redmine's plugins

    $ bundle exec rake redmine:plugins:migrate RAILS_ENV=production

Finnish updating taskman

    $ bundle exec rake tmp:cache:clear tmp:sessions:clear RAILS_ENV=production
    $ exit

### End of install/upgrade procedure(s)

For this final steps you will need help from a sys admin.

- close current production, follow [wiki here]( https://taskman.eionet.europa.eu/projects/infrastructure/wiki/How_To_Inform_on_Planned_Maintenance)
- re-run rsync files
- re-take mysql dump
- re-import mysql dump
- run upgrade commands if there is a new Redmine version
- start the new installation
- switch floating IP

Finally go to "Administration -> Roles & permissions" to check/set permissions for the new features, if any.

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

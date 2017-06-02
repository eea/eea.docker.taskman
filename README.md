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

1. Start **rsync client** on host from where do you want to migrate data (production)

  ```
    $ docker run -it --rm --name=r-client \
                 --volumes-from=eeadockertaskman_data_1 \
             eeacms/rsync sh
  ```

2. Start **rsync server** on host from where do you want to migrate data (devel)

  ```
    $ docker-compose up -d data
    $ docker run -it --rm --name=r-server -p 2222:22 \
                 --volumes-from=eeadockertaskman_data_1 \
                 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" \
             eeacms/rsync server
  ```

3. Within **rsync client** container from step 1 run:

  ```
    $ rsync -e 'ssh -p 2222' -avz /usr/src/redmine/files/ root@<TARGET_HOST_IP_ON_DEVEL>:/usr/src/redmine/files/
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

Replace the < MYSQL_ROOT_USER > and < MYSQL_ROOT_PASSWORD > with your values.

1. Make a dump of the database from production.

  ```
    $ docker exec -it eeadockertaskman_mysql_1 bash
      $ mysqldump -u<MYSQL_ROOT_USER> --add-drop-table redmine > ./backup/taskman.sql
      $ exit
  ```

2. Start **rsync client** on production

  ```
    $ docker run -it --rm --name=r-client \
                 --volumes-from=eeadockertaskman_mysql_1 \
             eeacms/rsync sh
  ```

3. Start **mysql** and the **rsync server** on devel

  ```
    $ docker-compose up -d mysql
    $ docker run -it --rm --name=r-server -p 2222:22 \
                 --volumes-from=eeadockertaskman_mysql_1 \
                 -e SSH_AUTH_KEY="<SSH-KEY-FROM-R-CLIENT-ABOVE>" \
             eeacms/rsync server
  ```

4. Sync mysql dump. Within **rsync client** container from step 2 run:

  ```
    $ scp -P 2222 /var/local/backup/taskman.sql root@<TARGET_HOST_IP_ON_DEVEL>:/var/local/backup/
    $ exit
  ```

5. Import the dump file (on devel)

  ```
    $ docker exec -it eeadockertaskman_mysql_1 bash
     $ mysql -u<MYSQL_ROOT_USER> <MYSQL_DB_NAME> < /var/local/backup/taskman.sql
     $ exit
  ```

6. Close **rsync server**

  ```
    $ docker kill r-server
  ```

#### Email settings

**IMPORTANT:** test first if the email notification are sent!
Use first time the email accounts marked as **email configuration without affecting production** from the _.email.secret_ file.

Features to be tested:

* create ticket via email
* create ticket for Helpdesk
* receive email notification on content update
* email issue reminder notification

Edit email configuration for helpdesk and taskman accounts

    $ vim .email.secret

Edit email configuration for redmine

    $ vim .postfix.secret

Restart postfix container

    $ docker-compose stop postfix
    $ docker-compose rm -v postfix
    $ docker-compose up -d postfix

### Upgrade procedure

Make a backup of database

    $ docker exec eeadockertaskman_mysql_1 mysqldump -u<MYSQL_ROOT_USER> -p<MYSQL_ROOT_PASSWORD> --add-drop-table redmine > ./backup/taskman.sql

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

    $ bundle install --without development test
    $ bundle exec rake redmine:plugins:migrate RAILS_ENV=production

Run this only when installing premium plugins ( make sure you have the plugins archives available in /install_plugins - see volume mapping in docker-compose.yml )

    $ ./install_plugins.sh

Finnish updating taskman

    $ bundle exec rake tmp:cache:clear tmp:sessions:clear RAILS_ENV=production
    $ exit
    $ docker-compose stop
    $ docker-compose up -d

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

1) Within Redmine Web Interface of your project: Settings > Repositories > Add new repository

    - SCM: Git
    - Identifier: eea-mypackage
    - Path to repository: /var/local/redmine/github/eea.mypackage.git

<pre>
All local repositories within */var/local/redmine/github* folder are synced automatically
from https://github.com/eea every 5 minutes (see */etc/chaperone.d/chaperone.conf* and
*/var/local/redmine/crons/redmine_github_sync.sh*) so you don't have to add them manually on server side.
</pre>

2) Update users mapping for your new repository:

    - Within Redmine Web Interface > Projects > <Project> > Settings > Repositories click on *Users* link available for your new repository and Update missing users

If it still doesn't update automatically after a while:

* login to the docker host and become root
* enter the redmine container (docker exec -it eeadockertaskman_redmine_1 bash)
* cd /var/local/redmine/github
* git clone --mirror https://github.com/eea/eea.mypackage.git
* cd eea.mypackage.git
* git fetch --all
* chown -R apache.apache .

You can "read more":http://www.redmine.org/projects/redmine/wiki/HowTo_keep_in_sync_your_git_repository_for_redmine

### How to add check Redmine's logs

    $ docker-compose logs redmine

or

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ tail -f /usr/src/redmine/log/production.log

### How to manually sync LDAP users/groups

If you want to manually sync LDAP users and/or groups you need to run the following rake command inside the redmine container:

    $ docker exec -it eeadockertaskman_redmine_1 bash
    redmine@76547b4110ab:~/redmine$ bundle exec rake -T redmine:plugins:ldap_sync

For more info see the [LDAP sync documentation](https://github.com/thorin/redmine_ldap_sync#rake-tasks)

### How to install Redmine plugins

    $ cd /var/local/deploy/eea.docker.taskman/plugins
    $ docker-compose stop
    $ wget <URL-TO-DOWNLOAD-ZIPPED-PLUGIN>
    $ docker-compose up -d

Follow instructions from [Start updating Taskman](https://github.com/eea/eea.docker.taskman#start-updating-taskman)

### How to uninstall Redmine plugins

    $ docker exec -it eeadockertaskman_redmine_1 bash
    $ bundle exec rake redmine:plugins:migrate NAME=redmine_plugin-name VERSION=0 RAILS_ENV=production
    $ cd /var/local/deploy/eea.docker.taskman/plugins
    $ rm <redmine_plugin-name>
    $ docker-compose stop
    $ docker-compose up -d

### Specific plugins documentation

* [Agile plugin](http://www.redminecrm.com/projects/agile/pages/1).
* [Checklists plugin](https://www.redminecrm.com/projects/checklist/pages/1).
* [LDAP Sync plugin](https://github.com/thorin/redmine_ldap_sync).

### Setting up Taskman development replica

1) Sync data from production:

    - Redmine files [Import Taskman files](https://github.com/eea/eea.docker.taskman#import-taskman-files)
    - MySQL database [Import Taskman database](https://github.com/eea/eea.docker.taskman#import-taskman-database)

2) Update .email.secret:

    - change email account settings with development ones
    - change TASKMAN_URL to your dev domain

3) Start the dev containers using the folowing command:

```
    $ docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

4) Disable helpdesk email accounts from the following Taskman projects:

    - check via Redmine REST API where Helpdesk module is enabled
      - http://YOUR_TASKMAN_DEV_HOST/projects.xml?include=enabled_modules&limit=1000
        - <enabled_module id="111" name="contacts"/>
        - <enabled_module id="222" name="contacts_helpdesk"/>
      - currentlly the projects REST API is not showing all the projects. This are the known projects where the Helpdesk module is enabled:
        - zope (IDM2 A-Team)
        - it-helpdesk (IT Helpdesk)
        - ied (CWS support)
      - alternativelly you can connect to the MySQL server and do the following queries:
        - select * from enabled_modules where name='contacts_helpdesk';
        - select * from enabled_modules where name='contacts';

5) Setup network and firewall to allow access of the devel host on the EEA email accounts.

6) Change the following settings:

    - http://YOUR_TASKMAN_DEV_HOST/projects/zope/settings/helpdesk ( From address: support.taskmannt AT eea.europa.eu )
    - http://YOUR_TASKMAN_DEV_HOST/settings/plugin/redmine_contacts_helpdesk?tab=general ( From address: support.taskmannt AT eea.europa.eu )
    - http://YOUR_TASKMAN_DEV_HOST/settings?tab=notifications ( Emission email address: taskmannt AT eionet.europa.eu )
    - http://YOUR_TASKMAN_DEV_HOST/settings?tab=general ( Host name and path: YOUR_TASKMAN_DEV_HOST )
    - http://YOUR_TASKMAN_DEV_HOST/settings/plugin/redmine_banner ( Banner message: This is a Taskman development replica, please do not use/login if you are not part of the development team.)

7) Test e-mails using mailtrap on the folowing address: http://YOUR_TASKMAN_DEV_HOST:8081

    - additional mailtrap settings: Settings -> Mailbox View -> Show preview pane -> CHECKED


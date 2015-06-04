## EEA Taskman docker setup
Taskman is a web application that facilitates Agile project management for EEA and Eionet software projects.

### Prerequisites

- Install [Docker](https://docs.docker.com/installation/)
- Install [Compose](https://docs.docker.com/compose/install/)

### Installation

Clone the repository
    
    $ git clone https://github.com/eea/eea.docker.redmine
    $ cd eea.docker.redmine
    
Edit configuration files

    $ vim .mysql.secret
    $ vim .redmine.secret
    $ # edit email configuration for helpdesk and taskman accounts
    $ vim redmine/.email.secret
    $ # edit email configuration for redmine
    $ vim .postfix.secret
    
Start containers

    $ docker-compose up

### Import data
Import files
    
    $ docker-compose up data
    $ mkdir /var/data && cp -R /path/example/files/ data/
    $ docker run -it --rm --volumes-from eeadockerredmine_data_1 -v \
      /var/data/:/mnt debian /bin/bash -c \
      "cp -R /mnt/files /home/redmine/data/files && chown -R 1000:1000 /home/redmine/data/files"

Import database (replace db_production, user, pass with your values)
    
    $ cd eea.docker.redmine
    $ cp /path/database/dump.sql.tgz backup/
    $ docker-compose up -d mysql
    $ docker exec -i eeadockerredmine_mysql_1 /bin/bash -c \
      "tar xvf /var/local/backup/dump.sql.tgz && mysql -uuser -ppass db_production < dump.sql"
    $ docker-compose stop mysql
    
Run containers

    $ docker-compose up

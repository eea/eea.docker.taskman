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
    $ vim redmine/helpdesk.sh
    
Start containers

    $ docker-compose up


FROM busybox

RUN mkdir -p /var/lib/mysql
RUN chown -R 1000:1000 /var/lib/mysql
VOLUME /var/lib/mysql

RUN mkdir -p /home/redmine/data
RUN chown -R 1000:1000 /home/redmine/data
VOLUME /home/redmine/data

RUN mkdir -p /home/redmine/redmine/github
RUN chown -R 1000:1000 /home/redmine/redmine/github
VOLUME /home/redmine/redmine/github

USER 1000

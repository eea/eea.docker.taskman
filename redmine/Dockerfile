FROM sameersbn/redmine

#default for ENV vars
ENV DB_NAME=redmine_production
ENV DB_USER=redmine
ENV DB_PASS=password
ENV REDMINE_EMAIL_HOST=host
ENV REDMINE_EMAIL_USERNAME=username
ENV REDMINE_EMAIL_PASSWORD=password

# install dependencies
RUN apt-get update && apt-get install -y git subversion graphviz
RUN ln -s /home/redmine/redmine /var/local/redmine

#install the plugins
RUN git clone https://github.com/tckz/redmine-wiki_graphviz_plugin.git plugins/wiki_graphviz_plugin && \
    git clone https://github.com/masamitsu-murase/redmine_add_subversion_links.git plugins/redmine_add_subversion_links && \
    git clone git://github.com/koppen/redmine_github_hook plugins/redmine_github_hook && \
    git clone git://github.com/jfqd/redmine_helpdesk.git plugins/redmine_helpdesk && \
    #workaround to don't have as dependency the codeclimate-test-reporter gem
    echo > plugins/redmine_helpdesk/Gemfile && \
    #install the theme
    git clone git://github.com/eea/eea.redmine.theme.git public/themes/eea.redmine.theme

#install eea tools and start services
ADD startup.sh /home/redmine/redmine/startup.sh
RUN chmod +x /home/redmine/redmine/startup.sh
ADD helpdesk.sh /home/redmine/redmine/helpdesk.sh
RUN mkdir -p /var/log/helpdesk && chown redmine:redmine /var/log/helpdesk && chmod +x /home/redmine/redmine/helpdesk.sh

#add cron jobs
ADD cronjobs /tmp/cronjobs
RUN crontab -u redmine /tmp/cronjobs && rm -rf /tmp/cronjobs

ENTRYPOINT /home/redmine/redmine/startup.sh

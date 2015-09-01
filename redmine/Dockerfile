FROM sameersbn/redmine

#default for ENV vars
ENV DB_NAME=redmine_production
ENV DB_USER=redmine
ENV DB_PASS=password

# install dependencies
RUN apt-get update && apt-get install -y git subversion graphviz
RUN ln -s /home/redmine/redmine /var/local/redmine

#install the plugins
RUN git clone https://github.com/tckz/redmine-wiki_graphviz_plugin.git plugins/wiki_graphviz_plugin && \
    git clone https://github.com/masamitsu-murase/redmine_add_subversion_links.git plugins/redmine_add_subversion_links && \
    git clone git://github.com/koppen/redmine_github_hook plugins/redmine_github_hook && \
    git clone git://github.com/jslucas/redmine_helpdesk.git plugins/redmine_helpdesk && \
    #workaround to don't have as dependency the codeclimate-test-reporter gem
    echo > plugins/redmine_helpdesk/Gemfile && \
    #install the theme
    git clone git://github.com/eea/eea.redmine.theme.git public/themes/eea.redmine.theme && \
    chown -R redmine:redmine plugins public/themes

#add configuration file
ADD configuration.yml /home/redmine/redmine/config/configuration.yml
RUN chmod +r /home/redmine/redmine/config/configuration.yml && \
    chown redmine:redmine /home/redmine/redmine/config/configuration.yml

#install eea tools and start services
ADD startup.sh /home/redmine/redmine/startup.sh
RUN chmod +x /home/redmine/redmine/startup.sh && \
    chown redmine:redmine /home/redmine/redmine/startup.sh
ADD helpdesk.sh /home/redmine/redmine/helpdesk.sh
RUN mkdir -p /var/log/helpdesk && \
    chown redmine:redmine /var/log/helpdesk && \
    chmod +x /home/redmine/redmine/helpdesk.sh && \
    chown redmine:redmine /home/redmine/redmine/helpdesk.sh
ADD taskman_email.sh /home/redmine/redmine/taskman_email.sh
RUN chmod +x /home/redmine/redmine/taskman_email.sh && \
    chown redmine:redmine /home/redmine/redmine/taskman_email.sh

#add cron jobs
ADD cronjobs /tmp/cronjobs
RUN crontab -u redmine /tmp/cronjobs && rm -rf /tmp/cronjobs

# remove nginx start
RUN rm -rf /etc/supervisor/conf.d/nginx.conf

# after nginx's disable, it is needed to change gunicorn configuration
RUN mkdir /tmp/eea_SETUP_DIR
RUN cp -ar ${SETUP_DIR} /tmp/eea_SETUP_DIR
RUN sed 's/127.0.0.1/0.0.0.0/g' -i /tmp/eea_SETUP_DIR/redmine/config/redmine/unicorn.rb
ENV SETUP_DIR=/tmp/eea_SETUP_DIR/redmine

ENTRYPOINT /home/redmine/redmine/startup.sh

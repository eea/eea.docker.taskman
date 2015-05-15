FROM sameersbn/redmine

ENV REDMINE_DATA /var/redmine_data
ENV REDMINE_GITHUB /var/redmine_github

RUN apt-get update

RUN apt-get install -y git
RUN apt-get install -y subversion
RUN apt-get install -y graphviz
RUN ln -s /home/redmine/redmine /var/local/redmine

#install the plugins
RUN git clone https://github.com/tckz/redmine-wiki_graphviz_plugin.git plugins/wiki_graphviz_plugin
RUN git clone https://github.com/masamitsu-murase/redmine_add_subversion_links.git plugins/redmine_add_subversion_links
RUN git clone git://github.com/koppen/redmine_github_hook plugins/redmine_github_hook
RUN git clone git://github.com/jfqd/redmine_helpdesk.git plugins/redmine_helpdesk
#workaround to don't have as dependency the codeclimate-test-reporter gem
RUN echo > plugins/redmine_helpdesk/Gemfile

#install the theme
RUN git clone git://github.com/eea/eea.redmine.theme.git public/themes/eea.redmine.theme

#install eea tools and start services
ADD startup.sh /home/redmine/redmine/startup.sh
RUN chmod +x /home/redmine/redmine/startup.sh
ENTRYPOINT /home/redmine/redmine/startup.sh


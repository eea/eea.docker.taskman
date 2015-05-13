FROM sameersbn/redmine

RUN apt-get install git
RUN gem install codeclimate-test-reporter
RUN git clone https://github.com/tckz/redmine-wiki_graphviz_plugin.git plugins/redmine-wiki_graphviz_plugin
RUN git clone https://github.com/masamitsu-murase/redmine_add_subversion_links.git plugins/redmine_add_subversion_links
RUN git clone git://github.com/koppen/redmine_github_hook plugins/redmine_github_hook
RUN git clone git://github.com/jfqd/redmine_helpdesk.git plugins/redmine_helpdesk
RUN git clone git://github.com/eea/eea.redmine.theme.git public/themes/eea.redmine.theme

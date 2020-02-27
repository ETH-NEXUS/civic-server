FROM ruby:2.6
MAINTAINER Vipin <vipin@nexus.ethz.ch>

RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        npm \
	vim \
    	libxml2 \
    	libxslt1-dev \
    	libpq-dev \
    	openssl \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

## Install rbenv
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
     && ln -s /root/.rbenv/bin/rbenv /usr/local/bin/

# FSA: i was only able to get /db/data.sql to load at this code commit:
# f8e8980eb53582677760aa8caa79b9ab0789eb72
# i've manually checked it out in the running container; i also had to load
# db/schema.rb manually via rake schema::load rather than running the migrations
ENV CIVIC_SERVER=/civic-server
COPY Gemfile /civic-server/Gemfile
COPY Gemfile.lock /civic-server/Gemfile.lock
# RUN git clone https://github.com/griffithlab/civic-server.git
WORKDIR $CIVIC_SERVER

RUN gem install bundler:1.17.3 \
    && rbenv rehash \
    && bundle install \
    && rbenv rehash

COPY . /civic-server

#ENV DEBIAN_FRONTEND=noninteractive
#RUN apt-get purge -y nodejs
#COPY $PWD/nodesource /etc/apt/preferences.d/
#RUN apt-cache policy nodejs \
#    && apt-get install -y nodejs

EXPOSE 3000

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["rails", "server", "-b", "0.0.0.0"]

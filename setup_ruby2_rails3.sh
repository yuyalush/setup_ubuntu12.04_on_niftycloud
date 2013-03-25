#!/bin/bash
# Setup for git , Ruby2.0.0 , Rails3.2.13
echo "START!!!!" > log.txt
date >> log.txt
echo 'Install libs'
apt-get -y install git build-essential zlib1g-dev libssl-dev libreadline-dev libxml2-dev libxslt-dev libsqlite3-dev g++ 
echo "apt-get finished." >> log.txt
date >> log.txt

#ruby2.0.0
echo "Ruby start." >> log.txt
date >> log.txt
wget ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p0.tar.gz
tar zxvf ruby-2.0.0-p0.tar.gz
cd ruby-2.0.0-p0
./configure
make -j
make install
cd ..
echo "Ruby finished." >> log.txt
date >> log.txt

echo 'Install Rails' >> log.txt
date >> log.txt
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
gem i bundle
bundle init
echo 'gem "rails"' >> Gemfile
bundle install
echo "Rails finished." >> log.txt
date >> log.txt

# Sqlite3
echo "Sqlite3 start." >> log.txt
date >> log.txt
wget http://www.sqlite.org/2013/sqlite-autoconf-3071600.tar.gz
tar zxf sqlite-autoconf-3071600.tar.gz
cd sqlite-autoconf-3071600/
./configure
make -j5
make install
cd ..
gem install sqlite3-ruby
echo "Sqlite3 finished." >> log.txt
date >> log.txt

# Check
echo "ruby & rails check" >> log.txt
ruby -v >> log.txt
rails -v >> log.txt

# Test Rails App
rails new testapp --skip-bundle
cd testapp
echo "gem 'therubyracer'" >> Gemfile
echo "gem 'unicorn'">> Gemfile
bundle install
rails g scaffold Book title:string price:integer
rake db:migrate
bundle exec unicorn_rails -D
ufw allow 8080

echo "Finish!!!!!" >> ../log.txt
date >> ../log.txt
cat ../log.txt

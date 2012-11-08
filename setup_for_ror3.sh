#!/bin/bash
# Setup for git , Ruby1.9.2 , Rails3.2.8
echo "START!!!!" > log.txt
date >> log.txt
echo 'Install libs'
apt-get -y install git build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev libsqlite3-dev g++ 
echo "apt-get finished." >> log.txt
date >> log.txt

echo 'Install rbenv' >> log.txt
apt-get -y install rbenv
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
#eval "$(rbenv init -)"
#source ~/.bashrc
echo "rbenv finished." >> log.txt
date >> log.txt

echo 'Install ruby-build' >> log.txt
date >> log.txt
git clone git://github.com/sstephenson/ruby-build.git
cd ruby-build
./install.sh
cd ..
echo "ruby-build finished." >> log.txt
date >> log.txt

echo 'Install Ruby1.9.2-p320' >> log.txt
date >> log.txt
rbenv install 1.9.2-p320
rbenv rehash
rbenv global 1.9.2-p320
echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc
echo 'Ruby1.9.2-p320 finished' >> log.txt
date >> log.txt


echo 'Install Rails' >> log.txt
date >> log.txt
gem update --system
gem update rake
gem install rails -v=3.2.8
rbenv rehash
echo "Rails finished." >> log.txt
date >> log.txt

# Sqlite3
echo "Sqlite3 start." >> log.txt
date >> log.txt
wget http://www.sqlite.org/sqlite-autoconf-3071401.tar.gz
tar zxf sqlite-autoconf-3071401.tar.gz
cd sqlite-autoconf-3071401/
./configure
make -j
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
echo "gem 'unicorn'" >> Gemfile
echo "gem 'nifty-generators'" >> Gemfile
echo "gem 'mocha'" >> Gemfile
bundle install
rails g nifty:scaffold Book title:string price:integer
rails g nifty:layout -f
rake db:migrate
bundle exec unicorn_rails -D
ufw allow 8080

echo "Finish!!!!!" >> ../log.txt
date >> ../log.txt
cat ../log.txt


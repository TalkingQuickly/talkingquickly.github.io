# Make sure you have a vagrant environment file

su deploy
cd /vagrant
bundle install
sudo -u postgres psql -c "create user rails with password 'rails';"
sudo -u postgres psql -c "ALTER USER rails WITH SUPERUSER;"
bundle exec rake db:create db:migrate db:seed
sudo rm /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-enabled/monit
sudo cp /vagrant/vagrant/vhost /etc/nginx/sites-enabled/rails
sudo nginx -s reload
#!/bin/bash

# install mongod 3.3.6 from mongo repo
cd /var/tmp/seed
echo '[mongodb-org-3.6]' > mongodb-org-3.6.repo
echo 'name=MongoDB Repository' >> mongodb-org-3.6.repo
echo 'baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.6/x86_64/' >> mongodb-org-3.6.repo
echo 'gpgcheck=1' >> mongodb-org-3.6.repo
echo 'enabled=1' >> mongodb-org-3.6.repo
echo 'gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc' >> mongodb-org-3.6.repo
cp ./mongodb-org-3.6.repo /etc/yum.repos.d/mongodb-org-3.6.repo
yum install -y mongodb-org-3.6.6 mongodb-org-server-3.6.6 mongodb-org-shell-3.6.6 mongodb-org-mongos-3.6.6 mongodb-org-tools-3.6.6

service mongod start
chkconfig mongod on
service mongod restart

# install service tools
yum install mc -y
yum install nc -y

# install admin
echo 'use admin' > m.cli
echo 'db.createUser(' >> m.cli
echo '    {' >> m.cli
echo '      user: "root",' >> m.cli
echo '      pwd: "Passwordqwerty1234",' >> m.cli
echo '      roles: [ "root" ]' >> m.cli
echo '    }' >> m.cli
echo ')' >> m.cli
echo 'show dbs' >> m.cli
echo 'show collections' >> m.cli
echo 'show users' >> m.cli
echo 'show roles' >> m.cli
mongo 127.0.0.1:27017 < m.cli


# install database admin
echo 'use mynewdb' > m.cli
echo 'db.createUser(' >> m.cli
echo '  {' >> m.cli
echo '    user: "mynewdb",' >> m.cli
echo '    pwd: "Passwordqwerty1234",' >> m.cli
echo '    roles:["readWrite","dbAdmin"]' >> m.cli
echo '  }' >> m.cli
echo ')' >> m.cli
mongo 127.0.0.1:27017/admin -u root -p Passwordqwerty1234 < m.cli

# create database collection
echo 'db.myCollection.insertOne( { x: 1 } );' > m.cli
echo 'show collections' >> m.cli
mongo 127.0.0.1:27017/mynewdb -u mynewdb -p Passwordqwerty1234 < m.cli

# security inhenstment
sed -i "/#security:/a \  authorization: enabled" /etc/mongod.conf
sed -i "/#security:/a security:" /etc/mongod.conf
sed -i 's/: 127.0.0.1/: 0.0.0.0/' /etc/mongod.conf
service mongod restart

# clean up
echo 'hello world' > m.cli
rm m.cli
#!/bin/bash

# install service tools
yum install nc -y
yum install mc -y

# install httpd for logs
yum install httpd -y
service httpd start

# run java payload
cd /var/tmp/seed
tar zxf jre-8u172-linux-x64.tar.gz
jre1.8.0_172/bin/java -jar ./ts.jar
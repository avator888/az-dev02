#!/bin/bash

# --------------------------------------------------------------------------------------
# access to vm
#  ssh mongoadmin@40.85.201.230
#  ssh mongoadmin@dev02mongo0.canadacentral.cloudapp.azure.com

# access to mongo console
#  mongo -host dev02mongo0.canadacentral.cloudapp.azure.com -port 27017 -u "root" -p "Passwordqwerty1234" -authenticationDatabase "admin"
#  mongo -host dev02mongo0.canadacentral.cloudapp.azure.com -port 27017 -u "mynewdb" -p "Passwordqwerty1234" -authenticationDatabase "mynewdb"
# --------------------------------------------------------------------------------------

echo "building mongo 01 db - dev02mo01 ... "

# get credentials
cp ./credentials/azure/azure.tf ./databases/mo01/azure.tf

# prepare seed
cd ./databases/mo01/
rm ./seed.tar.gz
tar -cvzf ./seed.tar.gz ./seed

# run azure part
terraform init -input=false
terraform plan -out=tfplan -input=false 
terraform apply -input=false tfplan

# test result
echo "testing mongo 01 db ... "
sleep 60
err_code="$(nc -zv dev02mongo0.canadacentral.cloudapp.azure.com 27017 2>&1 | grep Connected | wc -l)"

if [ ${err_code} -gt "0" ] ; then
   echo "MONGO 01 IS UP ... "
else
   echo "MONGO 01 HAS SOME PROBLEMS ... "
fi

# clean up
echo "hello world" >> ./azure.tf
rm ./azure.tf
rm ./seed.tar.gz
cd ../..
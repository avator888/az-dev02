#!/bin/bash

# --------------------------------------------------------------------------------------
# access to vm
# --------------------------------------------------------------------------------------
echo "building backend java app 01 db - dev02ts01 ... "

# get credentials
cp ./credentials/azure/azure.tf ./apps-backend/ts01/azure.tf

# prepare seed
cd ./apps-backend/ts01/
rm ./seed.tar.gz
tar -cvzf ./seed.tar.gz ./seed

# run azure part
terraform init -input=false
terraform plan -out=tfplan -input=false 
terraform apply -input=false tfplan

# test result
echo "testing ts 01 ... "
sleep 60
err_code="$(curl http://dev02ts01.canadacentral.cloudapp.azure.com/ts/ping | grep "this message" | wc -l)"

if [ ${err_code} -gt "0" ] ; then
   echo "TRADE STATS 01 IS UP ... "
else
   echo "TRADE STATS 01 HAS SOME PROBLEMS ... "
fi

# clean up
echo "hello world" >> ./azure.tf
rm ./azure.tf
rm ./seed.tar.gz
cd ../..
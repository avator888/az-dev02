#!/bin/bash

echo "destroying backend java app 01 db - dev02ts01 ... "
cp ./credentials/azure/azure.tf ./apps-backend/ts01/azure.tf
cd ./apps-backend/ts01/
terraform destroy -auto-approve
echo "hello world" >> ./azure.tf
rm ./azure.tf
echo "end of process ... "
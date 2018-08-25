#!/bin/bash

echo "destroying mongo db - dev02mo01 ... "
cp ./credentials/azure/azure.tf ./databases/mo01/azure.tf
cd ./databases/mo01/
terraform destroy -auto-approve
echo "hello world" >> ./azure.tf
rm ./azure.tf
echo "end of process ... "
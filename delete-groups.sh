#!/usr/bin/env bash

echo "Start"
groups=($(az group list --query '[].name' -o tsv))
echo ${groups[@]}
for gr in ${groups[@]}
do
  echo "deleting $gr"
  az group delete -y --no-wait -n $gr  
done
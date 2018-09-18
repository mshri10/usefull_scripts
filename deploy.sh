#!/bin/bash
# Auto edit image push
#
# This still needs some tweaking for services like Eagle to function
# Input services you with to restart in services.txt as (cluster image tag)
# Ex. in the file

echo "which account"
read account

echo "This will create a rolling restart of the following services"

while read -r line; do
   service=$(echo "$line"| awk -F" "  '{print $2}')
   image=$(echo "$line"| awk -F" "  '{print $3}')
   echo "$service $image"
done < services.txt

read -r -p "Are you sure you wish to continue? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  while IFS=$'\n' read -r line;
    do
      if [[ "$line" =~ \#.* ]];then
          echo "$line"
      else
          cluster=$(echo "$line"| awk -F" "  '{print $1}')
          service=$(echo "$line"| awk -F" "  '{print $2}')
          NAME=${cluster}_${account}
          image=$(echo "$line"| awk -F" "  '{print $3}')
          ecs-deploy -c $NAME -n ecs_service_$service -i ampush/$image
        fi
      done< services.txt
else
    echo "deploy cancelled"
fi


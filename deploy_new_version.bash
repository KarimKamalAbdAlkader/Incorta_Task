#!/bin/bash +x

### Building new container with the new version.

### Get the network of reverseproxy to attach the new container to it.

NETWORK=$(docker inspect reverseproxy -f "{{json .NetworkSettings.Networks }}" | cut -d '"' -f2)

#docker build -t airports:v2 -f Dockerfile-airportsv2 .
docker-compose -f docker-compose2.yml build

###   Editing nginx configuration to redirect the requests to the new container ...
###   but it will not take effect until nginx service restart. */

docker exec -i reverseproxy sed -i 's/airports:8080/airportsv2:8080/g' /etc/nginx/nginx.conf

### Starting the new container.

if [ $(docker ps -f name=airports -q) ]
then
    ENV="airportsv2"
    OLD="airports"
fi

echo "Starting "$ENV" container"
#docker run -d -p 8080:8080 --name airportsv2 --net $NETWORK --link reverseproxy airports:v2
docker-compose -f docker-compose2.yml up -d
#docker-compose restart $ENV

### Waiting untill the APP starts.

echo "Waiting until APP is UP..."
sleep 15s


### Restart the nginx service to redirect the request to the new container.

docker exec -i reverseproxy service nginx restart

### Stopping the old one.

echo "Stopping "$OLD" container"
docker stop $OLD 1> /dev/null && docker rm $OLD 1> /dev/null

### Editting the docker-compose file to be able to start and stop the stack.

sed -i 's/airports/airportsv2/g' docker-compose.yml

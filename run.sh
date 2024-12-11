#!/bin/bash

# Variables
IMAGE_NAME="ubuntu"
TAG="latest"
LOCAL_TAG="localhost:5000/$IMAGE_NAME:$TAG"
CONTAINER_NAME="ansible-container"
PLAYBOOK_PATH="./playbook.yml"

# Pull the image
docker pull $IMAGE_NAME:$TAG

# Tag the image for localhost
docker tag $IMAGE_NAME:$TAG $LOCAL_TAG

# Push the image to the localhost registry
docker push $LOCAL_TAG

# Run a container from the image
docker run -d --name $CONTAINER_NAME $LOCAL_TAG

# Copy the Ansible playbook to the container
docker cp $PLAYBOOK_PATH $CONTAINER_NAME:/tmp/playbook.yml

# Install Ansible and run the playbook inside the container
docker exec -it $CONTAINER_NAME bash -c "
  apt-get update && apt-get install -y ansible &&
  ansible-playbook /tmp/playbook.yml
"

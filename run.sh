#!/bin/bash

# Variables
IMAGE_NAME="your-image"
TAG="latest"
CONTAINER_NAME="jenkins-agent-test"
PLAYBOOK_PATH="./playbook.yml"  # Path to your Ansible playbook on the host
JENKINS_URL="http://dummy.url" # Dummy value for JENKINS_URL if required

# Ensure the playbook file exists
if [ ! -f "$PLAYBOOK_PATH" ]; then
  echo "Error: Playbook file not found at $PLAYBOOK_PATH"
  exit 1
fi

# Stop and remove any existing container with the same name
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "Stopping and removing existing container: $CONTAINER_NAME"
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
fi

# Run the Jenkins agent container interactively
echo "Starting container: $CONTAINER_NAME"
docker run -d \
  --name $CONTAINER_NAME \
  -e JENKINS_URL=$JENKINS_URL \
  --entrypoint bash \
  $IMAGE_NAME:$TAG

# Wait for the container to start
echo "Waiting for container to start..."
sleep 3

# Copy the playbook to the container
echo "Copying playbook to the container..."
docker cp $PLAYBOOK_PATH $CONTAINER_NAME:/tmp/playbook.yml

# Ensure Ansible is installed in the container
echo "Installing Ansible inside the container..."
docker exec $CONTAINER_NAME bash -c "apt-get update && apt-get install -y ansible"

# Run the Ansible playbook
echo "Running Ansible playbook..."
docker exec $CONTAINER_NAME ansible-playbook /tmp/playbook.yml

# Output the results
if [ $? -eq 0 ]; then
  echo "Ansible playbook executed successfully."
else
  echo "Ansible playbook execution failed."
fi

# Optionally keep the container running for debugging
echo "Container is available for debugging. Stop it with:"
echo "docker stop $CONTAINER_NAME"

#!/bin/bash
set -euo pipefail

AWS_REGION="us-east-1"
AWS_PROFILE="project-admin"
ECR_URL="349020400385.dkr.ecr.us-east-1.amazonaws.com/luxe-jewelry-store-project"

docker login -u AWS -p "$(aws ecr get-login-password --region $AWS_REGION --profile $AWS_PROFILE)" $ECR_URL

IMAGES=("frontend" "backend" "auth-service" "jenkins-agent")

for tag in "${IMAGES[@]}"; do
  echo "Pushing image: $tag"
  docker pull talgold01/luxe-jewelry-store-project:$tag
  docker tag talgold01/luxe-jewelry-store-project:$tag $ECR_URL:$tag
  docker push $ECR_URL:$tag
done

#!/bin/bash
set -e

REGION="${region}"
ACCOUNT_ID="${account_id}"
REPO="${repo_name}"
TAG="${image_tag}"

# install docker & awscli
yum update -y
amazon-linux-extras install docker -y || yum install -y docker
service docker start
usermod -a -G docker ec2-user

# install aws cli v2 if not present (simple detection)
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

# login to ecr
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${REGION}.amazonaws.com"

# pull and run container
IMAGE="${account_id}.dkr.ecr.${REGION}.amazonaws.com/${REPO}:${TAG}"

# Wait until image exists in ECR; try a few times (this helps when terraform creates instance immediately before Jenkins pushed image)
for i in {1..20}; do
  if aws ecr describe-images --repository-name "${REPO}" --image-ids imageTag="${TAG}" --region "$REGION"; then
    break
  fi
  sleep 10
done

# run container
docker rm -f ${REPO} || true
docker run -d --name ${REPO} -p 80:3000 "${IMAGE}"

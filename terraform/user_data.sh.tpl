#!/bin/bash
set -e

region="${region}"
account_id="${account_id}"
repo_name="${repo_name}"
image_tag="${image_tag}"

# install docker
yum update -y
amazon-linux-extras install docker -y || yum install -y docker
service docker start
usermod -a -G docker ec2-user

# install aws cli v2 if missing
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

# login to ECR
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com"

# construct image path directly (instead of using IMAGE variable from Terraform)
IMAGE="${account_id}.dkr.ecr.${region}.amazonaws.com/${repo_name}:${image_tag}"

# Wait until image exists in ECR
for i in {1..20}; do
  if aws ecr describe-images --repository-name "${repo_name}" --image-ids imageTag="${image_tag}" --region "$region" >/dev/null 2>&1; then
    break
  fi
  echo "Image not found yet, retrying in 10s..."
  sleep 10
done

# Run container
docker rm -f ${repo_name} || true
docker run -d --name ${repo_name} -p 80:3000 "$${IMAGE}"

# Log confirmation
echo "Container deployed successfully with image: $${IMAGE}" >> /var/log/user-data.log

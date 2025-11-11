pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'              
    ECR_REPO = 'my-node-app'   
    AWS_ACCOUNT = '390776111022'         
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    ECR_URI = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        // build the docker image and tag locally
        bat "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
      }
    }

    stage('Login to ECR & Tag') {
      steps {
        // login to AWS ECR
        bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        // create repository if not exists
        bat "aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} || aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}"
        // tag image
        bat "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}"
      }
    }

    stage('Push to ECR') {
      steps {
        bat "docker push ${ECR_URI}:${IMAGE_TAG}"
      }
    }

    stage('Update Terraform variables and apply') {
      steps {
        // copy terraform files into workspace/terraform
        dir('terraform') {
          // ensure terraform init & apply; auto-approve only for demo
          bat "terraform init -input=false -no-color"
          // we set var.ecr_image_tag to the new tag
          bat "terraform apply -auto-approve -var='ecr_image_tag=${IMAGE_TAG}' -var='aws_region=${AWS_REGION}' -no-color"
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline complete. Image pushed: ${ECR_URI}:${IMAGE_TAG}"
    }
    failure {
      echo "Pipeline failed"
    }
  }
}

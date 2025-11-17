pipeline {
  agent any

  environment {
    AWS_REGION = "ap-south-1"
    TF_DIR = "terraform"
    AWS_CREDS_ID = "AWS_ECR_CREDS" // Jenkins credential id (or leave blank if using instance role)
  }

  stages {
    stage('Checkout') {
      steps {
        echo 'Cloning repository...'
        checkout scm
      }
    }

    stage('Terraform: create ECR repo only') {
      steps {
        dir("${TF_DIR}") {
          withAWS(credentials: "${AWS_CREDS_ID}", region: "${AWS_REGION}") {
            sh '''
              terraform init -input=false
              terraform apply -auto-approve -target=aws_ecr_repository.app_repo
            '''
          }
        }
      }
    }

    stage('Read ECR URL') {
      steps {
        dir("${TF_DIR}") {
          sh 'terraform output -raw ecr_repository_url > ../ecr_url.txt'
        }
      }
    }

    stage('Build & Tag Docker image') {
      steps {
        script {
          def ecrUrl = readFile("ecr_url.txt").trim()
          sh """
            docker build -t app-temp-image:latest .
            docker tag app-temp-image:latest ${ecrUrl}:latest
          """
        }
      }
    }

    stage('Login & Push image to ECR') {
      steps {
        withAWS(credentials: "${AWS_CREDS_ID}", region: "${AWS_REGION}") {
          script {
            def ecrUrl = readFile("ecr_url.txt").trim()
            // login using registry host (account.dkr.ecr.region.amazonaws.com)
            def registry = ecrUrl.split('/')[0]
            sh """
              aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${registry}
              docker push ${ecrUrl}:latest
            """
          }
        }
      }
    }

    stage('Terraform: create EC2 and other infra') {
      steps {
        dir("${TF_DIR}") {
          withAWS(credentials: "${AWS_CREDS_ID}", region: "${AWS_REGION}") {
            sh '''
              terraform apply -auto-approve
              terraform output -raw ec2_public_ip > ../ec2_ip.txt
            '''
          }
        }
      }
    }

    stage('Verify Deployment') {
      steps {
        script {
          def ip = readFile("ec2_ip.txt").trim()
          echo "App should be available at: http://${ip} (port 80)"
        }
      }
    }
  }

  post {
    failure { echo "PIPELINE FAILED ❌" }
    success { echo "PIPELINE SUCCESS ✅" }
  }
}

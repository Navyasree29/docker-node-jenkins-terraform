# Base image with Jenkins and Java (required for Jenkins)
FROM jenkins/jenkins:lts

# Switch to root to install system dependencies
USER root

# Install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    nodejs \
    npm \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# Install AWS CLI
RUN pip3 install awscli --break-system-packages


# Create app directory
WORKDIR /usr/src/app

# Copy Node.js app files
COPY app/package*.json ./
RUN npm install --production
COPY app/ ./

# Expose Jenkins (8080) + Node.js app (3000)
EXPOSE 8080 3000 50000

# Set up environment variables (optional)
ENV AWS_DEFAULT_REGION=ap-south-1

# Run both Jenkins and Node app together
CMD service docker start && \
    nohup npm start & \
    /usr/bin/java -jar /usr/share/jenkins/jenkins.war

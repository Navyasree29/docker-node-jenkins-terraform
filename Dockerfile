# Base image with Jenkins and Java (required for Jenkins)
FROM jenkins/jenkins:lts

USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl unzip git nodejs npm python3 python3-pip supervisor \
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
COPY app/package*.json ./
RUN npm install --production
COPY app/ ./

# Expose ports
EXPOSE 8080 3000 50000

# Supervisor config to run both Jenkins and Node.js
RUN echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:jenkins]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=java -jar /usr/share/jenkins/jenkins.war" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:nodeapp]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "directory=/usr/src/app" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=npm start" >> /etc/supervisor/conf.d/supervisord.conf

# Start both services via Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

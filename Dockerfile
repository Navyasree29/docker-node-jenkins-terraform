# Base image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package.json first
COPY app/package*.json ./

# Install dependencies
RUN npm install --production

# Copy app source code
COPY app/ .

# Expose the port the app listens on
EXPOSE 3000

# Run the app
CMD ["npm", "start"]

# Dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock if present
COPY node.js/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app code
COPY node.js/ .

EXPOSE 3000
CMD ["npm", "start"]

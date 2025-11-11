# Base image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package and install
COPY app/package.json ./
RUN npm install --production

# Copy app source
COPY app/ ./

# Expose the port the app listens on
EXPOSE 3000

# Run the app
CMD ["npm", "start"]

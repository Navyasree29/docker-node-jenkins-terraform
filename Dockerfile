# Dockerfile
FROM node:18-alpine

WORKDIR /usr/src/app

# copy package.json first to use layer caching
COPY node.js/package*.json ./

RUN npm install --production

# copy app code
COPY node.js/ ./

EXPOSE 3000

CMD ["npm", "start"]

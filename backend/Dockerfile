# BUILD STAGE
FROM node:22-alpine AS build

WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY . .
RUN npm run build

# Only install production dependencies to keep the final image small
RUN npm ci --only=production && npm cache clean --force

# PRODUCTION STAGE
FROM node:22-alpine AS production

WORKDIR /usr/src/app

# Set Node environment
ENV NODE_ENV production

# Copy necessary files from the build stage
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist

# Expose port (Cloud Run sets PORT env var automatically)
EXPOSE 3000

# Start the server
CMD ["node", "dist/main.js"]

FROM node:lts-alpine
EXPOSE 3000
CMD ["yarn", "run", "dev"]
COPY package.json yarn.lock ./
RUN yarn install --production=false --frozen-lockfile --non-interactive
COPY . .

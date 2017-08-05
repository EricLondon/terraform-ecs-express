FROM node:6.11.1

ENV APP_HOME /express
WORKDIR $APP_HOME

COPY app.js $APP_HOME
COPY package.json $APP_HOME

RUN npm install

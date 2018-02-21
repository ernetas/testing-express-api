FROM node:carbon
ADD . /usr/src/app
WORKDIR /usr/src/app
RUN npm install --save express && \
    npm install --save-dev supertest tape tap-spec
EXPOSE 3000
CMD [ "npm", "start" ]

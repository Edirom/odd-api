#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM node:25 AS builder

ENV ODDAPI_BUILD_HOME="/opt/oddapi-build"

WORKDIR ${ODDAPI_BUILD_HOME}

COPY . .

RUN npm install \
    && cp existConfig.tmpl.json existConfig.json \
    && ./node_modules/.bin/gulp dist

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:6-jre11

# For more details about the options see  
# https://github.com/peterstadler/existdb-docker
LABEL org.opencontainers.image.authors="Johannes Kepper and Peter Stadler" \
      org.opencontainers.image.source="https://github.com/Edirom/odd-api"
ENV EXIST_ENV="restxq"
ENV EXIST_CONTEXT_PATH="/"

# simply copy our xar package
# to the eXist-db autodeploy folder
COPY --from=builder /opt/oddapi-build/dist/*.xar ${EXIST_HOME}/autodeploy/

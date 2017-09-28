# Mozilla Kinto server
FROM debian:sid
MAINTAINER Storage Team irc://irc.freenode.net/#kinto

RUN groupadd --gid 10001 app && \
    useradd --uid 10001 --gid 10001 --home /app --create-home app
WORKDIR /app
COPY . /app

ENV KINTO_INI /etc/kinto/kinto.ini
ENV PORT 8888

# Install build dependencies, build the virtualenv and remove build
# dependencies all at once to build a small image.
RUN \
    apt-get update; \
    apt-get install -y python3 python3-setuptools python3-pip libpq5; \
    apt-get install -y build-essential git python3-dev libssl-dev libffi-dev libpq-dev; \
    apt-get install -y nodejs; \
    cd kinto/plugins/admin; npm install kinto/plugins/admin; npm run build; \
    pip3 install -e /app[postgresql,monitoring]; \
    pip3 install kinto-pusher kinto-fxa kinto-attachment ; \
    kinto init --ini $KINTO_INI --host 0.0.0.0 --backend=memory; \
    apt-get remove -y -qq build-essential git python3-dev libssl-dev libffi-dev libpq-dev; \
    apt-get autoremove -y -qq; \
    apt-get clean -y

USER app
# Run database migrations and start the kinto server
CMD kinto migrate --ini $KINTO_INI && kinto start --ini $KINTO_INI --port $PORT

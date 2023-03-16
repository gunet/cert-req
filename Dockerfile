FROM debian:bullseye-slim
LABEL org.opencontainers.image.source="https://github.com/gunet/cert-req"
LABEL org.opencontainers.image.description="A simple Docker image to create certificate requests for web servers"
ENV ORG=GUNET
ENV SERVER=server.gunet.gr
RUN apt-get -qq update && apt-get -qqy install --no-install-recommends openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /var/cert-req
COPY *.cnf ./
COPY create.sh .
RUN chmod 0755 create.sh
ENTRYPOINT [ "/var/cert-req/create.sh" ]
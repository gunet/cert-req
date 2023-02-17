FROM debian:bullseye-slim
ENV ORG=GUNET
ENV SERVER=server.gunet.gr
RUN apt-get -qq update && apt-get -qqy install openssl && apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /var/cert-req
COPY *.cnf ./
COPY create.sh .
RUN chmod 0755 create.sh
ENTRYPOINT [ "/var/cert-req/create.sh" ]
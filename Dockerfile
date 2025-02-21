ARG FROM
FROM ${FROM}

WORKDIR /opt

COPY . .

RUN git config --global --add safe.directory /opt/repo || echo "no git"

VOLUME /opt/repo 

ARG IMGUSER=
USER ${IMGUSER}

ENTRYPOINT ["./start.sh"]

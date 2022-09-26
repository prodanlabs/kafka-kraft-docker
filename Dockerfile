FROM docker.io/library/openjdk:17-jdk
LABEL maintainer "prodan"

ENV KAFKA_VERSION="3.1.2" \
    SCALA_VERSION="2.13"

RUN groupadd -r kafka && useradd --no-log-init -r -g kafka kafka

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN cd /opt \
    && curl --remote-name --silent --show-error --fail "https://dlcdn.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" \
    && mkdir kafka /var/lib/kafka \
    && tar -zxvf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C ./kafka --strip-components 1 \
    && chown kafka.kafka -R kafka /var/lib/kafka \
    && rm -rf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

EXPOSE 9092 9093

WORKDIR /opt/kafka

USER kafka

ENTRYPOINT [ "/docker-entrypoint.sh" ]
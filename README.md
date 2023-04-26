# kafka-kraft-docker

Refer to `bitnami/kafka`

#### Rules for image tags
`{SCALA_VERSION}`-`{KAFKA_VERSION}`-`{JDK_VERSION}`

#### Environment 
The configuration of kafka is passed in using environment variables, which start with `KAFKA_CFG_`. For example, to enable the configuration of Kafka `delete.topic.enable=true`, its environment variable is `KAFKA_CFG_DELETE_TOPIC_ENABLE`

#### Examples
run on docker
```sh
docker run --name kafka-0 -d  \
-e POD_NAME="kafka-0" \
-e KAFKA_CFG_ADVERTISED_LISTENERS="PLAINTEXT://:9092" \
-e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS="0@127.0.0.1:9093" \
-e KAFKA_CFG_LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093" \
-e KAFKA_CFG_PROCESS_ROLES="broker,controller" \
-e KAFKA_CFG_CONTROLLER_LISTENER_NAMES="CONTROLLER"  \
prodan/kafka-kraft:2.13-3.4.0-jdk17
```
run on docker compose 
```sh
# install docker compose plugin
apt install docker-compose-plugin

# clone repo
git clone https://github.com/prodanlabs/kafka-kraft-docker.git

# docker compose up
cd kafka-kraft-docker/examples/docker
docker compose up -d
```
run on kubernetes
```sh
# clone repo
git clone https://github.com/prodanlabs/kafka-kraft-docker.git

# create statefulset
kubectl create -f kafka-kraft-docker/examples/kubernetes/statefulset.yaml
```

#### Docker buildx
```sh
# Installing emulators
docker run --privileged --rm tonistiigi/binfmt --install all

# Create a new builder instance
docker buildx create --use --name kafka-builder

# If a builder instance is also created, you can view and set the current builder instance
docker buildx ls
docker buildx use  <name>

# Start a build 
docker buildx build --platform linux/arm64,linux/amd64 -t  <image-name> . --push
```

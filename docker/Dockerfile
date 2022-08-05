# TODO Pass in image as argument
FROM quay.io/centos/centos:stream8

# TODO Make the following its on build image and
# copy the relavent pieces to production image
# upgrade packages
RUN dnf upgrade --setopt=install_weak_deps=False -y && \
    dnf install java-11-openjdk-devel -y && \
    dnf install wget -y && \
    dnf clean all && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/yum && \
    rm -rf /var/cache/dnf && \
    find /var/log -type f -name '*.log' -delete

# INSTALL SCALA Required by Kafka
# TODO Check signature/hash
# TODO Pass Scala Version in as Argument
# See https://www.scala-lang.org/download/2.13.8.html for details
# Kafka 3.x recommend using latest scala 2.13.x kafka is written in 
# scala
ENV SCALA_MAJOR_VERSION 2
ENV SCALA_MINOR_VERSION 13
ENV SCALA_PATCH_VERSION 8
ENV SCALA_VERSION $SCALA_MAJOR_VERSION.$SCALA_MINOR_VERSION.$SCALA_PATCH_VERSION


WORKDIR /tmp
RUN mkdir installs
WORKDIR /tmp/installs
RUN wget https://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.rpm
RUN dnf install scala-$SCALA_VERSION.rpm -y

# Create Kafka User and it's home directory
RUN groupadd --gid=3000 kafka
RUN useradd --uid=3000 --gid=3000 kafka


# INSTALL KAFKA
# TODO Check signature/hash
# TODO Pass Kafka Version in as an Argument
# TODO Move to build layer and copy
# https://dlcdn.apache.org/kafka/3.2.0/kafka_2.13-3.2.0.tgz
ENV KAFKA_VERSION 3.2.0
ENV KAFKA_NAME kafka_$SCALA_MAJOR_VERSION.$SCALA_MINOR_VERSION-$KAFKA_VERSION
RUN wget https://dlcdn.apache.org/kafka/$KAFKA_VERSION/$KAFKA_NAME.tgz && \
  tar xvf $KAFKA_NAME.tgz
WORKDIR /tmp/installs/$KAFKA_NAME
RUN mv ./* /home/kafka
COPY ./entrypoint.sh /home/kafka/
RUN chmod -R 755 /home/kafka
RUN chown -R kafka /home/kafka

# Populate Kraft configs
#ADD ./kraft /home/kafka/$KAFKA_NAME/config/kraft/
# Add run script
USER kafka
WORKDIR /home/kafka

# Make Kafka log directories must match kraft/server.properties value
RUN mkdir /home/kafka/kraft-combined-logs

# Setup Kraft server generate kraft cluster id in the init container
#  mNvZdBzpR3KCdx-uEAwaEQ
WORKDIR /home/kafka
#RUN ./bin/kafka-storage.sh format -t mNvZdBzpR3KCdx-uEAwaEQ -c ./config/kraft/server.properties

ENTRYPOINT ["./entrypoint.sh"]

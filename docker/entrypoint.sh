#!/bin/bash

NODE_ID=${HOSTNAME:6}
LISTENERS_BROKER_CONTROLLER="PLAINTEXT://:9092,CONTROLLER://:9093"
LISTENERS_BROKER_ONLY="PLAINTEXT://:9092"
ADVERTISED_LISTENERS="PLAINTEXT://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"

# Let's just create on controller
CONTROLLER_QUORUM_VOTERS="0@$SERVICE.$NAMESPACE.svc.cluster.local:9093"


# Make node zero both controller and broker
if (( $NODE_ID == 0 )); then
  PROCESS_ROLES=broker,controller
  LISTENERS=$LISTENERS_BROKER_CONTROLLER
else
  PROCESS_ROLES=broker
  LISTENERS=$LISTENERS_BROKER_ONLY
fi

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$LOG_DIR+" \
-e "s+^process.roles=.*+process.roles=$PROCESS_ROLES+" \
/home/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /home/kafka/config/kraft/server.properties

./bin/kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c /home/kafka/config/kraft/server.properties

exec ./bin/kafka-server-start.sh /home/kafka/config/kraft/server.properties

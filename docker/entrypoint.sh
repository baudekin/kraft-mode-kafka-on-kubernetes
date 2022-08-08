#!/bin/bash

NODE_ID=${HOSTNAME:6}
#LISTENERS_BROKER_CONTROLLER="PLAINTEXT://:9092,CONTROLLER://:9093"
#LISTENERS_BROKER_ONLY="PLAINTEXT://:9092"
#ADVERTISED_LISTENERS="PLAINTEXT://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"

# Let's just create one controller
#CONTROLLER_QUORUM_VOTERS="0@kafa-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9093"
#CONTROLLER_QUORUM_VOTERS="0@$SERVICE.$NAMESPACE.svc.cluster.local:9093"
SECURITY_PROTOCAL_MAP="CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL"

for (( i=0; i<$REPLICAS ;i++ ))
do
  if (( $i == 0 )); then
    SECURITY_PROTOCAL_MAP="PLAINTEXT_$i:PLANTEXT,CONTROLLER_$i:PLANTEXT"
    LISTENERS_BROKER_CONTROLLER="PLAINTEXT_$i://:9092,CONTROLLER_$i://:9093"
    CONTROLLER_QUORUM_VOTERS="$i@kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9093"
    ADVERTISED_LISTENERS="PLAINTEXT_$i://kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9092"
  else
    SECURITY_PROTOCAL_MAP="${SECURITY_PROTOCAL_MAP},PLAINTEXT_$i:PLANTEXT,CONTROLLER_$i:PLANTEXT"
    LISTENERS_BROKER_CONTROLLER="${LISTENERS_BROKER_CONTROLLER},PLAINTEXT_$i://:9092,CONTROLLER_$i://:9093"
    CONTROLLER_QUORUM_VOTERS="${CONTROLLER_QUORUM_VOTERS},$i@kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9093"
    ADVERTISED_LISTENERS="${ADVERTISED_LISTENERS},PLAINTEXT_$i://kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:9092"
  fi
done

PROCESS_ROLES=broker,controller
LISTENERS=$LISTENERS_BROKER_CONTROLLER

#  -e "s+^plistener.security.protocol.map=.*+listener.security.protocol.map=$SECURITY_PROTOCAL_MAP+" \

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$LOG_DIR+" \
-e "s+^process.roles=.*+process.roles=$PROCESS_ROLES+" \
/home/kafka/config/kraft/server.properties > server.properties.updated \
&& cat "listener.security.protocal.map=$SECURITY_PROTOCAL_MAP" >> server.properties.updated \
&& mv server.properties.updated /home/kafka/config/kraft/server.properties

./bin/kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c /home/kafka/config/kraft/server.properties

exec ./bin/kafka-server-start.sh /home/kafka/config/kraft/server.properties

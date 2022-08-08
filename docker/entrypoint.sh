#!/bin/bash

NODE_ID=${HOSTNAME:6}
#LISTENERS_BROKER_CONTROLLER="PLAINTEXT://:9092,CONTROLLER://:9093"
#LISTENERS_BROKER_ONLY="PLAINTEXT://:9092"
#ADVERTISED_LISTENERS="PLAINTEXT://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"

# Let's just create one controller
#CONTROLLER_QUORUM_VOTERS="0@kafa-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9093"
#CONTROLLER_QUORUM_VOTERS="0@$SERVICE.$NAMESPACE.svc.cluster.local:9093"
SECURITY_PROTOCAL_MAP="PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT"
INTERNAL_LISTENER_NAME="PLAINTEXT_0"

for (( i=0; i<$REPLICAS ;i++ ))
do
  BROKER_PORT=$(( 9092 + $i ))
  CONTROLLER_PORT=$(( 9083 + $i ))
  SECURITY_PROTOCAL_MAP="$SECURITY_PROTOCAL_MAP,PLAINTEXT_$i:PLAINTEXT,CONTROLLER_$i:PLAINTEXT"
  if (( $i == 0 )); then
    CONTROLLER_LISTENER_NAMES="CONTROLLER_$i"
    LISTENERS_BROKER_CONTROLLER="PLAINTEXT_$i://:$BROKER_PORT,CONTROLLER_$i://:$CONTROLLER_PORT"
    CONTROLLER_QUORUM_VOTERS="$i@kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:$CONTROLLER_PORT"
    ADVERTISED_LISTENERS="PLAINTEXT_$i://kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:$BROKER_PORT"
  else
    CONTROLLER_LISTENER_NAMES="$CONTROLLER_LISTENER_NAMES,CONTROLLER_$i"
    LISTENERS_BROKER_CONTROLLER="${LISTENERS_BROKER_CONTROLLER},PLAINTEXT_$i://:$BROKER_PORT,CONTROLLER_$i://:$CONTROLLER_PORT"
    CONTROLLER_QUORUM_VOTERS="${CONTROLLER_QUORUM_VOTERS},$i@kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:$CONTROLLER_PORT"
    ADVERTISED_LISTENERS="${ADVERTISED_LISTENERS},PLAINTEXT_$i://kafka-$i.$SERVICE.$NAMESPACE.svc.cluster.local:$BROKER_PORT"
  fi
done

PROCESS_ROLES="broker,controller"
LISTENERS=$LISTENERS_BROKER_CONTROLLER

#  -e "s+^plistener.security.protocol.map=.*+listener.security.protocol.map=$SECURITY_PROTOCAL_MAP+" \
# && echo "listener.security.protocal.map=$SECURITY_PROTOCAL_MAP" >> server.properties.updated \

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$LOG_DIR+" \
-e "s+^process.roles=.*+process.roles=$PROCESS_ROLES+" \
-e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
-e "s+^inter.broker.listener.name=.*+inter.broker.listener.name=$INTERNAL_LISTENER_NAME+" \
-e "s+^listener.security.protocol.map=.*+listener.security.protocol.map=$SECURITY_PROTOCAL_MAP+" \
/home/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /home/kafka/config/kraft/server.properties

echo "************************************************************************"
echo "************************************************************************"
echo "************************************************************************"
echo $SECURITY_PROTOCAL_MAP
cat /home/kafka/config/kraft/server.properties
echo "************************************************************************"
echo "************************************************************************"
echo "************************************************************************"

./bin/kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c /home/kafka/config/kraft/server.properties

exec ./bin/kafka-server-start.sh /home/kafka/config/kraft/server.properties

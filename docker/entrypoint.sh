#!/bin/bash
# Note the info we need POD_NAME can be passed in using
# helm teplates So there will be no need for NODE_ID logic below
# - name: POD_IP
#          valueFrom:
#            fieldRef:
#              fieldPath: status.podIP
#        - name: POD_NAME
#          valueFrom:
#            fieldRef:
#              fieldPath: metadata.name
#        - name: POD_NAMESPACE
#          valueFrom:
#            fieldRef:
#              fieldPath: metadata.namespace   
BROKER_ID=${HOSTNAME:6}
POD_NAME=kafka-${BROKER_ID}

PROCESS_ROLES=broker,controller

DNS_NAME="$POD_NAME.$SERVICE.$NAMESPACE.svc.cluster.local"

LISTENER_SECURITY_PROTOCAL_MAP="INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT"
ADVERTISED_LISTENERS="EXTERNAL://$DNS_NAME:9092,INTERNAL://$DNS_NAME:9492"
LISTENERS="INTERNAL://$DNS_NAME:9492,EXTERNAL://$DNS_NAME:9092,CONTROLLER://$DNS_NAME:9093"
INTER_BROKER_LISTENER_NAME=INTERNAL

CONTROLLER_LISTENER_NAMES=CONTROLLER
CONTROLLER_QUORUM_VOTERS=0@$DNS_NAME:9093

for (( i=0; i<$REPLICAS ;i++ ))
do
  CONTROLLER_PORT=$(( 9083 + $i ))
#  if (( $i == 0 )); then
#  else
#  fi
done

# Build new server.properties map
sed -e "s+^node.id=.*+node.id=$BROKER_ID+" \
-e "s+^process.roles=.*+process.roles=$PROCESS_ROLES+" \
-e "s+^listener.security.protocol.map=.*+listener.security.protocol.map=$LISTENER_SECURITY_PROTOCAL_MAP+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^inter.broker.listener.name=.*+inter.broker.listener.name=$INTER_BROKER_LISTENER_NAME+" \
-e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^log.dirs=.*+log.dirs=$LOG_DIR+" \
/home/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /home/kafka/config/kraft/server.properties

echo "************************************************************************"
echo "************************************************************************"
echo "************************************************************************"
cat /home/kafka/config/kraft/server.properties
echo "************************************************************************"
echo "************************************************************************"
echo "************************************************************************"

./bin/kafka-storage.sh format --ignore-formatted -t $CLUSTER_ID -c /home/kafka/config/kraft/server.properties

exec ./bin/kafka-server-start.sh /home/kafka/config/kraft/server.properties

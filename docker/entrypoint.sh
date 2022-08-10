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
PROCESS_ROLES=broker,controller
BROKER_ID=${HOSTNAME:6}

LISTENER_SECURITY_PROTOCAL_MAP="INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT"
INTERNAL_BROKER_LISTENER_NAME=INTERNAL_0

CONTROLLER_LISTENER_NAMES=CONTROLLER_0,CONTROLLER_1

for (( i=0; i<$REPLICAS ;i++ ))
do
  POD_NAME="kafka-${i}"
  DNS_NAME="$POD_NAME.$SERVICE.$NAMESPACE.svc.cluster.local"

  EXTERNAL_BROKER_PORT="9${i}92"
  INTERNAL_BROKER_PORT="8${i}92"
  CONTROLLER_PORT="9${i}93"


  INTERNAL_MAP_KEY="INTERNAL_${i}";
  CONTROLLER_MAP_KEY="CONTROLLER_${i}";
  if (( $i == 0 )); then
    CONTROLLER_QUORUM_VOTERS="$i@$DNS_NAME:$CONTROLLER_PORT"
    ADVERTISED_LISTENERS="EXTERNAL://$DNS_NAME:$EXTERNAL_BROKER_PORT,INTERNAL://$DNS_NAME:$INTERNAL_BROKER_PORT"
    LISTENERS="$INTERNAL_MAP_KEY://$DNS_NAME:$INTERNAL_BROKER_PORT,EXTERNAL://$DNS_NAME:$EXTERNAL_BROKER_PORT,$CONTROLLER_MAP_KEY://$DNS_NAME:$CONTROLLER_PORT"
  else
    CONTROLLER_QUORUM_VOTERS="$CONTROLLER_QUORUM_VOTERS,$i@$DNS_NAME:$CONTROLLER_PORT"
    ADVERTISED_LISTENERS="$ADVERTISED_LISTENERS,EXTERNAL://$DNS_NAME:$EXTERNAL_BROKER_PORT,INTERNAL://$DNS_NAME:$INTERNAL_BROKER_PORT"
    LISTENERS="$LISTENERS,$INTENAL_MAP_KEY://$DNS_NAME:$INTERNAL_BROKER_PORT,EXTERNAL://$DNS_NAME:$EXTERNAL_BROKER_PORT,$CONTROLLER_MAP_KEY://$DNS_NAME:$CONTROLLER_PORT"
  fi
done

echo "listeners=${LISTENERS}"

# Build new server.properties map
sed -e "s+^node.id=.*+node.id=$BROKER_ID+" \
--e "s+^process.roles=.*+process.roles=$PROCESS_ROLES+" \
--e "s+^listener.security.protocol.map=.*+listener.security.protocol.map=$LISTENER_SECURITY_PROTOCAL_MAP+" \
--e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
--e "s+^inter.broker.listener.name=.*+inter.broker.listener.name=$INTERNAL_BROKER_LISTENER_NAME+" \
--e "s+^controller.listener.names=.*+controller.listener.names=$CONTROLLER_LISTENER_NAMES+" \
--e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
--e "s+^log.dirs=.*+log.dirs=$LOG_DIR+" \
--e "s+^listeners=.*+listeners=${LISTENERS}+" \
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

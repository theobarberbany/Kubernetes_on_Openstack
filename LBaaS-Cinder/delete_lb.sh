# Set the lb id
echo -n "Enter LB ID to be deleted: "
read LB_ID
echo "deleting LBaaS ID :" "$LB_ID"
# delete the lb and all sub components.
LB_DATA=$(neutron lbaas-loadbalancer-show ${LB_ID} --format json)
echo "LB_DATA Command : " "$LB_DATA"
LB_LISTENER_1_ID=$(echo -e "$LB_DATA" | jq -r '.listeners[].id')
echo "LB_listeners Command : " "$LB_LISTENER_1_ID"
LB_POOL_ID=$(neutron lbaas-listener-show ${LB_LISTENER_1_ID} --format json | jq -r '.default_pool_id')
echo "LB_pool Command : " "$LB_POOL_ID"
LB_HEALTH_ID=$(neutron lbaas-pool-show ${LB_POOL_ID} --format json | jq -r '.healthmonitor_id')
echo "LB_health Command : " "$LB_HEALTH_ID"
neutron lbaas-pool-delete "${LB_POOL_ID}"
neutron lbaas-listener-delete "${LB_LISTENER_1_ID}"
neutron lbaas-healthmonitor-delete "${LB_HEALTH_ID}"
neutron lbaas-loadbalancer-delete "${LB_ID}"

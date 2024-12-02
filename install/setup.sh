#!/bin/sh

source ./export-cluster-env-vars.sh

pushd ..

# Deploy the HTTPBin application on both clusters
kubectl --context $CLUSTER1 create namespace httpbin --dry-run=client -o yaml | kubectl --context $CLUSTER1 apply -f -
kubectl --context $CLUSTER1 apply -f apis/httpbin.yaml
kubectl --context $CLUSTER2 create namespace httpbin --dry-run=client -o yaml | kubectl --context $CLUSTER2 apply -f -
kubectl --context $CLUSTER2 apply -f apis/httpbin.yaml

# Setup the gg-config namespace on all clusters. This namespace will be used for Gateway-1
kubectl --context $MGMT create namespace gg-config --dry-run=client -o yaml | kubectl --context $MGMT apply -f -
kubectl --context $CLUSTER1 create namespace gg-config --dry-run=client -o yaml | kubectl --context $CLUSTER1 apply -f -
kubectl --context $CLUSTER2 create namespace gg-config --dry-run=client -o yaml | kubectl --context $CLUSTER2 apply -f -

# Setup the gg-config namespace on all the mgmt cluster and cluster-2. This namespace will be used for Gateway-2 and will only be provisioned on cluster2.
kubectl --context $MGMT create namespace gg-config-2 --dry-run=client -o yaml | kubectl --context $MGMT apply -f -
kubectl --context $CLUSTER2 create namespace gg-config-2 --dry-run=client -o yaml | kubectl --context $CLUSTER2 apply -f -

# Install the GG Mgmt GatewayClass on the mgmt cluster
kubectl --context ${MGMT} apply -f gateways/gg-mgmt-gatewayclass.yaml

# Install Gateway-1
kubectl --context ${MGMT} apply -f gateways/gw-1.yaml

# Install Gateway-2
kubectl --context ${MGMT} apply -f gateways/gw-2.yaml

# #K8S Gateway API
# kubectl create namespace ingress-gw --dry-run=client -o yaml | kubectl apply -f -
# kubectl apply -f gateways/gateway-parameters.yaml
# kubectl apply -f gateways/gw.yaml

# Policies/RouteOptions
kubectl --context ${MGMT} apply -f policies/route-option-gw1.yaml
kubectl --context ${MGMT} apply -f policies/route-option-gw2.yaml

# HTTPRoute
printf "\nDeploy Root HTTPRoute ...\n"
kubectl --context ${MGMT} apply -f routes/httpbin-root-gw1-httproute.yaml

printf "\nDeploy Root HTTPRoute ...\n"
kubectl --context ${MGMT} apply -f routes/httpbin-root-gw2-httproute.yaml


# Deploy child routes directly on the cluster.
printf "\nDeploy Child HTTPRoutes on workload clusters ...\n"
kubectl --context $CLUSTER1 apply -f routes/httpbin-child-httproute.yaml
kubectl --context $CLUSTER2 apply -f routes/httpbin-child-httproute.yaml

printf "\nSetup complete. Expose the Gateways on the workload clusters to access the HTTPBin application ...\n"

popd
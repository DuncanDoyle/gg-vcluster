#!/bin/sh

source ./export-cluster-env-vars.sh

if [ -z "$GLOO_MESH_LICENSE_KEY" ]
then
   echo "Gloo MESH License Key not specified. Please configure the environment variable 'GLOO_MESH_LICENSE_KEY' with your Gloo Mesh License Key."
   exit 1
fi

# The Mgmt Server is exported from the host to the workload vclusters using the given name.
export GLOO_MGMT_SERVER_IP=$(kubectl --context ${MGMT} -n gloo-mesh get service/gloo-mesh-mgmt-server -o jsonpath='{.spec.clusterIP}')

export ENDPOINT_GLOO_MESH=$GLOO_MGMT_SERVER_IP:9900
export HOST_GLOO_MESH=$GLOO_MGMT_SERVER_IP

# Install Gloo Gateway on Cluster1
kubectl config use-context $CLUSTER1
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
glooctl install gateway \
  --version 1.17.16 \
  --values -<<EOF
discovery:
  enabled: false
gatewayProxies:
  gatewayProxy:
    disabled: true
gloo:
  disableLeaderElection: true
kubeGateway:
  enabled: true
EOF

# Install Gloo Mgmt Agent on Cluster1
helm upgrade --install gloo-platform-crds gloo-platform-crds \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --create-namespace \
  --kube-context ${CLUSTER1} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85

helm upgrade --install gloo-platform gloo-platform \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --kube-context ${CLUSTER1} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85 \
  -f -<<EOF
common:
  cluster: cluster1
glooAgent:
  enabled: true
  extraEnvs:
    RELAY_DISABLE_SERVER_CERTIFICATE_VALIDATION:
      value: "true"
    RELAY_TOKEN:
      value: "Relay token"
  relay:
    serverAddress: "${ENDPOINT_GLOO_MESH}"
    authority: gloo-mesh-mgmt-server.gloo-mesh
EOF


# Install Gloo Gateway on Cluster2
kubectl config use-context $CLUSTER2
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
glooctl install gateway \
  --version 1.17.16 \
  --values -<<EOF
discovery:
  enabled: false
gatewayProxies:
  gatewayProxy:
    disabled: true
gloo:
  disableLeaderElection: true
kubeGateway:
  enabled: true
EOF

# Install Gloo Mgmt Agent on Cluster2
helm upgrade --install gloo-platform-crds gloo-platform-crds \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --create-namespace \
  --kube-context ${CLUSTER2} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85

helm upgrade --install gloo-platform gloo-platform \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --kube-context ${CLUSTER2} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85 \
  -f -<<EOF
common:
  cluster: cluster2
glooAgent:
  enabled: true
  extraEnvs:
    RELAY_DISABLE_SERVER_CERTIFICATE_VALIDATION:
      value: "true"
    RELAY_TOKEN:
      value: "Relay token"
  relay:
    serverAddress: "${ENDPOINT_GLOO_MESH}"
    authority: gloo-mesh-mgmt-server.gloo-mesh
EOF

kubectl config use-context $MGMT
#!/bin/sh

source ./export-cluster-env-vars.sh


if [ -z "$GLOO_MESH_LICENSE_KEY" ]
then
   echo "Gloo MESH License Key not specified. Please configure the environment variable 'GLOO_MESH_LICENSE_KEY' with your Gloo Mesh License Key."
   exit 1
fi

# First, install Gateway API and Gloo Gateway on the management cluster to make sure CRDs are present:

kubectl config use-context $MGMT
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
EOF

# Install Gloo Mesh CRDS
helm upgrade --install gloo-platform-crds gloo-platform-crds \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --create-namespace \
  --kube-context ${MGMT} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85

helm upgrade --install gloo-platform gloo-platform \
  --repo https://storage.googleapis.com/gloo-platform-dev/platform-charts/helm-charts \
  --namespace gloo-mesh \
  --kube-context ${MGMT} \
  --version 2.7.0-beta1-2024-11-18-gg-config-distribution-07bf4f3f85 \
  -f -<<EOF
licensing:
  glooTrialLicenseKey: ${GLOO_MESH_LICENSE_KEY}
common:
  cluster: mgmt
glooMgmtServer:
  enabled: true
  extraEnvs:
    RELAY_DISABLE_CLIENT_CERTIFICATE_AUTHENTICATION:
      value: "true"
    RELAY_TOKEN:
      value: "Relay token"
  ports:
    healthcheck: 8091
  agents:
    - name: cluster1
      domain: cluster.local
    - name: cluster2
      domain: cluster.local
glooUi:
  enabled: true
  serviceType: LoadBalancer
EOF

kubectl --context ${MGMT} -n gloo-mesh rollout status deploy/gloo-mesh-mgmt-server


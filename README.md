# Gloo Gateway Multicluster

## Prerequisit

To run this demo, you will need to have access to a Kubernetes cluster. In this guide, the name of our Kubernetes context, which is used in our scripts, `kubectl`, `glooctl` and `meshctl` command is: `gg-vcluster`. This value is also set as the `${MGMT}` environment variable in our `install/export-cluster-env-vars.sh` script.

## Setup the VClusters

To run a multicluster K8S setup on our local machine, we'll be using `vcluster`, which allows us to run multiple virtual clusters in a single minikube cluster.

After installing your K8S cluster (in this example I use Minikube), we install 2 virtual clusters:

```
cd install
```

```
./vcluster1.sh
```

```
./vcluster2.sh
```

We need to keep these terminals open to keep the virtual clusters running.

Note that these vclusters have been configured to export the Gloo Mesh Mgmt Server from the host cluster (our management cluster) to the virtual clusters, so the Gloo Mesh agents in the virtual clusters can connect to the Mgmt Server.

Next, provision the management cluster. This will install the Gloo Gateway components, the K8S Gateway API gloo management GatewayClass and the Gloo Mesh management and control plane:

```
./install-gloo-mgmt-cluster.sh
```

After this, we can provision the workload cluster. This will install Gloo Gateway, the Gloo Mesh agents on our workload clusters:

```
./install-gloo-workload-clusters.sh
```

Check that workload clusters have connected to the management/control plane:

```
. ./export-cluster-env-vars.sh
meshctl --kubecontext ${MGMT} check
```

Finally we can setup our application on our workload clusters, deploy our Gateway, HTTPRoutes, etc.:

```
cd install
./setup.sh
```

## Minikube: Expose Gateway-Proxy service

If you're running this on Minikube, you need to expose the Gateway Proxies running in the workload virtual clusters to the host system. First we need to find the names of our gateway-proxy services:

```
minikube -p {profile} service list
```

When we've found gateway proxies in the `host-namespace-1` and `host-namespace-2` namespaces, we can create a tunnel:

```
minikube -p gg-vcluster service -n host-namespace-1 gloo-proxy-gw-1-gg-config-x-gg-config-x-vcluster-1 --url
```

This will print the URL via which our gateway-proxy is accessible. We can now try to access our HTTPBin service. Replace `{url}` with the URL created with the previous command:

```
export GATEWAY_CLUSTER1={url}
```

```
curl -H "Host: httpbin" $GATEWAY_CLUSTER1/get
```
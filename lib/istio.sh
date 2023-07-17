#!/usr/bin/env bash

source "${BASH_SOURCE[0]%/*}"/logging.sh


# Configure the given cluster as an Istio primary cluster.
function istio::primary::deploy {
	local cluster_name=$1

	# Copied and adapted from
	#   https://istio.io/v1.15/docs/setup/install/multicluster/primary-remote/#configure-cluster1-as-a-primary
	# East-West gateway generated using
	#   samples/multicluster/gen-eastwest-gateway.sh --network $ISTIO_NETWORK
	while IFS= read -r line; do
		echo "     ${line}"
	done < <(istioctl install \
		--context="kind-${cluster_name}" \
		--skip-confirmation \
		-f - <<-EOM 2>&1
			apiVersion: install.istio.io/v1alpha1
			kind: IstioOperator
			spec:
			  profile: minimal
			  meshConfig:
			    trustDomain: ${ISTIO_TRUST_DOMAIN}
			  components:
			    ingressGateways:
			    - name: istio-eastwestgateway
			      enabled: true
			      label:
			        istio: eastwestgateway
			        app: istio-eastwestgateway
			        topology.istio.io/network: ${ISTIO_NETWORK}
			      k8s:
			        env:
			          # traffic through this gateway should be routed inside the network
			          - name: ISTIO_META_REQUESTED_NETWORK_VIEW
			            value: ${ISTIO_NETWORK}
			        service:
			          ports:
			            - name: status-port
			              port: 15021
			              targetPort: 15021
			            - name: tls
			              port: 15443
			              targetPort: 15443
			            - name: tls-istiod
			              port: 15012
			              targetPort: 15012
			            - name: tls-webhook
			              port: 15017
			              targetPort: 15017
			  values:
			    global:
			      meshID: ${ISTIO_MESH_ID}
			      multiCluster:
			        clusterName: ${cluster_name}
			      network: ${ISTIO_NETWORK}
			    pilot:
			      env:
			        EXTERNAL_ISTIOD: true
			    gateways:
			      istio-ingressgateway:
			        injectionTemplate: gateway
		EOM
	)
	echo

	# Copied and adapted from
	#   samples/multicluster/expose-istiod.yaml
	kubectl apply \
		--context="kind-${cluster_name}" \
		-n istio-system \
		-f - <<-EOM >/dev/null
			apiVersion: networking.istio.io/v1alpha3
			kind: Gateway
			metadata:
			  name: istiod
			spec:
			  selector:
			    istio: eastwestgateway
			  servers:
			  - port:
			      name: tls-istiod
			      number: 15012
			      protocol: tls
			    tls:
			      mode: PASSTHROUGH
			    hosts:
			    - '*'
			  - port:
			      name: tls-istiodwebhook
			      number: 15017
			      protocol: tls
			    tls:
			      mode: PASSTHROUGH
			    hosts:
			    - '*'
			---
			apiVersion: networking.istio.io/v1alpha3
			kind: VirtualService
			metadata:
			  name: istiod
			spec:
			  hosts:
			  - '*'
			  gateways:
			  - istiod
			  tls:
			  - match:
			    - port: 15012
			      sniHosts:
			      - '*'
			    route:
			    - destination:
			        host: istiod.istio-system.svc.cluster.local
			        port:
			          number: 15012
			  - match:
			    - port: 15017
			      sniHosts:
			      - '*'
			    route:
			    - destination:
			        host: istiod.istio-system.svc.cluster.local
			        port:
			          number: 443
		EOM

	log::submsg "[${cluster_name}] Configured as Istio primary"
}

# Configure the given cluster as an Istio remote cluster.
function istio::remote::deploy {
	local cluster_name=$1
	local primary_cluster_name=$2

	# Adapted from
	#   https://istio.io/v1.15/docs/setup/install/multicluster/primary-remote/#set-the-control-plane-cluster-for-cluster2
	kubectl apply \
		--context="kind-${cluster_name}" \
		-f - <<-EOM >/dev/null
			apiVersion: v1
			kind: Namespace
			metadata:
			  name: istio-system
			  annotations:
			    topology.istio.io/controlPlaneClusters: ${primary_cluster_name}
		EOM

	local pilot_addr
	pilot_addr="$(istio::primary::pilot_address ${primary_cluster_name})"

	# Copied and adapted from
	#   https://istio.io/v1.15/docs/setup/install/multicluster/primary-remote/#configure-cluster2-as-a-remote
	while IFS= read -r line; do
		echo "     ${line}"
	done < <(istioctl install \
		--context="kind-${cluster_name}" \
		--skip-confirmation \
		-f - <<-EOM 2>&1
			apiVersion: install.istio.io/v1alpha1
			kind: IstioOperator
			spec:
			  profile: external
			  meshConfig:
			    trustDomain: ${ISTIO_TRUST_DOMAIN}
			  values:
			    global:
			      remotePilotAddress: ${pilot_addr}
			    istiodRemote:
			      injectionPath: /inject/cluster/${cluster_name}/net/${ISTIO_NETWORK}
		EOM
	)
	echo

	local apiserver_addr
	apiserver_addr="https://$(kind::cluster::node_ip ${cluster_name}):6443"

	istioctl x create-remote-secret \
		--context="kind-${cluster_name}" \
		--name="${cluster_name}" \
		--server="${apiserver_addr}" \
		| kubectl apply \
			--context="kind-${primary_cluster_name}" \
			-f - >/dev/null

	log::submsg "[${cluster_name}] Configured as Istio remote"
}

# Return the address at which the remote pilot can be accessed in the given
# primary cluster.
function istio::primary::pilot_address {
	local cluster_name=$1

	local pilot_addr
	pilot_addr="$(kubectl get service \
		--context="kind-${cluster_name}" \
		-n istio-system \
		-o jsonpath='{.status.loadBalancer.ingress[0].ip}' \
		istio-eastwestgateway
	)"

	echo ${pilot_addr}
}

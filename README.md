# KinD: Istio Lab multi-cluster

Lab to experiment with multi-cluster Istio installations (multi-primary).

## Requirements

- Linux OS
- [Docker](https://docs.docker.com/)
- [KinD](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [istioctl](https://istio.io/latest/docs/setup/install/istioctl/)


## Set Up

Pre: Download Istio
```
 curl -L https://istio.io/downloadIstio | sh -
 export PATH="$PATH:/home/davar/ISTIO-MULTI/istio-lab/istio-1.18.1/bin"
```

Run the `setup-clusters.sh` script. It creates three KinD clusters:

- One ArgoCD cluster (`argocdhub`)
- Two Istio primary (`primary1`, `primary2`)

`kubectl` contexts are named respectively:

- `kind-argohub`
- `kind-primary1`
- `kind-primary2`

All three clusters are in a single Istio network `network1`.

The control plane manages the mesh ID `mesh1`.

Istiod (pilot), in the primary cluster, is exposed to remote clusters over an Istio east-west gateways backed by a
Kubernetes Service of type LoadBalancer. ArgoCD of type LoadBalance.
The IP address of this Services is assigned and advertised by [MetalLB](https://metallb.universe.tf/) (L2 mode).

Ref: [https://istio.io/latest/docs/setup/install/multicluster/primary-remote/](https://istio.io/latest/docs/setup/install/multicluster/multi-primary/)

Architecture: primary-remote

<img src="screenshots/arch.svg?raw=true" width="800">


Example Output:

```
[+] Creating KinD clusters
   ⠿ [primary1] Cluster created
   ⠿ [primary2] Cluster created
   ⠿ [argohub] Cluster created
[+] Adding routes to other clusters
   ⠿ [argohub] Route to 10.20.0.0/24 added
   ⠿ [argohub] Route to 10.30.0.0/24 added
   ⠿ [primary1] Route to 10.10.0.0/24 added
   ⠿ [primary1] Route to 10.30.0.0/24 added
   ⠿ [primary2] Route to 10.10.0.0/24 added
   ⠿ [primary2] Route to 10.20.0.0/24 added
[+] Deploying MetalLB inside primary
   ⠿ [argohub] MetalLB deployed
   ⠿ [primary1] MetalLB deployed
   ⠿ [primary2] MetalLB deployed
[+] Deploying Istio
     
     - Processing resources for Istio core.
     ✔ Istio core installed
     - Processing resources for Istiod.
     - Processing resources for Istiod. Waiting for Deployment/istio-system/istiod
     ✔ Istiod installed
     - Processing resources for Ingress gateways.
     - Processing resources for Ingress gateways. Waiting for Deployment/istio-system/istio-eastwestgateway
     ✔ Ingress gateways installed
     - Pruning removed resources
     ✔ Installation completeMaking this installation the default for injection and validation.

   ⠿ [primary1] Configured as Istio primary
     
     - Processing resources for Istio core.
     ✔ Istio core installed
     - Processing resources for Istiod.
     - Processing resources for Istiod. Waiting for Deployment/istio-system/istiod
     ✔ Istiod installed
     - Processing resources for Ingress gateways.
     - Processing resources for Ingress gateways. Waiting for Deployment/istio-system/istio-eastwestgateway
     ✔ Ingress gateways installed
     - Pruning removed resources
     ✔ Installation completeMaking this installation the default for injection and validation.

   ⠿ [primary2] Configured as Istio primary

```

### Verify the installation 
Ref: https://istio.io/latest/docs/setup/install/multicluster/verify/
```
$ kubectl config get-contexts 
CURRENT   NAME            CLUSTER         AUTHINFO        NAMESPACE
          kind-argohub    kind-argohub    kind-argohub    
*         kind-primary1   kind-primary1   kind-primary1   
          kind-primary2   kind-primary2   kind-primary2   

$ kubectl config use-context kind-primary2

$ kubectl get all -n istio-system
NAME                                         READY   STATUS    RESTARTS   AGE
pod/istio-eastwestgateway-74bcf5c77c-9r42w   1/1     Running   0          15m
pod/istiod-854f648b95-k7zcn                  1/1     Running   0          16m

NAME                            TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                                                           AGE
service/istio-eastwestgateway   LoadBalancer   10.255.30.79   172.18.255.10   15021:32135/TCP,15443:31777/TCP,15012:30350/TCP,15017:32723/TCP   15m
service/istiod                  ClusterIP      10.255.30.22   <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                             16m

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/istio-eastwestgateway   1/1     1            1           15m
deployment.apps/istiod                  1/1     1            1           16m

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/istio-eastwestgateway-74bcf5c77c   1         1         1       15m
replicaset.apps/istiod-854f648b95                  1         1         1       16m

NAME                                                        REFERENCE                          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/istio-eastwestgateway   Deployment/istio-eastwestgateway   <unknown>/80%   1         5         1          15m
horizontalpodautoscaler.autoscaling/istiod                  Deployment/istiod                  <unknown>/80%   1         5         1          16m

$ kubectl config use-context kind-primary1
Switched to context "kind-primary1".
$ kubectl get all -n istio-system
NAME                                         READY   STATUS    RESTARTS   AGE
pod/istio-eastwestgateway-74bcf5c77c-64hl7   1/1     Running   0          16m
pod/istiod-b86fdf46b-4445p                   1/1     Running   0          17m

NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                           AGE
service/istio-eastwestgateway   LoadBalancer   10.255.20.228   172.18.255.10   15021:31941/TCP,15443:31250/TCP,15012:31550/TCP,15017:30015/TCP   16m
service/istiod                  ClusterIP      10.255.20.56    <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                             17m

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/istio-eastwestgateway   1/1     1            1           16m
deployment.apps/istiod                  1/1     1            1           17m

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/istio-eastwestgateway-74bcf5c77c   1         1         1       16m
replicaset.apps/istiod-b86fdf46b                   1         1         1       17m

NAME                                                        REFERENCE                          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/istio-eastwestgateway   Deployment/istio-eastwestgateway   <unknown>/80%   1         5         1          16m
horizontalpodautoscaler.autoscaling/istiod                  Deployment/istiod                  <unknown>/80%   1         5         1          17m
davar@carbon:~/Documents/TRAININGS-Summer-2023/ISTIO-MULTI/GITHUB-my/kind-istio-multicluster-playground$ 



### Verifying Cross-Cluster Traffic
$ kubectl create --context=kind-primary1 namespace sample
namespace/sample created
$ kubectl create --context=kind-primary2 namespace sample
namespace/sample created
$ kubectl label --context=kind-primary1 namespace sample istio-injection=enabled
namespace/sample labeled
$ kubectl label --context=kind-primary2 namespace sample istio-injection=enabled
namespace/sample labeled
$ kubectl apply --context=kind-primary1 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
service/helloworld created
$ kubectl apply --context=kind-primary2 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
service/helloworld created
$ kubectl apply --context=kind-primary1 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l version=v1 -n sample
deployment.apps/helloworld-v1 created
$ kubectl apply --context=kind-primary2 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l version=v2 -n sample
deployment.apps/helloworld-v2 created
$ kubectl apply --context=kind-primary1     -f istio-1.18.1/samples/sleep/sleep.yaml -n sample
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
$ kubectl apply --context=kind-primary2     -f istio-1.18.1/samples/sleep/sleep.yaml -n sample
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created

kubectl exec --context=kind-primary1 -n sample -c sleep \
    "$(kubectl get pod --context=kind-primary1 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

kubectl exec --context=kind-primary2 -n sample -c sleep \
    "$(kubectl get pod --context=kind-primary2 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello


$ kubectl get pod --context=kind-primary1 -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-78b9f5c87f-drlcd   2/2     Running   0          73s
sleep-78ff5975c6-r2m24           2/2     Running   0          40s
$ kubectl get pod --context=kind-primary2 -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v2-54dddc5567-v5d77   2/2     Running   0          68s
sleep-78ff5975c6-nqs6r           2/2     Running   0          37s
$ kubectl exec --context=kind-primary1 -n sample -c sleep \
>     "$(kubectl get pod --context=kind-primary1 -n sample -l \
>     app=sleep -o jsonpath='{.items[0].metadata.name}')" \
>     -- curl -sS helloworld.sample:5000/hello
Hello version: v1, instance: helloworld-v1-78b9f5c87f-drlcd
$ kubectl exec --context=kind-primary1 -n sample -c sleep     "$(kubectl get pod --context=kind-primary1 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')"     -- curl -sS helloworld.sample:5000/hello
Hello version: v1, instance: helloworld-v1-78b9f5c87f-drlcd

$ kubectl exec --context=kind-primary2 -n sample -c sleep \
>     "$(kubectl get pod --context=kind-primary2 -n sample -l \
>     app=sleep -o jsonpath='{.items[0].metadata.name}')" \
>     -- curl -sS helloworld.sample:5000/hello
Hello version: v2, instance: helloworld-v2-54dddc5567-v5d77
$ kubectl exec --context=kind-primary2 -n sample -c sleep     "$(kubectl get pod --context=kind-primary2 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')"     -- curl -sS helloworld.sample:5000/hello
Hello version: v2, instance: helloworld-v2-54dddc5567-v5d77

```

### TODO1: Setup Kiali for Istio multicluster multi-primary environment (Note: Kiali -> Experimental support)

Note: Support for multi-cluster deployments is currently experimental and subject to change. Only the primary-remote istio deployment is currently supported.

### ArgoCD setup

<img src="screenshots/ArgoFlow.png?raw=true" width="800">

```
$  kubectl config use-context kind-argohub
Switched to context "kind-argohub"
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.4:6443   15m
$ kubectl config use-context kind-primary1
Switched to context "kind-primary1".
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.3:6443   15m
$ kubectl config use-context kind-primary2
Switched to context "kind-primary2".
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.2:6443   15m

$ diff ~/.kube/config ~/.kube/config.BACKUP
5c5
<     server: https://172.18.0.4:6443
---
>     server: https://127.0.0.1:45289
9c9
<     server: https://172.18.0.3:6443
---
>     server: https://127.0.0.1:39737
13c13
<     server: https://172.18.0.2:6443
---
>     server: https://127.0.0.1:43535

export CTX_CLUSTER1=kind-primary1
export CTX_CLUSTER2=kind-primary2
export CTX_CLUSTERHUB=kind-argohub

kubectl --context="${CTX_CLUSTERHUB}" create namespace argocd
kubectl --context="${CTX_CLUSTERHUB}" apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl config use-context kind-primary1
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
ARGOHUB=$(kubectl get svc argocd-server -n argocd -o json | jq -r .status.loadBalancer.ingress\[\].ip)

argocd login $ARGOHUB --insecure --grpc-web

$ argocd cluster add $CTX_CLUSTER1
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `kind-primary1` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0001] ClusterRole "argocd-manager-role" created    
INFO[0001] ClusterRoleBinding "argocd-manager-role-binding" created 
INFO[0006] Created bearer token secret for ServiceAccount "argocd-manager" 
Cluster 'https://172.18.0.3:6443' added
$ argocd cluster add $CTX_CLUSTER2
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `kind-primary2` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" created in namespace "kube-system" 
INFO[0001] ClusterRole "argocd-manager-role" created    
INFO[0001] ClusterRoleBinding "argocd-manager-role-binding" created 
INFO[0006] Created bearer token secret for ServiceAccount "argocd-manager" 
Cluster 'https://172.18.0.2:6443' added

### Add demo-primary1 & demo_primary2 apps via ArgoUI: Browser -> http://172.18.0.4 (Repo URL: https://github.com/adavarski/ArgoCD-GitOps-playground, Path: helm, Cluster: primary1 & primary2, Namespace: default)

$ argocd  app get demo-primary1
Name:               argocd/demo-primary1
Project:            default
Server:             https://172.18.0.3:6443
Namespace:          default
URL:                https://172.18.255.10/applications/demo-primary1
Repo:               https://github.com/adavarski/ArgoCD-GitOps-playground
Target:             HEAD
Path:               helm
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        Synced to HEAD (483d668)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME                        STATUS  HEALTH   HOOK  MESSAGE
       Service     default    demo-primary1-helm-example  Synced  Healthy        service/demo-primary1-helm-example created
apps   Deployment  default    demo-primary1-helm-example  Synced  Healthy        deployment.apps/demo-primary1-helm-example created

$ argocd  app get demo-primary2
Name:               argocd/demo-primary2
Project:            default
Server:             https://172.18.0.2:6443
Namespace:          default
URL:                https://172.18.255.10/applications/demo-primary2
Repo:               https://github.com/adavarski/ArgoCD-GitOps-playground
Target:             HEAD
Path:               helm
SyncWindow:         Sync Allowed
Sync Policy:        Automated
Sync Status:        Synced to HEAD (483d668)
Health Status:      Healthy

GROUP  KIND        NAMESPACE  NAME                        STATUS  HEALTH   HOOK  MESSAGE
       Service     default    demo-primary2-helm-example  Synced  Healthy        service/demo-primary2-helm-example created
apps   Deployment  default    demo-primary2-helm-example  Synced  Healthy        deployment.apps/demo-primary2-helm-example created


$ argocd cluster list
SERVER                          NAME           VERSION  STATUS      MESSAGE                                                  PROJECT
https://172.18.0.3:6443         kind-primary1  1.25     Successful                                                           
https://172.18.0.2:6443         kind-primary2  1.25     Successful                                                           
https://kubernetes.default.svc  in-cluster              Unknown     Cluster has no applications and is not being monitored.  

```

Screenshots:

<img src="screenshots/ArgoCD-UI-APPS.png?raw=true" width="1000">

<img src="screenshots/ArgoCD-UI-Clusters.png?raw=true" width="1000">

<img src="screenshots/ArgoCD-UI-LoadBalancer.png?raw=true" width="1000">


### ArgoCD Rollouts & Upgrade Application with Argo Rollouts (Canary Deploy)

```
### Argo Rollouts: Workload clusters

### Install kubectl plugin: Kubectl Plugin.
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

Install Argo Rollout in both workload clusters:

kubectl --context="${CTX_CLUSTER1}" create namespace argo-rollouts
kubectl --context="${CTX_CLUSTER1}" apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
kubectl --context="${CTX_CLUSTER2}" create namespace argo-rollouts
kubectl --context="${CTX_CLUSTER2}" apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

### Deploy Application Sets
kubectl apply -f argo-resources/application-set/appset-helloworld.yaml
kubectl get svc -n helloworld
kubectl apply -f multicluster-canary/istio-resources/application-set/appset-istio-resources.yaml
kubectl apply -f multicluster-canary/istio-resources/application-set/inbound-traffic/gateway.yaml 
kubectl apply -f multicluster-canary/istio-resources/application-set/inbound-traffic/virtualservice.yaml
kubectl apply -f multicluster-canary/argo-resources/rollout/appset-rollouts.yaml
kubectl get rollout -A
```

### Deploy the monitoring stack (Prometheus Operator on Workload Clusters + Install and Configure Thanos)
```
helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl config use-context kind-primary1
helm install prometheus-operator \
  --set prometheus.thanos.create=true \
  --set operator.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP \
  --set alertmanager.service.type=ClusterIP \
  --set prometheus.thanos.service.type=LoadBalancer \
  --set prometheus.externalLabels.cluster="data-producer-1" \
  bitnami/kube-prometheus

kubectl config use-context kind-primary2
helm install prometheus-operator \
  --set prometheus.thanos.create=true \
  --set operator.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP \
  --set alertmanager.service.type=ClusterIP \
  --set prometheus.thanos.service.type=LoadBalancer \
  --set prometheus.externalLabels.cluster="data-producer-2" \
  bitnami/kube-prometheus

cd multicluster-canary/monitoring
kubectl config use-context kind-argohub
kubectl create ns monitoring
helm install thanos bitnami/thanos -n monitoring --values values.yaml
$ kubectl get all -n monitoring
NAME                                         READY   STATUS             RESTARTS      AGE
pod/thanos-bucketweb-64f7c4c967-lmg69        1/1     Running            0             108s
pod/thanos-compactor-6dcb4df68-kch94         1/1     Running            0             107s
pod/thanos-minio-7bc9c95ccc-qxq77            1/1     Running            0             108s
pod/thanos-query-f89c8dbbc-nr44l             1/1     Running            0             108s
pod/thanos-query-frontend-57c779496c-n8djn   1/1     Running            0             108s
pod/thanos-ruler-0                           1/1     Running            0             106s
pod/thanos-storegateway-0                    0/1     CrashLoopBackOff   1 (11s ago)   106s

NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
service/thanos-bucketweb        ClusterIP   10.255.10.149   <none>        8080/TCP             110s
service/thanos-compactor        ClusterIP   10.255.10.175   <none>        9090/TCP             110s
service/thanos-minio            ClusterIP   10.255.10.139   <none>        9000/TCP,9001/TCP    110s
service/thanos-query            ClusterIP   10.255.10.30    <none>        9090/TCP             110s
service/thanos-query-frontend   ClusterIP   10.255.10.147   <none>        9090/TCP             110s
service/thanos-query-grpc       ClusterIP   10.255.10.52    <none>        10901/TCP            110s
service/thanos-ruler            ClusterIP   10.255.10.62    <none>        9090/TCP,10901/TCP   110s
service/thanos-storegateway     ClusterIP   10.255.10.49    <none>        9090/TCP,10901/TCP   110s

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/thanos-bucketweb        1/1     1            1           109s
deployment.apps/thanos-compactor        1/1     1            1           109s
deployment.apps/thanos-minio            1/1     1            1           109s
deployment.apps/thanos-query            1/1     1            1           109s
deployment.apps/thanos-query-frontend   1/1     1            1           109s

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/thanos-bucketweb-64f7c4c967        1         1         1       108s
replicaset.apps/thanos-compactor-6dcb4df68         1         1         1       108s
replicaset.apps/thanos-minio-7bc9c95ccc            1         1         1       108s
replicaset.apps/thanos-query-f89c8dbbc             1         1         1       108s
replicaset.apps/thanos-query-frontend-57c779496c   1         1         1       108s

NAME                                   READY   AGE
statefulset.apps/thanos-ruler          1/1     109s
statefulset.apps/thanos-storegateway   0/1     109s

$ kubectl get secret -n monitoring thanos-minio -o yaml -o jsonpath={.data.root-password} | base64 -d

Substitute this password by KEY (secret_key: KEY) in your values.yaml file, and upgrade the helm chart:

helm upgrade thanos bitnami/thanos -n monitoring \
  --values values.yaml

helm install grafana bitnami/grafana \
--set service.type=LoadBalancer \
--set admin.password=admin --namespace monitoring

Add PodMonitor and ServiceMonitor to scrape Istio Metrics

$ export CTX_CLUSTER1=kind-primary1
$ export CTX_CLUSTER2=kind-primary2
$ kubectl apply -f monitoring/monitor.yaml --context="${CTX_CLUSTER1}"
podmonitor.monitoring.coreos.com/envoy-stats-monitor created
servicemonitor.monitoring.coreos.com/istio-component-monitor created
$ kubectl apply -f monitoring/monitor.yaml --context="${CTX_CLUSTER2}"
podmonitor.monitoring.coreos.com/envoy-stats-monitor created
servicemonitor.monitoring.coreos.com/istio-component-monitor created


$ kubectl port-forward -n monitoring svc/thanos-query 9090

Browser (TANOS UI: Prom): http://localhost:9090 (prometheus)

Browser (Grafana UI): http://172.18.255.11:3000 (admin:admin)
```

## Clean local environment
```
$ kind delete cluster --name=argohub
Deleting cluster "primary1" ...
$ kind delete cluster --name=primary1
Deleting cluster "remote1" ...
$ kind delete cluster --name=primary2
Deleting cluster "remote2" .
```
### Thanks
- https://github.com/antoineco/istio-lab
- https://github.com/edubonifs/multicluster-canary

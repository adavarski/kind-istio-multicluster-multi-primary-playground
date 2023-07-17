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
   ⠿ [argohub] Cluster already exists
   ⠿ [primary2] Cluster already exists
   ⠿ [primary1] Cluster already exists
[+] Adding routes to other clusters
   ⠿ [argohub] Route to 10.20.0.0/24 already exists
   ⠿ [argohub] Route to 10.30.0.0/24 already exists
   ⠿ [primary1] Route to 10.10.0.0/24 already exists
   ⠿ [primary1] Route to 10.30.0.0/24 already exists
   ⠿ [primary2] Route to 10.10.0.0/24 already exists
   ⠿ [primary2] Route to 10.20.0.0/24 already exists
[+] Deploying MetalLB inside primary
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


### TODO2: ArgoCD Rollouts & Upgrade Application with Argo Rollouts (Canary Deploy)

### TODO3: Deploy the monitoring stack (Prometheus Operator on Workload Clusters + Install and Configure Thanos)

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

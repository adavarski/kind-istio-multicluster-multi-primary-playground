# KinD: Istio Lab multi-cluster

Lab to experiment with multi-cluster Istio installations (primary-remote).

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

- One Istio primary (`primary1`)
- Two Istio remotes (`remote1`, `remote2`)

`kubectl` contexts are named respectively:

- `kind-primary1`
- `kind-remote1`
- `kind-remote2`

All three clusters are in a single Istio network `network1`.

The control plane manages the mesh ID `mesh1`.

Istiod (pilot), in the primary cluster, is exposed to remote clusters over an Istio east-west gateway backed by a
Kubernetes Service of type LoadBalancer.
The IP address of this Service is assigned and advertised by [MetalLB](https://metallb.universe.tf/) (L2 mode).

Ref: https://istio.io/latest/docs/setup/install/multicluster/primary-remote/

Architecture: primary-remote

<img src="arch.svg?raw=true" width="800">


Example Output:

```
[+] Creating KinD clusters
   ⠿ [remote1] Cluster created
   ⠿ [primary1] Cluster created
   ⠿ [remote2] Cluster created
[+] Adding routes to other clusters
   ⠿ [primary1] Route to 10.20.0.0/24 added
   ⠿ [primary1] Route to 10.30.0.0/24 added
   ⠿ [remote1] Route to 10.10.0.0/24 added
   ⠿ [remote1] Route to 10.30.0.0/24 added
   ⠿ [remote2] Route to 10.10.0.0/24 added
   ⠿ [remote2] Route to 10.20.0.0/24 added
[+] Deploying MetalLB inside primary
   ⠿ [primary1] MetalLB deployed
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
     
     - Processing resources for Istiod remote.
     ✔ Istiod remote installed
     - Pruning removed resources
     ✔ Installation completeMaking this installation the default for injection and validation.

   ⠿ [remote1] Configured as Istio remote
     
     - Processing resources for Istiod remote.
     ✔ Istiod remote installed
     - Pruning removed resources
     ✔ Installation completeMaking this installation the default for injection and validation.

   ⠿ [remote2] Configured as Istio remote
```

### Verify the installation 
Ref: https://istio.io/latest/docs/setup/install/multicluster/verify/
```
$ kubectl config get-contexts 
CURRENT   NAME            CLUSTER         AUTHINFO        NAMESPACE
          kind-primary1   kind-primary1   kind-primary1   
          kind-remote1    kind-remote1    kind-remote1    
*         kind-remote2    kind-remote2    kind-remote2  


$ kubectl config use-context kind-remote1
Switched to context "kind-remote1".
$ kubectl get ns
NAME                 STATUS   AGE
default              Active   8m
istio-system         Active   5m23s
kube-node-lease      Active   8m19s
kube-public          Active   8m21s
kube-system          Active   8m24s
local-path-storage   Active   7m54s

$ kubectl get all -n istio-system
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/istiod   ClusterIP   10.255.20.161   <none>        15012/TCP,443/TCP   5m28s

$ kubectl config use-context kind-primary1
Switched to context "kind-primary1".

$ kubectl get all -n istio-system
NAME                                         READY   STATUS    RESTARTS   AGE
pod/istio-eastwestgateway-74bcf5c77c-rtfzm   1/1     Running   0          6m16s
pod/istiod-b86fdf46b-446xj                   1/1     Running   0          6m41s

NAME                            TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                           AGE
service/istio-eastwestgateway   LoadBalancer   10.255.10.221   172.17.255.10   15021:31406/TCP,15443:30559/TCP,15012:31479/TCP,15017:31992/TCP   6m16s
service/istiod                  ClusterIP      10.255.10.86    <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                             6m41s

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/istio-eastwestgateway   1/1     1            1           6m17s
deployment.apps/istiod                  1/1     1            1           6m41s

NAME                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/istio-eastwestgateway-74bcf5c77c   1         1         1       6m17s
replicaset.apps/istiod-b86fdf46b                   1         1         1       6m41s

NAME                                                        REFERENCE                          TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/istio-eastwestgateway   Deployment/istio-eastwestgateway   <unknown>/80%   1         5         1          6m16s
horizontalpodautoscaler.autoscaling/istiod                  Deployment/istiod                  <unknown>/80%   1         5         1          6m41s

$ kubectl get all -n metallb-system
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-84d6d4db45-7vtmk   1/1     Running   0          8m13s
pod/speaker-kwqqq                 1/1     Running   0          8m5s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webhook-service   ClusterIP   10.255.10.136   <none>        443/TCP   8m13s

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/speaker   1         1         1       1            1           kubernetes.io/os=linux   8m13s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           8m13s

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-84d6d4db45   1         1         1       8m13s

$ kubectl get svc --all-namespaces
NAMESPACE        NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                           AGE
default          kubernetes              ClusterIP      10.255.10.1     <none>          443/TCP                                                           8m47s
istio-system     istio-eastwestgateway   LoadBalancer   10.255.10.221   172.17.255.10   15021:31406/TCP,15443:30559/TCP,15012:31479/TCP,15017:31992/TCP   6m38s
istio-system     istiod                  ClusterIP      10.255.10.86    <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                             7m3s
kube-system      kube-dns                ClusterIP      10.255.10.10    <none>          53/UDP,53/TCP,9153/TCP                                            8m45s
metallb-system   webhook-service         ClusterIP      10.255.10.136   <none>          443/TCP                                                           8m22s
$ kubectl get ing --all-namespaces
No resources found

$  kubectl create --context=kind-remote1 namespace sample
namespace/sample created
$ kubectl create --context=kind-remote2 namespace sample
namespace/sample created


$ kubectl label --context=kind-remote1 namespace sample istio-injection=enabled
namespace/sample labeled
$ kubectl label --context=kind-remote2 namespace sample istio-injection=enabled
namespace/sample labeled

$ kubectl apply --context=kind-remote1 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
service/helloworld created
$ kubectl apply --context=kind-remote2 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
service/helloworld created
$ kubectl apply --context=kind-remote1 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l version=v1 -n sample
deployment.apps/helloworld-v1 created
$ kubectl apply --context=kind-remote2 -f istio-1.18.1/samples/helloworld/helloworld.yaml -l version=v2 -n sample
deployment.apps/helloworld-v2 created


$ kubectl apply --context=kind-remote1     -f istio-1.18.1/samples/sleep/sleep.yaml -n sample
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created
$ kubectl apply --context=kind-remote2     -f istio-1.18.1/samples/sleep/sleep.yaml -n sample
serviceaccount/sleep created
service/sleep created
deployment.apps/sleep created

$ kubectl get pod --context=kind-remote1 -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-78b9f5c87f-bk578   2/2     Running   0          4m54s
sleep-78ff5975c6-l5cg5           2/2     Running   0          26s
$ kubectl get pod --context=kind-remote2 -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v2-54dddc5567-jbzw9   2/2     Running   0          4m45s
sleep-78ff5975c6-pzbfk           2/2     Running   0          24s


### Verifying Cross-Cluster Traffic

kubectl exec --context=kind-remote1 -n sample -c sleep \
    "$(kubectl get pod --context=kind-remote1 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

kubectl exec --context=kind-remote2 -n sample -c sleep \
    "$(kubectl get pod --context=kind-remote2 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello


$ kubectl exec --context=kind-remote1 -n sample -c sleep \
>     "$(kubectl get pod --context=kind-remote1 -n sample -l \
>     app=sleep -o jsonpath='{.items[0].metadata.name}')" \
>     -- curl -sS helloworld.sample:5000/hello
Hello version: v2, instance: helloworld-v2-54dddc5567-jbzw9
$ kubectl exec --context=kind-remote1 -n sample -c sleep     "$(kubectl get pod --context=kind-remote1 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')"     -- curl -sS helloworld.sample:5000/hello
Hello version: v1, instance: helloworld-v1-78b9f5c87f-bk578


$ kubectl exec --context=kind-remote2 -n sample -c sleep \
>     "$(kubectl get pod --context=kind-remote1 -n sample -l \
>     app=sleep -o jsonpath='{.items[0].metadata.name}')" \
>     -- curl -sS helloworld.sample:5000/hello
Hello version: v2, instance: helloworld-v2-54dddc5567-jbzw9
$ kubectl exec --context=kind-remote2 -n sample -c sleep     "$(kubectl get pod --context=kind-remote2 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')"     -- curl -sS helloworld.sample:5000/hello
Hello version: v1, instance: helloworld-v1-78b9f5c87f-bk578

```

### TODO1: Setup a multi-cluster environment with Istio and Kiali (Experimental support)


### TODO2: ArgoCD + ArgoCD Rollouts  & Upgrade Application with Argo Rollouts (Canary Deploy)
```
$ kubectl config use-context kind-remote1
Switched to context "kind-remote1".
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.3:6443   22m
$ kubectl config use-context kind-remote2
Switched to context "kind-remote2".
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.4:6443   23m
$ kubectl config use-context kind-primary1
Switched to context "kind-primary1".
$ kubectl get endpoints
NAME         ENDPOINTS         AGE
kubernetes   172.18.0.2:6443   23m


$ diff ~/.kube/config ~/.kube/config.ORIG
5c5
<     server: https://172.18.0.2:6443
---
>     server: https://127.0.0.1:36691
9c9
<     server: https://172.18.0.3:6443
---
>     server: https://127.0.0.1:35169
13c13
<     server: https://172.18.0.4:6443
---
>     server: https://127.0.0.1:37795

export CTX_CLUSTER1=kind-remote1
export CTX_CLUSTER2=kind-remote2
export CTX_CLUSTERHUB=kind-primary1

kubectl --context="${CTX_CLUSTERHUB}" create namespace argocd
kubectl --context="${CTX_CLUSTERHUB}" apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl config use-context kind-primary1
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
ARGOHUB=$(kubectl get svc argocd-server -n argocd -o json | jq -r .status.loadBalancer.ingress\[\].ip)

argocd login $ARGOHUB --insecure --grpc-web

$ argocd cluster add $CTX_CLUSTER1
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `kind-remote1` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" already exists in namespace "kube-system" 
INFO[0001] ClusterRole "argocd-manager-role" updated    
INFO[0001] ClusterRoleBinding "argocd-manager-role-binding" updated 
Cluster 'https://172.18.0.3:6443' added
$ argocd cluster add $CTX_CLUSTER2
WARNING: This will create a service account `argocd-manager` on the cluster referenced by context `kind-remote2` with full cluster level privileges. Do you want to continue [y/N]? y
INFO[0001] ServiceAccount "argocd-manager" already exists in namespace "kube-system" 
INFO[0001] ClusterRole "argocd-manager-role" updated    
INFO[0001] ClusterRoleBinding "argocd-manager-role-binding" updated 
Cluster 'https://172.18.0.4:6443' added
$ argocd cluster list
SERVER                          NAME          VERSION  STATUS   MESSAGE                                                  PROJECT
https://172.18.0.3:6443         kind-remote1           Unknown  Cluster has no applications and is not being monitored.  
https://172.18.0.4:6443         kind-remote2           Unknown  Cluster has no applications and is not being monitored.  
https://kubernetes.default.svc  in-cluster             Unknown  Cluster has no applications and is not being monitored. 

```

### TODO3: Deploy the monitoring stack (Prometheus Operator on Workload Clusters + Install and Configure Thanos)

## Clean local environment
```
$ kind delete cluster --name=primary1
Deleting cluster "primary1" ...
$ kind delete cluster --name=remote1
Deleting cluster "remote1" ...
$ kind delete cluster --name=remote2
Deleting cluster "remote2" .
```
## [Thanks](https://github.com/antoineco/istio-lab)

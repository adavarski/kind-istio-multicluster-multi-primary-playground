#!/usr/bin/env bash

# Sets up a multi-cluster Istio lab with one primary and two remotes.
#
# Loosely adapted from:
#   https://istio.io/v1.15/docs/setup/install/multicluster/primary-remote/
#   https://github.com/istio/common-files/blob/release-1.15/files/common/scripts/kind_provisioner.sh

set -eu
set -o pipefail

source "${BASH_SOURCE[0]%/*}"/lib/logging.sh
source "${BASH_SOURCE[0]%/*}"/lib/kind.sh
source "${BASH_SOURCE[0]%/*}"/lib/metallb.sh
source "${BASH_SOURCE[0]%/*}"/lib/istio.sh


# ---- Definitions: mesh, clusters ----

ISTIO_MESH_ID=mesh1
ISTIO_NETWORK=network1
ISTIO_TRUST_DOMAIN=td1

declare -A cluster_argohub=(
  [name]=argohub
  [pod_subnet]=10.10.0.0/16
  [svc_subnet]=10.255.10.0/24
  [metallb_l2pool_start]=10
)

declare -A cluster_primary1=(
  [name]=primary1
  [pod_subnet]=10.20.0.0/16
  [svc_subnet]=10.255.20.0/24
  [metallb_l2pool_start]=30
)

declare -A cluster_primary2=(
  [name]=primary2
  [pod_subnet]=10.30.0.0/16
  [svc_subnet]=10.255.30.0/24
  [metallb_l2pool_start]=50
)

#--------------------------------------

# Create clusters

log::msg "Creating KinD clusters"

kind::cluster::create ${cluster_argohub[name]} ${cluster_argohub[pod_subnet]} ${cluster_argohub[svc_subnet]} &
kind::cluster::create ${cluster_primary1[name]} ${cluster_primary1[pod_subnet]} ${cluster_primary1[svc_subnet]} &
kind::cluster::create ${cluster_primary2[name]} ${cluster_primary2[pod_subnet]} ${cluster_primary2[svc_subnet]} &
wait

kind::cluster::wait_ready ${cluster_argohub[name]}
kind::cluster::wait_ready ${cluster_primary1[name]}
kind::cluster::wait_ready ${cluster_primary2[name]}

# Add cross-cluster routes

declare argohub_cidr
declare primary1_cidr
declare primary2_cidr
argohub_cidr=$(kind::cluster::pod_cidr ${cluster_argohub[name]})
primary1_cidr=$(kind::cluster::pod_cidr  ${cluster_primary1[name]})
primary2_cidr=$(kind::cluster::pod_cidr  ${cluster_primary2[name]})

declare argohub_ip
declare primary1_ip
declare primary2_ip
argohub_ip=$(kind::cluster::node_ip ${cluster_argohub[name]})
primary1_ip=$(kind::cluster::node_ip  ${cluster_primary1[name]})
primary2_ip=$(kind::cluster::node_ip  ${cluster_primary2[name]})

log::msg "Adding routes to other clusters"

kind::cluster::add_route ${cluster_argohub[name]} ${primary1_cidr}  ${primary1_ip}
kind::cluster::add_route ${cluster_argohub[name]} ${primary2_cidr}  ${primary2_ip}

kind::cluster::add_route ${cluster_primary1[name]}  ${argohub_cidr} ${argohub_ip}
kind::cluster::add_route ${cluster_primary1[name]}  ${primary2_cidr}  ${primary2_ip}

kind::cluster::add_route ${cluster_primary2[name]}  ${argohub_cidr} ${argohub_ip}
kind::cluster::add_route ${cluster_primary2[name]}  ${primary1_cidr}  ${primary1_ip}

# Deploy MetalLB

log::msg "Deploying MetalLB inside primary"

metallb::deploy ${cluster_argohub[name]} ${cluster_argohub[metallb_l2pool_start]}
metallb::deploy ${cluster_primary1[name]} ${cluster_primary1[metallb_l2pool_start]}
metallb::deploy ${cluster_primary2[name]} ${cluster_primary2[metallb_l2pool_start]}

# Deploy Istio

log::msg "Deploying Istio"

istio::primary::deploy ${cluster_primary1[name]}
istio::primary::deploy ${cluster_primary2[name]}


#!/usr/bin/env bash

RG_NAME='k8sftprg'
LOCATION_VALUE='australiaeast'
AKS_NAME='k8sftp'
AKS_ROLE='cluster-admin'

function destroy_all(){
   az aks delete --name ${AKS_NAME} --resource-group ${RG_NAME} --output json --yes
   az group delete --resource-group ${RG_NAME} --output json --yes
}

function build_aks(){
   echo "obtaining resource group status"
   RG_STATUS=`az group show --resource-group ${RG_NAME} --output json | \
   	jq '.properties.provisioningState' --compact-output --monochrome-output | \
   	sed 's/\"//g'` 
   
   echo "checking resource group status"
   [[ -n $RG_STATUS && $RG_STATUS == "Succeeded" ]] && echo "resource group availble" || {
      echo "creating:resource"
      az group create --location ${LOCATION_VALUE} --resource-group ${RG_NAME}
      RG_STATUS=`az group create --location ${LOCATION_VALUE} --resource-group ${RG_NAME} --output json | \
              jq '.properties.provisioningState' --compact-output --monochrome-output | \
              sed 's/\"//g'` 
      if [[ -z $RG_STATUS || $RG_STATUS != "Succeeded" ]]; then echo "failed to create RG"; exit; fi
   }
   
   echo "obtaining aks status"
   AKS_STATUS=`az aks show --name ${AKS_NAME} --resource-group ${RG_NAME} --output json | \
   	jq '.provisioningState' | \
   	sed 's/\"//g'`
   
   echo "checking aks status"
   [[ -n $AKS_STATUS && $AKS_STATUS == "Succeeded" ]] && echo "AKS working" || {
      echo "creating:aks"
      AKS_STATUS=`az aks create --name ${AKS_NAME} --resource-group ${RG_NAME} --output json | \
              jq '.provisioningState' --compact-output --monochrome-output | \
              sed 's/\"//g'` 
      echo "aks status: $AKS_STATUS"
      if [[ -z $AKS_STATUS || $AKS_STATUS != "Succeeded" ]]; then echo "failed to create AKS"; exit; fi
   }
   
   echo "obtaining kubectl path"
   KUBECTL_PATH=`which kubectl`
   
   echo "checking kubectl path"
   [[ $KUBECTL_PATH =~ .*kubectl ]] && echo "valid kubectl" || { 
      KUBECTL_STATUS=`az aks install-cli --install-location ~/bin/kubectl --output json | \
              jq '.properties.provisioningState' --compact-output --monochrome-output | \
              sed 's/\"//g'` 
      [[ $KUBECTL_STATUS != "Succeeded" ]] && echo "created AKS" ||  { echo "failed to create AKS"; exit; }
      KUBECTL_PATH=`which kubectl`
      echo ${KUBECTL_PATH:?"No valid path for KubeCTL"}
   }
   
   echo "obtaining cluster credentials"
   CLUSTER=`yq -r ".clusters[0] | select(.name==\"${AKS_NAME}\") | .name"  ~/.kube/config`
   
   echo "checking cluser credentials"
   [[ -n $CLUSTER && $CLUSTER =~ $AKS_NAME ]] && echo "Cluster registered" || {
      echo "no cluster credentials visible, better install credentials"
      az aks get-credentials --resource-group ${RG_NAME} --name ${AKS_NAME}
      #TODO add check
   }
   
   echo "obtaining role binding"
   ROLE=`kubectl get clusterrolebinding kubernetes-dashboard -n kube-system --output json | jq '.roleRef.name' --raw-output`
   
   echo "checking role binding"
   [[ -n $ROLE && $ROLE =~ $AKS_ROLE ]] && echo "valid service account" || {
      cat <<EOF
      installing cluster role binding per:
      https://pascalnaber.wordpress.com/2018/06/17/access-dashboard-on-aks-with-rbac-enabled/
      automatically executed by azure: kubectl create serviceaccount kubernetes-dashboard -n kube-system
EOF
      kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=$AKS_ROLE --serviceaccount=kube-system:kubernetes-dashboard
      #TODO add check
   }
}

function browse(){
   echo "opening browser"
   az aks browse --resource-group ${RG_NAME} --name ${AKS_NAME}
}

function build_sftp_container(){
   docker build --tag alpine-sftp-azure .
}

function run_sftp_container(){
   docker build --tag alpine-sftp-azure .
   docker run --volume data2:/data --publish 2222:22 --env USER=$USER --env PASSWORD="$OS_PASSWORD" --detach --name sftp --rm alpine-sftp-azure
}

#az login
#destroy_all
#build_aks
#browse
#build_sftp_container
#run_sftp_container

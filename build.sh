#!/usr/bin/env bash

RG_NAME='k8sftprg'
LOCATION_VALUE='australiaeast'
AKS_NAME='k8sftp'

az login

RG_STATUS=`az group show --resource-group ${RG_NAME}--output json | \
	jq '.properties.provisioningState' --compact-output --monochrome-output | \
	sed 's/\"//g'` 

[[ $RG_STATUS != "Succeeded" ]] && echo "resource group availble" || {
   echo "creating:resource"
   az group create --location ${LOCATION_VALUE} --resource-group ${RG_NAME}
   RG_STATUS=`az group create --location ${LOCATION_VALUE} --resource-group ${RG_NAME} --output json | \
           jq '.properties.provisioningState' --compact-output --monochrome-output | \
           sed 's/\"//g'` 
   if [[ $RG_STATUS != "Succeeded" ]]; then echo "failed to create RG"; exit; fi
}

AKS_STATUS=`az aks show --name ${AKS_NAME} --resource-group ${RG_NAME} --output json | \
	jq '.provisioningState' | \
	sed 's/\"//g'`
[[ $AKS_STATUS == "Succeeded" ]] && echo "AKS working" || {
   echo "creating:aks"
   AKS_STATUS=`az aks create --name ${AKS_NAME} --resource-group ${RG_NAME} --output json | \
           jq '.properties.provisioningState' --compact-output --monochrome-output | \
           sed 's/\"//g'` 
   if [[ $AKS_STATUS != "Succeeded" ]]; then echo "failed to create AKS"; exit; fi
}

KUBECTL_PATH=`which kubectl`
[[ $KUBECTL_PATH =~ .*kubectl ]] && echo "valid kubectl" || { 
   KUBECTL_STATUS=`az aks install-cli --install-location ~/bin/kubectl --output json | \
           jq '.properties.provisioningState' --compact-output --monochrome-output | \
           sed 's/\"//g'` 
   [[ $KUBECTL_STATUS != "Succeeded" ]] && echo "created AKS" ||  { echo "failed to create AKS"; exit; }
   KUBECTL_PATH=`which kubectl`
   echo ${KUBECTL_PATH:?"No valid path for KubeCTL"}
}

TOKEN=`yq --compact-output --monochrome-output '.users[] | select(.name=="clusterUser_${RG_NAME}_${AKS_NAME}").user.token' ~/.kube/config | \
	sed 's/\"//g' `
echo $TOKEN
[[ `echo $TOKEN | wc -c` =~ 33 ]] && echo "valid token" || {
   echo "invalid token, better install credentials"
   az aks get-credentials --resource-group ${RG_NAME} --name ${AKS_NAME}
   #TODO add check
}

SA_SECRET=`kubectl get serviceaccount kubernetes-dashboard -n kube-system --output=json | jq '.secrets[].name' | sed 's/\"//g'`
[[ $SA_SECRET =~ kubernetes-dashboard-token-* ]] && echo "valid SA" || {
   cat <<EOF
   installing cluster role binding per:
   https://pascalnaber.wordpress.com/2018/06/17/access-dashboard-on-aks-with-rbac-enabled/
   automatically executed by azure: kubectl create serviceaccount kubernetes-dashboard -n kube-system
EOF
   kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
   #TODO add check
}
az aks browse --resource-group ${RG_NAME} --name ${AKS_NAME}

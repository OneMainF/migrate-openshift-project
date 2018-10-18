#!/bin/bash

function usage() {

	echo "Usage: $0 [-s <source cluster>] [-d <destination cluster>] [-p <project (namespace)> [-t <source cluster token>] [-e <destination cluster token>]"
	exit 1
}

function validate_args() {

	if [ -z "${SOURCECLUSTER}" ]
	then
		echo "Source cluster not set, exiting"
		exit 1
	else
		check_cluster "${SOURCECLUSTER}"
	fi

	if [ -z "${DESTCLUSTER}" ]
	then
		echo "Destination cluster not set, exiting"
		exit 1
	else
		check_cluster "${DESTCLUSTER}"
	fi

	if [ -z "${DESTTOKEN}" ]
	then
		echo "Destination token not set, exiting"
		exit 1
	fi

	if [ -z "${SOURCETOKEN}" ]
	then
		echo "Source token not set, exiting"
		exit 1
	fi

	if [ -z "${THISPROJECT}" ]
	then
		echo "OpenShift project (namespace) not set, exiting"
		exit 1
	fi

}

function check_cluster() {
	THISCLUSTER=$1

	if [ "$(curl -sk -I "${THISCLUSTER}" | grep -c "^HTTP/1.1 403 Forbidden")" != "1" ]
	then
		echo "Failed to connect to ${THISCLUSTER}"
		exit 1
	fi

}

function cleanUp() {

	rm -r "${THISPROJECT:?}"_*.yaml

}

## No arguments passed, show usage
if [ $# -eq 0 ];
then
	usage
fi

## Get args
while getopts ":s:d:p:t:e:" o; do
	case "${o}" in
	s)
		SOURCECLUSTER=${OPTARG}
		;;
	d)
		DESTCLUSTER=${OPTARG}
		;;
	p)
		THISPROJECT=${OPTARG}
		;;
	t)
		SOURCETOKEN=${OPTARG}
		;;
	e)
		DESTTOKEN=${OPTARG}
		;;
	*)
		usage
		;;
	esac
done

validate_args

echo "Log into ${SOURCECLUSTER}"
oc login "${SOURCECLUSTER}" --token="${SOURCETOKEN}" > /dev/null
RES="$?"

if [ "${RES}" -gt "0" ]
then
	echo "Failed to login to ${SOURCECLUSTER}"
	exit 1
fi

##stmt:Collect name
if [ "$(oc projects | grep -v "^Using" | grep -c " ${THISPROJECT} - ")" == "1" ]
then
	##stmt:Collect
	echo "Getting objects from ${THISPROJECT} in ${SOURCECLUSTER}"
	oc export project "${THISPROJECT}" -o yaml > "${THISPROJECT}"_project_init.yaml
	oc export all -o yaml -n "${THISPROJECT}" > "${THISPROJECT}"_project.yaml
	oc get rolebindings -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_rolebindings.yaml
	oc get serviceaccount -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_serviceaccount.yaml
	oc get secret -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_secret.yaml
	oc get pvc -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_pvc.yaml
	oc get configmap -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_configmap.yaml
	oc get cronjob -o yaml --export=true -n "${THISPROJECT}" > "${THISPROJECT}"_cronjob.yaml

	oc login "${DESTCLUSTER}" --token="${DESTTOKEN}" > /dev/null
	RES="$?"

	if [ "${RES}" -gt "0" ]
	then
		echo "Failed to login to ${DESTCLUSTER}"
		exit 1
	fi

	if [ "$(oc projects | grep -v "^Using" | grep -c " ${THISPROJECT} - ")" == "0" ]
	then
		##stmt:Recreate
		echo "Creating ${THISPROJECT} in ${DESTCLUSTER}"
		oc create -f "${THISPROJECT}"_project_init.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_project.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_secret.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_configmap.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_serviceaccount.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_pvc.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_rolebindings.yaml -n "${THISPROJECT}"
		oc create -f "${THISPROJECT}"_cronjob.yaml -n "${THISPROJECT}"

		cleanUp
	else
		echo "${THISPROJECT} already exists on ${DESTCLUSTER}"
		cleanUp
		exit 1
	fi
else
	echo "Project ${THISPROJECT} does not exist on the ${SOURCECLUSTER} cluster"
	exit 1
fi

exit 0

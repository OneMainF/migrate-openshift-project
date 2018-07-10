# migrate-openshift-project
A simple script to migrate an OpenShift project (namespace) from one cluster to another

At One Main when we upgrade our OpenShift cluster we will spin up a new cluster of VMs and the install the latest version of OpenShift on them.
Once we have tweaked and automated the latest version we will begin migrating projects to the new cluster.

Requirements
You will need the OpenShift Client tools installed for this script to run correctly
For RHEL run the following
`yum -y install atomic-openshift-clients`

Example usage
This example will demonstrate migrating project "cool-app" from OpenShift cluster ocp_37 to cluster ocp_39
Before you migrate you will need at access to each cluster and will also need access to create new projects.
This has only been tested with cluster-admin access.

You will also need your token from each cluster, to get the token you will need to authenticate to the cluster and get the token
`oc login https://ocp_37:8443 --username=myuser --password=mypass`
To get the token
`oc whoami -t`

`./migrateProject.sh -s https://ocp_37:8443 -d https://ocp_39:8443 -t <ocp_37_token> -e <ocp_39_token> -p cool-app`

Once the migration has finished your destination cluster will start building your applications in the new namespace.


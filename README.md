# EDCOP Bro Guide

Table of Contents
-----------------
 
* [Configuration Guide](#configuration-guide)
	* [Image Repository](#image-repository)
	* [Networks](#networks)
	* [Node Selector](#node-selector)
	* [Bro Configuration](#bro-configuration)
		* [Resource Limits](#resource-limits)
		* [CPU Pinning](#cpu-pinning)
	* [Logstash Configuration](#logstash-configuration)
	* [Redis Configuration](#redis-configuration)
	
# Configuration Guide

Within this configuration guide, you will find instructions for modifying Bro's helm chart. All changes should be made in the *values.yaml* file.
Please share any bugs or features requests via GitHub issues.
 
## Image Repository

This is the location of where the containers will be pulled from when deployed.  If you're changing these values, make sure you use the full repository name.
 
```
images:
  bro: gcr.io/edcop-public/bro:2
  logstash: docker.elastic.co/logstash/logstash:6.3.0
  redis: redis:4.0.9
  filebeat: docker.elastic.co/beats/filebeat:6.3.0
```
 
## Networks

Bro only uses 2 interfaces because it can only be deployed in passive mode. By default, these interfaces are named *calico* and *passive*. 

useHostNetworking is used in situations where container networking is insufficient (such as the lack of SR-IOV).  This allows the container to see all physical interfaces of the minions.  This has some security concerns due to the fact that Bro now have access to all physical networking.  When useHostNetworking is set, specify hostNetworkingInterface to match the physical interface of the minions being deployed to.  When useHostNetworking is specified, the container will still be joined to the Calico network, but the passive variable is ignored.

```
networks:
  overlay: calico
  passive: passive
  useHostNetworking: false
  hostNetworkingInterface: eth0
```
 
To find the names of your networks, use the following command:
 
```
# kubectl get networks
NAME		AGE
calico		1d
passive		1d
inline-1	1d
inline-2	1d
```


## Node Selector

This value tells Kubernetes which hosts the daemonset should be deployed to by using labels given to the hosts. Hosts without the defined label will not receive pods. Bro will only deploy to nodes that are labeled 'sensor=true'
 
```
nodeSelector:
  label: sensor
```
 
To find out what labels your hosts have, please use the following:
```
# kubectl get nodes --show-labels
NAME		STATUS		ROLES		AGE		VERSION		LABELS
master 		Ready		master		1d		v1.9.1		...,infrastructure=true
minion-1	Ready		<none>		1d		v1.9.1		...,sensor=true
minion-2	Ready		<none>		1d		v1.9.1		...,sensor=true
```

## Bro Configuration

Bro is used as a passive network security monitoring tool, so no advanced configuration is required for accepting traffic. Clusters that run Bro will need 2 networks: an overlay and passive tap network. 

### Resource Limits

You can set limits on Bro to ensure it doesn't use more CPU/memory space than necessary. Finding the right balance can be tricky, so some testing may be required. Limits are strictly enforced by Kubernetes.  If you are using CPU pinning make sure the limits match up with the number of resources assigned.

```
broConfig:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 2
    memory: 4G
```


Bro performance can be greatly increased by "pinning" CPU cores.  When pinning cores, it is necessary to plan which cores can be exclusively by Bro.  When you setCPUAffinity to false the Linux scheduler will be used and pinCpus and lbprocs will be ignored. Generally you want to pin both the core and the corresponding hyperthreaded core on modern system.  The correct syntax for pin cpus is "1,2,5,6".  LBprocs should match the number of cores (including hyperthreaded cores).

```
broConfig:
  setCpuAffinity: false
  pinCpus: 0
  lbProcs: 0
```

## Logstash Configuration

Logstash is currently included in the Daemonset to streamline the rules required for the data it ingests. Having one Logstash instance per node would clutter rules and cause congestion with log filtering, which would harm our events/second speed. This instance will only deal with Bro's logs and doesn't need complicated filters to figure out which tool the logs came from.
Please make sure to read the [Logstash Performance Tuning Guide](https://www.elastic.co/guide/en/logstash/current/performance-troubleshooting.html) for a better understanding of managing Logstash's resources. 

```
logstashConfig:
  threads: 2 
  batchCount: 250
  initialJvmHeap: 4g
  maxJvmHeap: 4g
  pipelineOutputWorkers: 2 
  pipelineBatchSize: 150  
  limits:
    cpu: 2
    memory: 8G
```

## Redis Configuration

Redis is also included in the Daemonset for the same reasons Logstash is. Currently, you can only limit the resources of Redis in this section, but in the future we would like to add configmaps for tuning purposes. 

```
redisConfig:
  limits:
    cpu: 2
    memory: 8G
```

 

# Installing Bro Packages
Bro has the ability to add various packages to increase functionality of the tool.  It is possible to add packages to the official EDCOP images by simply extending the images and creating your own.  To do this it will be necessary to have access to your own container repository (Docker Hub, or internally host repository will bot work).  Bro uses a [multi-stage container](https://docs.docker.com/develop/develop-images/multistage-build/).  What this means is that when the container is built, there is actually two containers that are created.  The first container downloads all the necessary development tools, builds Bro and then installs Bro packages using the Bro package manager.  When these tasks are completed, a new container is created that then copies the output of the the Bro directory over to the new container.  The purpose of this process is to ensure the final container is kept as lightweight as possible by keeping the development packages and build tools out.

The build container in the Dockerfile begins with 

```
FROM centos:latest AS build
```

The final container 

```
FROM centos:latest
```

To download the containers for modifying run the command:
```
git clone https://github.com/sealingtech/EDCOP-BRO
```

## Adding packages
All packages are different as far as what is required to make them work, some require specific packages, others require configuration changes to be made.  First step is to figure out which packages are needed by a specific.  Generally, if you need additional packages in the build container it will be necessary to add the development package (doesn't hurt to add the library packages as well).  The final container will only need the libraries.

For example, for the Redis package ensure in the build container on the yum install line you include hiredis-devel and hiredis.

```
yum -y install ...... hiredis-devel hiredis
```

In the final container install only the library package

```
yum -y install ...... hiredis
```

To build the container from the EDCOP-BRO/container directory run the command:
docker build -t <name of image> .

If there are errors when building packages, there will be a section on the build process that will output the messages from the build logs of each plugin.  Look for the following lines in the output:

```
Step 7/22 : RUN echo "********Log files for Bro Packages*********" &&     for i in $(find /root/.bro-pkg/logs/); do echo "***Bro Log file: $i"; cat $i; done;
 ---> Running in d8be4c589ba9
********Log files for Bro Packages*********
***Bro Log file: /root/.bro-pkg/logs/
```

Push this container to your Docker repository following the instructions of the repository provider.  When deploying the tool, simply update the images.bro option to point to your Docker repository.

# Configuring individual plugins
The configuration process will be different for each plugin and therefore difficult to prescribe a single method (some don't require any configuration).  Configuration files are often configured when the containers are created through configuration maps in Kubernetes.  If the package you are installing requires either of these it will be necessary to apply these configurations through a configuration map. To configure these, it will be necessary to modify the following files. 

Directory mounted: /usr/local/bro/etc/
Configmap: bro/templates/bro-etc-config.yaml

Directory mounted: /usr/local/bro/share/bro/site/
Configmap: bro/templates/bro-site-config.yaml

Modify these files with the necessary configurations changes in their corresponding files.  If there is an additional directories needed, it is possible to add a separate configuration map, and then mount it accordingly in the bro-daemonset.yaml.  It will be necessary to create your own Helm repository to host the new file.




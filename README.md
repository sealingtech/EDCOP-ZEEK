# EDCOP Bro Guide

Table of Contents
-----------------
 
* [Configuration Guide](#configuration-guide)
	* [Image Repository](#image-repository)
	* [Networks](#networks)
	* [Persistent Storage](#persistent-storage)
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

By default, images are pulled from *edcop-master:5000* which is presumed to be hosted on the master node. If you're changing these values, make sure you use the full repository name.
 
```
images:
  bro: gcr.io/edcop-public/bro:2
  logstash: docker.elastic.co/logstash/logstash:6.3.0
  redis: redis:4.0.9
  filebeat: docker.elastic.co/beats/filebeat:6.3.0
```
 
## Networks

Bro only uses 2 interfaces because it can only be deployed in passive mode. By default, these interfaces are named *calico* and *passive*. 

```
networks:
  overlay: calico
  passive: passive
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

## Persistent Storage

These values tell Kubernetes where Bro's logs should be stored on the 
host for persistent storage. The *spool* option is for Bro's current 
logs and the *logs* option is for Bro's old logs. By default, these values are set to */var/EDCOP/data/logs/bro* but should be changed according to your logical volume setup. 

```
volumes:
  logs:
    spool: 
      hostPath: /var/EDCOP/data/logs/bro/spool
    logs: 
      hostPath: /var/EDCOP/data/logs/bro/logs   
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

You can set limits on Bro to ensure it doesn't use more CPU/memory space than necessary. Finding the right balance can be tricky, so some testing may be required. 

```
broConfig:
  limits:
    cpu: 2
    memory: 4G
```

### CPU Pinning

Bro should be pinned to a number of CPU cores depending on your NUMA node setup to prevent cache thrashing and boost performance. Cores should be entered as a comma separated list in ascending order without spaces. 

```
broConfig:
  limits:
    ...
    pin-cpus: 27,28,29,30,31,32,33,34
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

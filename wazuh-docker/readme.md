# Wazuh Docker Container Build

I have to rebuild the container so it will install the OSS Filebeat instead of elastic's version, otherwise you will get the following error from `/var/log/filebeat`:

```
2019-06-07T20:35:18.113Z        ERROR   pipeline/output.go:100  Failed to connect to backoff(elasticsearch(https://odfe-node1:9200)): Connection marked as failed because the onConnect callback failed: cannot retrieve the elasticsearch license: error from server, response code: 500
```

This is a direct copy from here: https://github.com/wazuh/wazuh-docker/tree/3.9.0_6.7.2/wazuh

The only change made was in the Dockerfile `ARG FILEBEAT_VERSION=6.7.2` to `ARG FILEBEAT_VERSION=oss-6.7.1`
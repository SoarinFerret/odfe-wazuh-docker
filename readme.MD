# Opendistro for Elasticsearch with Wazuh

I recently got ODFE with Wazuh working in my homelab and it was a struggle fighting some of the more obscure issues. This project documents how I got everything working in a _hopefully_ reproducable manor.

## What Services are Setup

The following are setup after starting the docker-compose file:

  * Opendistro for Elasticsearch
  * ODFE-Kibana (updated to include Wazuh plugin)
  * Logstash-OSS
  * Wazuh (updated to use filebeat-oss)

# Install / Setup

Before you even try, no, you can not just git clone this and be up and running. Here the major outline of steps:

  - Clone this Repo
  - Generate certs for ODFE
  - Update any config with `.default` as the extension
    * `kibana-configs/kibana.yml`
    * `logstash-configs/01-wazuh-remote.conf`
    * `odfe-configs/es-config.yml`
    * `odfe-configs/internal_users.yml`
    * `odfe-configs/security-config.yml`
    * `wazuh-configs/filebeat.yml`
    * `wazuh-configs/wazuh.env`
  - Run `docker-compose up -d`
  - Apply the elasticsearch template for Wazuh
  - Add clients to wazuh
  - Profit??

To see an actual guide, please refer to [here](guide.md)

# TODO

List of things I still need to fix/adjust:

  * SSL verification is disabled by default. Probably just need to either update the hostnames or how I generate the certs
  * Logstash is not being secured with certs as of right now.
  * Probably should be more restrictive in handing out roles and permissions to things
  * Finish guide with adding agents section

# References

Here is a list of the major references used that I can remember off the top of my head.

  * [Wazuh Docs](https://documentation.wazuh.com/3.x/getting-started/index.html)
    * [Search Guard Setup](https://documentation.wazuh.com/3.9/installation-guide/installing-elastic-stack/protect-installation/searchguard.html)
    * [Wazuh Docker Deployment](https://documentation.wazuh.com/3.9/docker/wazuh-container.html)
  * [ODFE Docs](https://opendistro.github.io/for-elasticsearch-docs/)
    * [Docker Security Configuration](https://opendistro.github.io/for-elasticsearch-docs/docs/install/docker-security/)
  * [Search Guard Docs](https://docs.search-guard.com/latest/)
  * The following Github Issue threads:
    * [Too many doc types coming from Wazuh to ODFE](https://github.com/wazuh/wazuh/issues/3032) (and the pull request linked)

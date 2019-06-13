# The Guide

This guide is essentially my bash history nicely explained when I did this. I did this using an Ubuntu 18.04.2 server host up to date as of 6/8/19

I'm warning you now:

**_DO NOT RUN THIS AS ROOT_**

Besides obvious reasons like it being a security concern, this process includes building some images for Wazuh and Kibana. If you run that as roots, permissions in the container will be messed up, and its a pain to go through to try and fix it all. Just save yourself the trouble and run as local user.

## 0. Prerequistes

First things first, you need the following installed:

  * Docker
  * Docker Compose
  * Openssl (for generating the certs for ODFE)

## 1. Clone the repo

```bash
git clone https://github.com/SoarinFerret/odfe-wazuh-docker
cd ./odfe-wazuh-docker
```

## 2. Generate the Certificates

You need to generate a series of certificates for Opendistro for Elasticsearch's security plugin. Included is a script called `buildcerts.sh` under tools that can generate the certs for you.

The script takes 3 parameters. Make sure you remember what you put, you will need this later.

  * Country Code: Your 2 digit country code, like `US` or `GB`
  * Organization: Your organization name. This can be anything, like something as simple as `Homelab`
  * Top Level Domain: This will be the TLD for the `odfe-node1` certificate. For example, using `example.com` will result in a cert named `odfe-node1.example.com`.

To use the script:

```bash
cd ./certs
../tools/buildcerts.sh US 'The Best Homelab' 'example.com'
```

This will result in the following files being created:

```
admin-key.pem
admin.pem
odfe-node1-key.pem
odfe-node1.pem
root-ca-key.pem
root-ca.pem
root-ca.srl
```

The docker-compose files expect these names.

## 3. Update the Config Files

Throughout the subdirectories, there are a series of files with the extension of `.default`. Everything is tagged with a 'TODO' comment for things that need to be updated.

You will need to rename the files without the `.default` extension and use the following steps to update things appropriately.

### ODFE Configs

There are 3 configs to update: `es-config.yml`, `internal_users.yml`, and `security-config.yml`. In addition, 2 addition files exist: `roles_mapping.yml` and `roles-wazuh.yml`. You do not NEED to update anything in these files - but you are more than welcome to.

#### ES-CONFIG.YML

There are 2 options to update in this file: `opendistro_security.authcz.admin_dn` and `opendistro_security.nodes_dn`. These require the subject line from the previous the `buildcerts.sh` tool.

For example, if I used `buildcerts.sh US 'The Best Homelab' 'example.com'`, then:

  * `opendistro_security.authcz.admin_dn` becomes `'CN=ADMIN,O=The Best Homelab,C=US'`
  * `opendistro_security.nodes_dn` becomes `'CN=*.example.com,O=The Best Homelab,C=US'`

#### INTERNAL_USERS.YML

This file stores the user accounts created and their passwords.

To generate a new password, use the following (be sure to change the password):

```
docker run --rm -it amazon/opendistro-for-elasticsearch:0.9.0 /bin/bash -c 'chmod +x ./plugins/opendistro_security/tools/hash.sh; ./plugins/opendistro_security/tools/hash.sh -p YOUR_PASSWORD_HERE'
```

Then simply update the hash for each user. Default passwords are included.

#### SECURITY-CONFIG.YML

This is more up to you how you want to do this. Personally, I am a 'if it can use SAML, it will' kind of person. I have included the settings I used for ADFS, but you are more than welcome to change it to something else.

I recommend the following docs:

  * [Search Guard Configuration Docs](https://docs.search-guard.com/latest/authentication-authorization)
  * [ODFE Docs](https://opendistro.github.io/for-elasticsearch-docs/docs/security-configuration/)

On a separate note, I am NOT happy with the included SAML auth provider. In the future, I think I may put an Apache MOD_AUTH_MELLON proxy in front of kibana and use the `xff` auth provider.

### Kibana Config

Only one file to update here: `kibana.yml`

#### KIBANA.YML

2 main things to update: `server.name` and `elasticsearch.password`. These should be pretty self explainatory. If you want to enable the saml provider, the settings are commented out at the bottom.

### Wazuh Configs

The main files you need to update here is `filebeat.yml` and `wazuh.env`. There are other included files, please see [this doc](wazuh-configs/readme.md) for why they are included and any default settings that were changed.

#### FILEBEAT.YML

I have included 2 different outputs in this file: elasticsearch and logstash. I could not get the elasticsearch output to work correctly, so as of right now I am recommending you use the logstash config. If you choose to use the logstash output, then the default is fine.

However, you do need to perform 2 steps before continuing. Filebeat is VERY particular about its settings file permissions, so go ahead and run this:

```bash
sudo chown root:root ./wazuh-configs/filebeat.yml
sudo chmod go-w ./wazuh-configs/filebeat.yml
```

#### WAZUH.ENV

This file sets the API user and password using environment variables. Its highly recommended you change it from `foo` and `bar`.

_I haven't found a document saying what all environment variables you can use, so this is what I'm using for now, but it would be nice if they published one._

### Logstash Configs

One file you need to update is `01-wazuh-remote.conf`.

#### 01-WAZUH-REMOTE.CONF

One line to update: under output, change the elasticsearch password.

### Docker-Compose

Shouldn't be alot you need to change here. Only thing is I gave ODFE 8GBs of RAM for its Java heap size - you are more than welcome to adjust this to your needs. This line `ES_JAVA_OPTS=-Xms8g -Xmx8g` is what you are looking to modify.

## 4. Bringing Up the Services

If you haven't already, be sure to update the memory mapping for docker, otherwise ODFE will crash.

```bash
sudo sysctl -w vm.max_map_count=262144
```

Run the following to bring up the services:

```bash
docker-compose up -d
```

Wait a couple of minutes for ODFE to come up.

Check if ODFE is running (update the admin password before running):

```bash
curl -XGET https://127.0.0.1:9200 -u admin:admin -k
```

## 5. Applying the ODFE ES Template & Setting up GeoIP

[This template](https://github.com/emhlbmc/wazuh/blob/fbc66c2c36dfadd4199e78aca57d47c608a8ecf3/extensions/elasticsearch/wazuh-elastic6-template-alerts.json) needs to be applied. Its from the same [pull request](https://github.com/wazuh/wazuh/pull/2382) as the logstash `01-wazuh-remote.conf` file.

I have also included the file as `es-6-alert-template.json` in this repo for completeness.

Be sure to update the admin password:

```bash
cat es-6-alert-template.json | curl -X PUT https://127.0.0.1:9200/_template/wazuh -u admin:admin -k -H 'Content-Type: application/json' -d @-
```

The result should say: `{"acknowledged":true}`

### Setup GeoIP

This is probably optional, but I still did it so its included:

```bash
curl -X PUT https://127.0.0.1:9200/_ingest/pipeline/geoip -u admin:admin -k -H 'Content-Type: application/json' -d'
{
    "description" : "Add geoip info",
    "processors" : [
        {
            "geoip" : {
                "field" : "@src_ip",
                "target_field": "GeoLocation",
                "properties": ["city_name", "country_name", "region_name", "location"],
                "ignore_missing": true,
                "ignore_failure" : true
            }
        },
        {
            "remove": {
                "field": "@src_ip",
                "ignore_missing": true,
                "ignore_failure" : true
            }
        }
    ]
}
'
```

## 6. Logging into Kibana

At this point, you should be able to sign into Kibana and do things. Go to `https://<SERVERIP>:5601`. You will get a warning about using a self-signed certificate - just accept and continue. You can sign in using pretty much any of the accounts defined within the `internal_users.yml` file.

If not, I would begin troubleshooting that before continuing.

However, if you can sign in, congrats! Now lets take a look at Wazuh.

## 7. Logging into the Kibanan Wazuh Plugin and Adding Agents

**_Before continuing, switch your default tenant to Global_**

Go to Tenants and click 'select' to change your tenant.

### Kibana Wazuh Plugin

On the left hand side, you will see a Wazuh icon / app / plugin. Go ahead and click on that, and fill in the information:

```
User: foo (or what you changed it to in wazuh.env)
Password: bar (or what you changed it to in wazuh.env)
API Url: https://<yourip>
API Port: 55000
```

From here, you should be able to see you have basically nothing configured.

### Adding Agents

TODO


## Miscellaneous Issues

### Settings. 3005 - Wrong protocol being used to connect to the Wazuh API (/api/check-api)

Had this happen to me on a digital ocean instance. After pulling my hair out for what seemed like 2 hours, ended up being UFW issue. To fix it:
```bash
ufw allow 55000/tcp
```
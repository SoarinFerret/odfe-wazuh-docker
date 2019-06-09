# Logstash Configs

## 01-wazuh-remote.conf

Config I got from this [pull request](https://github.com/wazuh/wazuh/pull/2382)

  * Direct link to the file: https://github.com/emhlbmc/wazuh/blob/fbc66c2c36dfadd4199e78aca57d47c608a8ecf3/extensions/logstash/01-wazuh-local.conf


## logstash.conf

Included only because its included in the base image - this simply overwrites the port to 5043 which is not being referenced. I wanted to include wazuh with the existing naming scheme instead of overwriting it to be `logstash.conf`, which would be confusing after expanding to additional services.
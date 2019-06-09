# Wazuh Configs

## Filebeat.yml

Make sure to do the following, otherwise wazuh will fail to run `filebeat.yml`:
```
sudo chown root:root ./filebeat.yml
sudo chmod go-w ./filebeat.yml
```

## Fortigate Decoders

These 2 files simply override the built-in fortigate decoders from this [pull request](https://github.com/wazuh/wazuh-ruleset/pull/147).

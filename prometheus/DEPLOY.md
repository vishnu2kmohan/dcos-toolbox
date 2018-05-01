```
dcos marathon app add prometheus.json
dcos marathon app add prom-statsd-exporter.json
```

Use `dcos node` to verify the list of Masters and Agents

Generate the list of DC/OS Agents in Prometheus `target` format
```
dcos node --json | jq -er '.[].hostname' | sed -e 's/^/    - /' -e 's/$/:61091/' | grep -v null
```

Edit `prometheus.yml` and add the values from above (incl. the values for the Masters, manually)

Remotely exec into the prometheus container and edit its configuration
```
dcos task exec -it dcos_prometheus_prometheus sh
```

```
cd /etc/prometheus
mv prometheus.yml prometheus.yml.bak
cat > prometheus.yml << "EOF"
<paste contents from your prometheus.yml>
EOF
kill -HUP $(pgrep prometheus)
```

Verify that all Prometheus targets are healthy

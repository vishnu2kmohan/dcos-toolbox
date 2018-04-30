```
dcos marathon app add grafana.json
```

Register Prometheus as a Datasource for Grafana

While SSH'ed into a node (e.g., Mesos Leader with `dcos node ssh --master-proxy --leader`) in the cluster:

```
curl -fsSL -H "Content-Type: application/json" -X POST -d '{"name":"Prometheus","type":"prometheus","url":"http://dcosprometheusprometheus.marathon.l4lb.thisdcos.directory:9090/service/dcos/prometheus/prometheus","access":"proxy","basicAuth":false,"isDefault":true}' http://admin:GrafanaMesos@dcosgrafanagrafana.marathon.l4lb.thisdcos.directory:3000/api/datasources
```

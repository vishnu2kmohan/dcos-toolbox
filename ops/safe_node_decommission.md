# Replace an agent node with data services and/or K8s

## 1. Get a list of nodes to decommission, have their mesos internal agent uuid ready
```
agent1-cluster111.team.acme.com 172.31.3.226  85409ae2-9f36-4738-ae5d-712bba77ebc3-S13
agent2-cluster111.team.acme.com 172.31.14.16  aaf0a62f-a6eb-4c1d-80db-5fdd26fe8008-S2
[...]
```

## 2. Move one-by-one: Set the first agent into maintenance mode
```
# taken from https://docs.mesosphere.com/1.11/administering-clusters/update-a-node/
cat <<EOF > maintenance.json
{
  "windows" : [
    {
      "machine_ids" : [
        { "hostname" : "agent1-cluster111.team.acme.com", "ip" : "172.31.3.226" }
      ],
      "unavailability" : {
        "start" : { "nanoseconds" : 1 },
        "duration" : { "nanoseconds" : 3600000000000 }
      }
    }
  ]
}
EOF
bash ../mesos/maintain-agents.sh maintenance.json
```

## 3. Issue pod replacements for each SDK based service
```
eval $(bash pod_replace_drain_agent.sh '85409ae2-9f36-4738-ae5d-712bba77ebc3-S1')
```

## 4. Check if the node is really drained from SDK services, wait just a little longer, check that the service is healthy and on a new node

## 5. Decommission node
```
dcos node decommission 85409ae2-9f36-4738-ae5d-712bba77ebc3-S13
```

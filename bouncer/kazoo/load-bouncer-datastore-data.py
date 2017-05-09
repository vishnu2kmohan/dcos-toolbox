from kazoo.client import KazooClient

DCOS_ZK_HOSTS='zk-1.zk:2181,zk-2.zk:2181,zk-3.zk:2181,zk-4.zk:2181,zk-5.zk:2181'

DCOS_ZK_AUTH_TYPE='digest'
DCOS_ZK_CREDS='super:secret'
DCOS_ZK_AUTH_DATA=[(DCOS_ZK_AUTH_TYPE, DCOS_ZK_CREDS)]

DCOS_BOUNCER_LOCK_PATH='/bouncer/datastore/locking'
DCOS_BOUNCER_DATA_PATH='/bouncer/datastore/data.json'

zk = KazooClient(hosts=DCOS_ZK_HOSTS, auth_data=DCOS_ZK_AUTH_DATA)
zk.start()
if zk.exists(DCOS_BOUNCER_DATA_PATH):
    with zk.Lock(DCOS_BOUNCER_LOCK_PATH):
        data, stat = zk.get(DCOS_BOUNCER_DATA_PATH)
    print(data.decode())
    print(stat)
zk.stop()
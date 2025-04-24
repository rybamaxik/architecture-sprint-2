#!/bin/bash

docker compose exec -T configSrv mongosh --port 27019 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27019" }
    ]
  }
);
EOF

sleep 2

docker compose exec -T shard1_1 mongosh --port 27031 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_1:27031" },
        { _id : 1, host : "shard1_2:27032" },
        { _id : 2, host : "shard1_3:27033" }
      ]
    }
);
EOF

sleep 2

docker compose exec -T shard2_1 mongosh --port 27041 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
       { _id : 0, host : "shard2_1:27041" },
       { _id : 1, host : "shard2_2:27042" },
       { _id : 2, host : "shard2_3:27043" },
      ]
    }
);
EOF

sleep 2

docker compose exec -T mongos_router mongosh --port 27017 --quiet <<EOF
sh.addShard( "shard1/shard1_1:27031");
sh.addShard( "shard2/shard2_1:27041");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
EOF

sleep 2

docker compose exec -T mongos_router mongosh --port 27017 --quiet <<EOF
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF

sleep 2

docker compose exec -T shard1_1 mongosh --port 27031 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

docker compose exec -T shard1_2 mongosh --port 27032 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

docker compose exec -T shard1_3 mongosh --port 27033 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

docker compose exec -T shard2_1 mongosh --port 27041 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

docker compose exec -T shard2_2 mongosh --port 27042 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

docker compose exec -T shard2_3 mongosh --port 27043 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8080/helloDoc/users"
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8080/helloDoc/users"

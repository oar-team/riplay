#!/bin/bash

SLEEP_TIME=$1

sleep $SLEEP_TIME
ssh root@`cat $OAR_FILE_NODES|sort -u -V|head -1` "sudo su - postgres -c 'pg_dump oar > /tmp/oar_db_dump.sql.`date +%s`'"
scp -p root@`cat $OAR_FILE_NODES|sort -u -V|head -1`:/tmp/oar_db_dump.sql.* ~/public/

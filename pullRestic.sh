#!/bin/bash
# Situation: Restic client cannot connect to server due to strict firewall,
# but server can SSH to client. Both server and client are managed servers,
# so there's no way to configure sshd or to set up containers
# Solution: Either allow client to SFTP to server (a bit risky because you
# have to restrict client in order not to mess around with your files)
# or start local Restic server and allow client to interact with it for the
# backup.

# start Restic server

nohup ${HOME}/rest-server/rest-server \
	--no-auth \
	--tls \
	--path restic-backup > /dev/null 2>&1 &

# remember Restic server PID
SPID=$!

# connect to client and forward Restic server port to it
ssh -R 127.0.0.1:8000:`hostname -f`:8000 lernraum -i .ssh/rest-server

# quit Restic server after backup has finished
kill ${SPID}

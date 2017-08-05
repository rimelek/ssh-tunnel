#!/bin/sh

: ${TUNNEL_HOST:=""}
: ${TUNNEL_REMOTES:=""}

: ${TUNNEL_HOST:?cannot be empty}
: ${TUNNEL_REMOTES:?cannot by empty}

getUser() {
  local HOST_PTRN=$1
  if [ `echo ${HOST_PTRN} | grep -c "@"` -gt 0 ]; then
    echo $(echo ${HOST_PTRN} | cut -d '@' -f 1)
  fi
}

getHost() {
  local HOST_PTRN=$1
  if [ `echo ${HOST_PTRN} | grep -c "@"` -gt 0 ]; then
     HOST_PTRN=$(echo ${HOST_PTRN} | cut -d '@' -f 2)
  fi

  echo $(echo ${HOST_PTRN}':' | cut -d ':' -f 1)
}

getPort() {
  local HOST_PTRN=$1
  echo $(echo ${HOST_PTRN}':22' | cut -d ':' -f 2)
}

TUNNEL_HOST_USER=$(getUser ${TUNNEL_HOST})
TUNNEL_HOST_HOST=$(getHost ${TUNNEL_HOST})
TUNNEL_HOST_PORT=$(getPort ${TUNNEL_HOST})

if [ "$TUNNEL_HOST_USER" = "" ]; then
  TUNNEL_HOST_USER=root
fi

COMMAND_FORWARDED_SSH='ssh -oStrictHostKeyChecking=no'

for REMOTE in ${TUNNEL_REMOTES}; do
    REMOTE_HOST=$(getHost ${REMOTE})
    REMOTE_PORT=$(getPort ${REMOTE})

    COMMAND_FORWARDED_SSH=${COMMAND_FORWARDED_SSH}' -L '\*:${REMOTE_PORT}':'${REMOTE_HOST}':'${REMOTE_PORT}
done

COMMAND_FORWARDED_SSH=${COMMAND_FORWARDED_SSH}' '${TUNNEL_HOST_USER}'@'${TUNNEL_HOST_HOST}' -p '${TUNNEL_HOST_PORT}' -N'

echo ${COMMAND_FORWARDED_SSH}
exec ${COMMAND_FORWARDED_SSH}


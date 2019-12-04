#!/bin/sh

FULLPATH=`readlink -f $0`
WDIR=`dirname $FULLPATH`

echo 1 > /proc/sys/net/mptcp/enabled

[ -f ${WDIR}/use_mptcp.so ] || make -C ${WDIR}

LD_PRELOAD=${WDIR}/use_mptcp.so $*

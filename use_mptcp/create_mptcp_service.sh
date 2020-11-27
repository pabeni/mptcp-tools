#!/bin/sh

FULLPATH=`readlink -f $0`
WDIR=`dirname $FULLPATH`
TARGET=$1

if [ -z "$TARGET" ]; then
	echo -e "syntax: $0 <service file>"
	exit -1
fi

if [ -f "$TARGET" ]; then
	SERVICE=`basename $TARGET`
	SERVICE=${SERVICE%.service}
	UNIT=$TARGET
elif [ -f /usr/lib/systemd/system/$TARGET -o -f /usr/lib/systemd/system/$TARGET.service ]; then
	SERVICE=${TARGET%.service}
	UNIT=/usr/lib/systemd/system/$SERVICE.service
fi

MPTCP_UNIT=/usr/lib/systemd/system/$SERVICE"_mptcp.service"

sed -e 's/\[Service\]/\[Service\]\nEnvironment="LD_PRELOAD='${WDIR}'/use_mptcp.so"\nExecStartPre=sysctl -w net.mptcp.enabled=1\nConflicts='$SERVICE'\nAfter='$SERVICE'\n/' $UNIT > $MPTCP_UNIT

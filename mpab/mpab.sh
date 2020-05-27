#!/bin/sh

WD=`mktemp -d`
WD_BASE=`basename $WD`
NS_SRV=$WD_BASE.srv
NS_CL=$WD_BASE.cl
NGINX_PID="$WD/nginx.pid"

FULLNAME=`readlink -f $0`
WRAPPER=`dirname $FULLNAME`/../use_mptcp/use_mptcp.sh
WRAPPER=`readlink -f $WRAPPER`

help()
{
	echo -e "syntax:\n$0 [-d] [-c] [-n <name>] [-h]\n"\
		"\t-d\t debug this script\n" \
		"\t-c\t capture traffic into pcap.dump\n" \
		"\t-h\t show this help\n"
	exit 0
}

cleanup()
{
	[ -f "$NGINX_PID" ] && nginx -c $WD/nginx.conf -s quit
	[ -f "$NGINX_PID" ] && kill -9 `cat $NGINX_PID`
	ip netns del $NS_SRV
	ip netns del $NS_CL
	[ -d "$WD" ] && rm -f $WD/*
	[ -d "$WD" ] && rmdir $WD
}

init()
{
	for NS in $NS_SRV $NS_CL; do
		ip netns add $NS
		ip -n $NS link set dev lo up
	done

	ip -n $NS_SRV link add name eth0 type veth peer name eth1 netns $NS_CL

	ID=0
	for NS in $NS_SRV $NS_CL; do
		DEV=eth$ID
		ip -n $NS link set dev $DEV up
		ID=$((ID + 1))
		ip -n $NS addr add dev $DEV 192.168.1.$ID/24
		ip -n $NS addr add dev $DEV 192.168.2.$ID/24
	done

	ip -n $NS_SRV mptcp endpoint add 192.168.2.1 dev eth0 signal
	ip -n $NS_SRV mptcp limits set subflows 2
	ip -n $NS_CL mptcp limits set subflows 2
	ip -n $NS_CL mptcp limits set add_addr_accepted 2

	dd if=/dev/null of=$WD/1K bs=1 count=1024
	dd if=/dev/null of=$WD/50K bs=50 count=1024
	dd if=/dev/null of=$WD/300K bs=300 count=1024
}

run_ab()
{
	sed -e 's/error_log .*;/error_log \/tmp\/'$WD_BASE'\/error.log;/' \
		-e 's/pid .*;/pid \/tmp\/'$WD_BASE'\/nginx.pid;/' \
		-e 's/\s*access_log .*;/    access_log \/tmp\/'$WD_BASE'\/access.log main;/' \
		-e 's/\s*root.*;/        root \/tmp\/'$WD_BASE'/' \
		-e 's/\s*include .*conf.d.*;/    include \/tmp\/'$WD_BASE'\/root.conf;/' \
		/etc/nginx/nginx.conf > $WD/nginx.conf

cat > $WD/root.conf << ENDL
server {
	listen       80;
	server_name  localhost;
	location / {
		root   $WD;
		index  index.html index.htm;
	}
}
ENDL

	# will close automatically on device removal
	[ -n "$DUMP" ] && ip netns exec $NS_SRV tcpdump -nnei eth0 -w dump.pcap &
	ip netns exec $NS_SRV $WRAPPER nginx -c $WD/nginx.conf &
	sleep 1

	ip netns exec $NS_CL $WRAPPER ab -c 100 -n 100000 192.168.1.1/1KB
	ip netns exec $NS_CL $WRAPPER ab -c 100 -n 100000 192.168.1.1/50KB
	ip netns exec $NS_CL $WRAPPER ab -c 100 -n 100000 192.168.1.1/300KB
}

while getopts "cdh" option; do
	case $option in
		c)
			DUMP=1
			;;
		d)
			set -x
			;;
		h)
			help
			;;
	esac
done

trap cleanup EXIT

init
run_ab

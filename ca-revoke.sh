#!/bin/sh

usage() {
	echo "usage: $0 CADIR CERTFILE" >&2
}

if [ $# -lt 2 ]; then
	usage
	exit 1
fi

CADIR="$1"
REALPATH="readlink -f"	# some old linux distributions without realpath by default
CERTFILE=`$REALPATH $2` # Because openssl will switch to CADIR
OPENSSL_CONF=./ca.cnf
export OPENSSL_CONF

cd $CADIR || exit 1

openssl ca -revoke $CERTFILE

exit 0

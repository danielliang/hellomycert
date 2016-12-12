#!/bin/sh

usage() {
	echo "usage: $0 CADIR" >&2
}

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

CADIR="$1"
OPENSSL_CONF=./ca.cnf
export OPENSSL_CONF

cd $CADIR || exit 1

openssl ca -gencrl -out ca.crl

exit 0

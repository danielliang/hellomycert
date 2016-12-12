#!/bin/sh

# Copyright (c) 2016 Hung-te Liang.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

usage() {
	echo "usage: $0 CADIR CSRFILE OPTIONS [DAYS]" >&2
	echo "  OPTIONS: -server|-ca" >&2
	echo "  DAYS: the number of days to certify the certificate for" >&2
}

if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    usage
    exit 1
fi

REALPATH="readlink -f"	# some old linux distributions without realpath by default
SERVEREXTS="v3_server"
CAEXTS="v3_ca"
DNPOLICY="policy_anything"

case "$3" in
-server)
	EXTS="$SERVEREXTS"
	;;
-ca)
	EXTS="$CAEXTS"
	DNPOLICY="policy_match"
	;;
*)
	usage
	exit 1
	;;
esac

DAYSOPT=""
# check if it is an INTEGER
if [ $# -eq 4 ] && [ "$4" -eq "$4" ] 2> /dev/null; then
    DAYSOPT="-days $4"
fi
 
CADIR="$1"
CSRFILE=`$REALPATH $2` # Because openssl will switch to CADIR

cd $CADIR || exit 1

OPENSSL_CONF=./ca.cnf
if ! [ -s $OPENSSL_CONF ]; then
	echo "No data in `$REALPATH $OPENSSL_CONF`, stop!" >&2
	exit 1
fi

export OPENSSL_CONF

if [ "x${DAYSOPT}" = "x" ]; then
	echo ""
	echo "How many days to to certify the certificate for?"
	echo "leave it blank to use the value of 'default_days' in [ CA_default ] of `$REALPATH $OPENSSL_CONF`"
	read -p "Days:" DAYSOPT

	# check if it is an INTEGER
	if [ "$DAYSOPT" -eq "$DAYSOPT" ] 2> /dev/null; then
		DAYSOPT="-days $DAYSOPT"
	fi
fi

eval openssl ca -extensions $EXTS -in $CSRFILE -policy $DNPOLICY $DAYSOPT || exit 1

exit 0

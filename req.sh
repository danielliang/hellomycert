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
	echo "usage: $0 OPTIONS [-selfsign [DAYS]]" >&2
	echo "  OPTIONS: -server|-ca" >&2
	echo "  DAYS: the number of days to certify the certificate for" >&2
}

if [ $# -lt 1 ] || [ $# -gt 3 ]; then
	usage
	exit 1
fi

SERVEREXTS="v3_server"
SERVEREXTS_NOSAN="v3_server_nosan"
CAEXTS="v3_ca"

case "$1" in
-server)
	EXTS="$SERVEREXTS"
	BITS=2048
	;;
-ca)
	EXTS="$CAEXTS"
	BITS=4096
	;;
*)
	usage
	exit 1
	;;
esac

SELFSIGN=0
OUTPUTYPE="CSR"

if [ $# -ge 2 ]; then
	if [ "x$2" = "x-selfsign" ]; then
		SELFSIGN=1
		OUTPUTYPE="self-signed certificate"
		DAYSOPT=""
	else
		usage
		exit 1
	fi

	# check if it is an INTEGER
	if [ $# -eq 3 ] && [ "$3" -eq "$3" ] 2> /dev/null; then
	    DAYSOPT="-days $3"
	fi
fi
		
export OPENSSL_CONF="req.cnf"
export RANDFILE=".rnd"

echo "Generating a ${OUTPUTYPE}..."
echo "1. Choose a filename prefix for the key and the ${OUTPUTYPE},"
echo "   and it will also be the default Common Name"
echo "2. Generate a new private key or use the old one"
echo "3. Generate a ${OUTPUTYPE}"
echo ""

read -p "The filename prefix: " FPREFIX

[ "x${FPREFIX}" = "x" ] && exit 1

KEYFILE=${FPREFIX}.key
if [ $SELFSIGN -eq 0 ]; then
	OUTPUTFILE=${FPREFIX}.csr
else
	OUTPUTFILE=${FPREFIX}.crt
fi

if [ -f $OUTPUTFILE ]; then
	if [ $SELFSIGN -eq 0 ]; then
		read -p "$OUTPUTFILE exist, overwrite it? [y/N]" OVERWRITECSR
		case $OVERWRITECSR in
		Y|y)
			;;
		*)
			echo "Stop. If you want to keep the old CSR, rename or delete it manually."
			exit 1
			;;
		esac
	else
		echo "Stop. The certificate is important. To generate new $OUTPUTFILE you should rename or delete the old one manually."
		exit 1
	fi
fi

if [ -f $KEYFILE ]; then
	read -p "$KEYFILE exist, use it again? [Y/n]" USEOLDKEY
	case $USEOLDKEY in 
	N|n)
		echo "Stop. The private key is important. To generate new $KEYFILE you should rename or delete the old one manually."; exit 1;;
	*)
		;;
	esac
else
	echo ""
	echo "Generating ${KEYFILE}..."
	read -p "Encrypt $KEYFILE? [y/N]" ENCRYPTKEY
	case $ENCRYPTKEY in
	Y|y)
		openssl genrsa -rand .rnd -aes256 -out $KEYFILE $BITS || exit 1 
		;;
	*)
		openssl genrsa -rand .rnd -out $KEYFILE $BITS || exit 1
		;;
	esac

	chmod 400 $KEYFILE
fi

echo ""
echo "Generating ${OUTPUTFILE}..."
export FPREFIX

# If it's for server, ask for SAN.
if [ "${EXTS}" = "${SERVEREXTS}" ]; then
	read -p "Subject Alternative Name: (Format example: IP:1.1.1.1,DNS:aa.com,DNS:www.aa.com): " X509V3SAN

	if [ "x${X509V3SAN}" = "x" ]; then
 		EXTS="$SERVEREXTS_NOSAN"
	else
		export X509V3SAN
	fi
fi

if [ $SELFSIGN -eq 0 ]; then
	# Some extensions can't be add to CSR
	EXTS="${EXTS}_req"
	openssl req -new -key $KEYFILE -out $OUTPUTFILE -reqexts $EXTS || exit 1
	VIEWOPT="req"
else
	if [ "x${DAYSOPT}" = "x" ]; then
		echo ""
		echo "How many days to to certify the certificate for?"
		read -p "Days [30]:" DAYSOPT
		# check if it is an INTEGER
		if [ "$DAYSOPT" -eq "$DAYSOPT" ] 2> /dev/null; then
			DAYSOPT="-days $DAYSOPT"
		fi
	fi
	eval openssl req -x509 -new -key $KEYFILE -out $OUTPUTFILE -extensions $EXTS $DAYSOPT || exit 1
	VIEWOPT="x509"
fi

echo ""
echo "Success! You can use \"openssl $VIEWOPT -in $OUTPUTFILE -text\" to view the information."

exit 0

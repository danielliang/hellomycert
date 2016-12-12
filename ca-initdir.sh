#!/bin/sh

usage() {
 echo "usage: $0 CADIR" >&2
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

CADIR="$1"
PRIVATEDIR=$CADIR/private
NEWCERTSDIR=$CADIR/newcerts
DBINDEX=$CADIR/index.txt
SERIAL=$CADIR/serial
CRLNUMBER=$CADIR/crlnumber
CACERT=$CADIR/ca.crt
CAKEY=$PRIVATEDIR/ca.key
CACONF=$CADIR/ca.cnf
CACONF_TEMPALTE=ca.cnf.template

if [ -s $DBINDEX ] || [ -s $SERIAL ] || [ -s $CRLNUMBER ] ; then
    echo "There are some old data in $CADIR,"  >&2
    echo "you should rename or delete old index.txt, serial, crlnumber, or ca.cnf in $CADIR manually"  >&2
    echo "or use another directory."  >&2
    echo "Stop!"  >&2
    exit 1
fi

mkdir -vp $CADIR $NEWCERTSDIR || exit 1
mkdir -vm 700 $PRIVATEDIR || exit 1

echo "Create ${DBINDEX}..."
touch $DBINDEX || exit 1

echo "Create ${SERIAL}..."
echo "01" > $SERIAL || exit 1

echo "Create ${CRLNUMBER}..."
echo "01" > $CRLNUMBER || exit 1

cp -v $CACONF_TEMPALTE $CACONF

echo "Initial OK!"
echo "You can put the key and certificate of CA as $CAKEY and $CACERT, "
echo "And customize $CACONF."

exit 0

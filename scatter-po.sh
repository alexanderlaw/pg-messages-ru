#!/bin/bash

set -e

SD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HM=`pwd`
TMP=$HM/.tmp

[ -d $TMP ] || mkdir $TMP

source config

TTPATH="$( cd "$TTPATH" && pwd )"
POLOGY_PATH="$( cd "$POLOGY_PATH" && pwd )"
export PYTHONPATH=$POLOGY_PATH:$PYTHONPATH

prepare_src_messages() {
    local version=$1
    local msgbranch=$2
    [ -d $TMP/messages-$version.git ] || git clone --branch $msgbranch --depth 1 $PGSQL_MESSAGES_GIT_URL $TMP/messages-$version.git
    (
    cd $TMP/messages-$version.git
    git checkout $msgbranch
    git pull
    )
}

finalize_po() {
    local version=$1
    (
    cd $TMP/messages-$version.git/ru
    for po in *.po; do
        echo $po
        msgcat $po --width=79 -o t.po && mv t.po $po;
        msgfmt -v -o /dev/null $po
        $TTPATH/chkpos.py --whitelist=$SD/whitelist.xml $po
    done
    )
}

export MSG_SRCS="$( cd "$TMP" && pwd )"

prepare_src_messages 17 REL_17_STABLE
prepare_src_messages 16 REL_16_STABLE
prepare_src_messages 15 REL_15_STABLE
prepare_src_messages 14 REL_14_STABLE
prepare_src_messages 13 REL_13_STABLE
(
cd $CUR_MESSAGES_PATH
$POLOGY_PATH/bin/posummit -v scatter
)
finalize_po 17
finalize_po 16
finalize_po 15
finalize_po 14
finalize_po 13


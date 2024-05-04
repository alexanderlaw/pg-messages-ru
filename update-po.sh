#!/bin/bash

set -e


####
# On error:
# Merging xxxx.po...
# posummit: [error] [Errno 2] No such file or directory: '/tmp/summit-templates-28577/xxxx.pot'
# remove postgresql/xxxx.po
####

HM=`pwd`
SD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $SD/config

TMP=$HM/.tmp
PGD=$TMP/postgresql.git
POTD=$TMP/pot

POLOGY_PATH="$( cd "$POLOGY_PATH" && pwd )"
export PYTHONPATH=$POLOGY_PATH:$PYTHONPATH

[ -d $TMP ] || mkdir $TMP

if [ -d $POTD ]; then rm -rf $POTD; fi
mkdir $POTD
POTD="$( cd $POTD && pwd )"

[ -d $PGD ] || git clone https://github.com/postgres/postgres.git $PGD


(cd $PGD; git fetch)

extract_pot() {
    local version=$1
    local gitdir=$2
    local branch=$3
    mkdir $POTD/$version
    (
    cd $gitdir
    git clean -dfx
    git reset --hard HEAD
    git checkout $branch
    git rebase
    ./configure --enable-nls --with-perl --with-python --with-tcl >/dev/null
    make init-po
    for pot in `find . -name '*.pot'`; do
        cp $pot $POTD/$version/
        echo $pot
    done
    )
}

merge_pot() {
    local version=$1
    local gitdir=$2
    local srcbranch=$3
    local msgbranch=$4
    extract_pot $version $gitdir $srcbranch
    [ -d $TMP/messages-$version.git ] || git clone --branch $msgbranch --depth 1 $PGSQL_MESSAGES_GIT_URL $TMP/messages-$version.git
    (
    cd $TMP/messages-$version.git
    git checkout $msgbranch
    git pull
    cd $MSG_LANG
    for po in *.po; do
        echo $po
        msgmerge -U --backup=none $po $POTD/$version/`basename $po .po`.pot
    done
    )
}

wrap_msgs() {
    for po in *.po; do
        msgcat $po --width=79 -o t.po && mv t.po $po
    done
}

export MSG_SRCS="$( cd "$TMP" && pwd )"
export MSG_POTS="$POTD"

merge_pot 16 $PGD REL_16_STABLE REL_16_STABLE

merge_pot 15 $PGD REL_15_STABLE REL_15_STABLE

merge_pot 14 $PGD REL_14_STABLE REL_14_STABLE

merge_pot 13 $PGD REL_13_STABLE REL_13_STABLE

merge_pot 12 $PGD REL_12_STABLE REL_12_STABLE

merge_pot 11 $PGD REL_11_STABLE REL_11_STABLE

(
cd $CUR_MESSAGES_PATH
$POLOGY_PATH/bin/posummit -v --create merge
# When adding a new branch:
#$POLOGY_PATH/bin/posummit gather --create --force
wrap_msgs
)

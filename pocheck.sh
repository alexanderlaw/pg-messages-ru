#!/bin/bash

set -e

SD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HM=`pwd`

if [ -z $1 ]; then
  TRANSD=postgresql
else
  TRANSD=$1
fi

source config

TMP=$HM/.tmp
TTPATH="$( cd "$TTPATH" && pwd )"
POLOGY_PATH="$( cd "$POLOGY_PATH" && pwd )"

pocheck() {
#    sed -i -z -e 's/"Last-Translator:[^"]*"\n//g' *.po
    sed -i -e "s/\(\"PO-Revision-Date: \)YEAR-MO-DA HO:MI+ZONE\(\\\\n\"\)/\1`date --rfc-3339=seconds`\2/" *.po
    for po in *.po; do
        msgfmt -c -v -o /dev/null $po
        $TTPATH/chkpos.py --whitelist=$SD/whitelist.xml $po
        $TTPATH/chkpos.py --test=SuffixWhitespacePedantic --whitelist=$SD/whitelist.xml $po
    done

    for po in *.po; do msgcat $po --width=79 -o t.po && mv t.po $po; done
    $POLOGY_PATH/bin/posieve check-rules --skip-obsolete -slang:ru -snorule:"mdash-required,double-quotes" --raw-colors --quiet *.po
    $POLOGY_PATH/bin/posieve check-spell-ec -slang:ru \
     -sskip:"[a-zA-Z]+" -sfilter:"remove_ru/remove_abbr" -sfilter:"remove_ru/remove_endings"  \
     -sfilter:"remove_ru/validwords" -sfilter:"remove_ru/remove_underscore"  \
     *.po
    [ -d "$TMP/po" ] && rm -rf "$TMP/po"
    mkdir "$TMP/po"
    [ -d "$TMP/poconflicts" ] && rm -rf "$TMP/poconflicts"
    mkdir "$TMP/poconflicts"
    cp *.po "$TMP/po/"
    poconflicts -i "$TMP/po" -o "$TMP/poconflicts"
}

(
cd $TRANSD
pocheck
)

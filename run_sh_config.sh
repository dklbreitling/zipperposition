#!/bin/bash

# based on the Sledgehammer config, but w/o calling E in the backend

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "% ZIP_TIMELIMIT is $ZIP_TIMELIMIT"
: ${ZIP_TMP_DIR:="/tmp/zip"}
: ${ZIP_TIMELIMIT:=30.000}
ZIP_ULIMIT=$(echo "$ZIP_TIMELIMIT + 5" | bc)
ZIP_ULIMIT=${ZIP_ULIMIT%.*}
echo "% ZIP_TIMELIMIT is $ZIP_TIMELIMIT, ZIP_ULIMIT is $ZIP_ULIMIT, ZIP_TMP_DIR is $ZIP_TMP_DIR."
ulimit -t $ZIP_ULIMIT

$DIR/zipperposition.exe ${1:+"$1"} \
  --input tptp\
  --output tptp\
  --timeout $ZIP_TIMELIMIT\
  --mode=ho-pragmatic\
  --tptp-def-as-rewrite\
  --rewrite-before-cnf=true\
  --max-inferences=1\
  --ho-unif-max-depth=1\
  --ho-max-elims=0\
  --ho-max-app-projections=0\
  --ho-max-rigid-imitations=1\
  --ho-max-identifications=0\
  --boolean-reasoning=bool-hoist\
  --bool-hoist-simpl=true\
  --bool-select=LI\
  --recognize-injectivity=true\
  --ext-rules=ext-family\
  --ext-rules-max-depth=1\
  --ho-choice-inst=true\
  --ho-prim-enum=none\
  --ho-elim-leibniz=0\
  --interpret-bool-funs=true\
  --tmp-dir="$ZIP_TMP_DIR"\
  --ho-unif-level=pragmatic-framework\
  --select=bb+e-selection2\
  --post-cnf-lambda-lifting=true\
  -q "4|prefer-sos|pnrefined(2,1,1,1,2,2,2)"\
  -q "6|prefer-processed|conjecture-relative-struct(1.5,3.5,2,3)"\
  -q "1|const|fifo"\
  -q "4|prefer-ground|orient-lmax(2,1,2,1,1)"\
  -q "4|defer-sos|conjecture-relative-struct(1,5,2,3)"\
  --avatar=off\
  --recognize-injectivity=true\
  --ho-neg-ext=true\
  --ho-pattern-decider=true\
  --ho-fixpoint-decider=true\
  --ignore-orphans=true\
  --presaturate=true\
  --disable-e\
  "${@:2}"

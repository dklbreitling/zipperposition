#!/bin/bash

# based mostly on 40_c.s.sh, but w/o calling E in the backend

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "% ZIP_TIMELIMIT is $ZIP_TIMELIMIT"
: ${ZIP_TIMELIMIT:=30.000}
ZIP_ULIMIT_IF=$(echo "$ZIP_TIMELIMIT + 5" | bc)
ZIP_ULIMIT_IF=${ZIP_ULIMIT%.*}
: ${ZIP_ULIMIT:=ZIP_ULIMIT_IF}
echo "% ZIP_TIMELIMIT is $ZIP_TIMELIMIT, ZIP_ULIMIT is $ZIP_ULIMIT, ZIP_TMP_DIR is $ZIP_TMP_DIR."
ulimit -t $ZIP_ULIMIT

$DIR/zipperposition.exe ${1:+"$1"} \
  --input tptp\
  --output tptp\
  --timeout $ZIP_TIMELIMIT\
  --mode=ho-pragmatic\
  -nc\
  --tptp-def-as-rewrite\
  --rewrite-before-cnf=true \
  --mode=ho-competitive\
  --boolean-reasoning=bool-hoist\
  --bool-hoist-simpl=true\
  --ext-rules=ext-family\
  --ext-rules-max-depth=2\
  --ho-prim-enum=full\
  --ho-prim-max=2\
  --bool-select=LI\
  --ho-max-elims=1\
  --avatar=off \
  --recognize-injectivity=true\
  --ho-elim-leibniz=1 \
  --ho-unif-level=full-framework\
  --no-max-vars\
  -q "6|prefer-sos|pnrefined(1,1,1,2,2,2,0.5)" \
  -q "6|const|conjecture-relative-var(1.02,l,f)" \
  -q "1|prefer-processed|fifo" \
  -q "1|prefer-non-goals|conjecture-relative-var(1,l,f)" \
  -q "4|prefer-easy-ho|conjecture-relative-var(1.01,s,f)" \
  --select=e-selection7\
  --ho-choice-inst=true\
  --sine=-1\
  --e-max-derived=48\
  --e-encode-lambdas=lift\
  --scan-clause-ac=true\
  --lambdasup=0\
  --kbo-weight-fun=invfreqrank\
  --disable-e\
  "${@:2}"

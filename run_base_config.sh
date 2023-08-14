#!/bin/bash

# based on the base config of Vukmirovic et al.'s Making HOS work,
# calling E backend disabled explicitly

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
  -nc --tptp-def-as-rewrite --rewrite-before-cnf=true \
  --mode=ho-competitive --boolean-reasoning=simpl-only \
  --ext-rules=off \
  --ho-prim-enum=pragmatic --ho-prim-max=1 \
  --avatar=off \
  --recognize-injectivity=true  --ho-elim-leibniz=1 \
  --ho-unif-level=full-framework --no-max-vars  \
  -q "2|prefer-goals|conjecture-relative-e(0.5,1,100,100,100,100,1.5,1.5,1)" \
  -q "4|const|conjecture-relative-e(0.1,1,100,100,100,100,1.5,1.5,1.5)" \
  -q "1|prefer-processed|fifo" \
  -q "1|prefer-non-goals|conjecture-relative-e(0.5,1,100,100,100,100,1.5,1.5,1.5)" \
  -q "4|prefer-sos|pnrefined(1,1,1,1,2,1.5,2)" \
  --select=ho-selection5 --ho-choice-inst=true \
  --sine=50 --sine-tolerance=2 --sine-depth-max=4 --sine-depth-min=1 \
  --scan-clause-ac=false --kbo-weight-fun=arity0 --prec-gen-fun=invfreq_conj \
  --disable-e\
  "${@:2}"

#!/bin/bash

# based on the fluid_off config of Bentkamp et al.'s Superposition for full HOL,
# but w/o calling E in the backend

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
  --mode=ho-competitive\
  --tptp-def-as-rewrite\
  --rewrite-before-cnf=true\
  --kbo-weight-fun=invfreqrank \
  -q "2|prefer-sos|conjecture-relative-var(1.02,l,f)" \
  -q "3|prefer-non-goals|pnrefined(1,1,1,2,2,2,0.5)" \
  -q "1|const|fifo" \
  -q "3|prefer-goals|conjecture-relative-var(1,l,f)" \
  -q "2|prefer-easy-ho|conjecture-relative-var(1.03,s,f)" \
  --select=bb+e-selection8\
  --fluid-hoist=false\
  --fluid-log-hoist=false\
  --fluidsup=false\
  --boolean-reasoning=bool-hoist\
  --bool-select=LI\
  --disable-e\
  "${@:2}"

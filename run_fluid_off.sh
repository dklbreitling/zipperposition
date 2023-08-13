#!/bin/bash



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ulimit -t $2

$DIR/zipperposition ${1:+"$1"} \
  -i tptp \
  -o tptp \
  --mode=ho-competitive --tptp-def-as-rewrite --rewrite-before-cnf=true \
  --timeout "$2" \
  --kbo-weight-fun=invfreqrank \
  -q "2|prefer-sos|conjecture-relative-var(1.02,l,f)" \
  -q "3|prefer-non-goals|pnrefined(1,1,1,2,2,2,0.5)" \
  -q "1|const|fifo" \
  -q "3|prefer-goals|conjecture-relative-var(1,l,f)" \
  -q "2|prefer-easy-ho|conjecture-relative-var(1.03,s,f)" \
  --select=bb+e-selection8 --fluid-hoist=false --fluid-log-hoist=false --fluidsup=false --boolean-reasoning=bool-hoist --bool-select=LI

#!/bin/bash
DATA_FILE="$1"            # e.g. solver_times_20250504_153012.dat
OUT_PNG="${DATA_FILE%.dat}.png"

gnuplot <<-EOF
  set terminal png size 800,600
  set output "${OUT_PNG}"
  set title "ESBMC Solver Compare"
  set style data histograms
  set style fill solid border -1
  set ylabel "Time (s)"
  set xlabel "Solver"
  set grid ytics
  # skip comment lines; use column 1 as labels, column 2 as values
  plot "${DATA_FILE}" using 2:xtic(1) title ""
EOF

echo "Wrote graph to ${OUT_PNG}"

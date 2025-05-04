#!/bin/bash

FILENAME=$1
shift
ESBMC_ARGS=$@

# Create temporary files to store outputs
Z3_OUTPUT=$(mktemp)
BOOLECTOR_OUTPUT=$(mktemp)
DATA_FILE="solver_times.dat"

# Create timestamp for unique filenames
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
GRAPH_FILE="solver_comparison_${TIMESTAMP}.png"

echo "===================================================="
echo "PORTFOLIO VERIFICATION FOR: $FILENAME"
echo "ARGUMENTS: $ESBMC_ARGS"
echo "===================================================="

# Launch ESBMC with Z3 in parallel
echo "Starting Z3 solver..."
START_TIME_Z3=$(date +%s.%N)
esbmc $FILENAME --z3 $ESBMC_ARGS > $Z3_OUTPUT 2>&1 &
PID_Z3=$!

# Launch ESBMC with Boolector in parallel
echo "Starting Boolector solver..."
START_TIME_BOOLECTOR=$(date +%s.%N)
esbmc $FILENAME --boolector $ESBMC_ARGS > $BOOLECTOR_OUTPUT 2>&1 &
PID_BOOLECTOR=$!

echo "Waiting for solvers to finish..."

# Variable to track which solver finished first
WINNER=""
WINNER_TIME=""

# Function to check if a solver has finished
check_solver_finished() {
  local PID=$1
  local NAME=$2
  local START_TIME=$3
  
  if ! kill -0 $PID 2>/dev/null; then
    if [ -z "$WINNER" ]; then
      WINNER=$NAME
      END_TIME=$(date +%s.%N)
      WINNER_TIME=$(echo "$END_TIME - $START_TIME" | bc)
      echo "$NAME solver finished first in $(printf "%.3f" $WINNER_TIME) seconds"
    else
      END_TIME=$(date +%s.%N)
      ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
      echo "$NAME solver finished in $(printf "%.3f" $ELAPSED) seconds"
    fi
    return 0
  fi
  return 1
}

# Wait for both solvers to finish
while true; do
  Z3_DONE=false
  BOOLECTOR_DONE=false
  
  check_solver_finished $PID_Z3 "Z3" $START_TIME_Z3 && Z3_DONE=true
  check_solver_finished $PID_BOOLECTOR "Boolector" $START_TIME_BOOLECTOR && BOOLECTOR_DONE=true
  
  if $Z3_DONE && $BOOLECTOR_DONE; then
    break
  fi
  
  sleep 0.1
done

# Calculate final times
END_TIME_Z3=$(date +%s.%N)
ELAPSED_Z3=$(echo "$END_TIME_Z3 - $START_TIME_Z3" | bc)

END_TIME_BOOLECTOR=$(date +%s.%N)
ELAPSED_BOOLECTOR=$(echo "$END_TIME_BOOLECTOR - $START_TIME_BOOLECTOR" | bc)

# Display a summary of results
echo ""
echo "===================================================="
echo "VERIFICATION RESULTS SUMMARY"
echo "===================================================="
echo "Z3 solver time: $(printf "%.3f seconds" $ELAPSED_Z3)"
echo "Boolector solver time: $(printf "%.3f seconds" $ELAPSED_BOOLECTOR)"
echo ""
echo "WINNER: $WINNER ($(printf "%.3f" $WINNER_TIME) seconds)"
echo "===================================================="

# Write data for plotting
echo "Solver Time" > $DATA_FILE
echo "Z3 $ELAPSED_Z3" >> $DATA_FILE
echo "Boolector $ELAPSED_BOOLECTOR" >> $DATA_FILE

# Create gnuplot script
GNUPLOT_SCRIPT=$(mktemp)
cat > $GNUPLOT_SCRIPT << GNUPLOT
set terminal png size 800,600
set output '$GRAPH_FILE'
set title 'SMT Solver Performance Comparison for $FILENAME'
set style data histogram
set style histogram cluster gap 1
set style fill solid
set boxwidth 0.9
set xtics rotate by -45
set grid ytics
set ylabel 'Time (seconds)'
set yrange [0:*]
plot '$DATA_FILE' using 2:xtic(1) title 'Execution Time'
GNUPLOT

# Generate the graph
if command -v gnuplot >/dev/null 2>&1; then
  gnuplot $GNUPLOT_SCRIPT
  echo "Performance comparison graph saved as $GRAPH_FILE"
else
  echo "gnuplot not found. Please install it to generate visual comparisons."
  echo "On Ubuntu: sudo apt-get install gnuplot"
  echo "On macOS: brew install gnuplot"
fi

# Display detailed results
echo ""
echo "===================================================="
echo "Z3 DETAILED RESULTS"
echo "===================================================="
cat $Z3_OUTPUT

echo ""
echo "===================================================="
echo "BOOLECTOR DETAILED RESULTS"
echo "===================================================="
cat $BOOLECTOR_OUTPUT

# Clean up temp files
rm -f $Z3_OUTPUT $BOOLECTOR_OUTPUT $GNUPLOT_SCRIPT $DATA_FILE

echo ""
echo "Portfolio verification completed."

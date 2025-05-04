#!/bin/bash

FILENAME=$1
shift
ESBMC_ARGS=$@

# Define available solvers
SOLVERS=(
  "z3"
  "boolector"
  "yices"
  "cvc5"  # Add CVC5 as a direct solver option
)

# Create timestamp for unique filenames
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATA_FILE="solver_times_${TIMESTAMP}.dat"

echo "===================================================="
echo "PORTFOLIO VERIFICATION FOR: $FILENAME"
echo "ARGUMENTS: $ESBMC_ARGS"
echo "===================================================="

# Create temporary files to store outputs and track PIDs
declare -A SOLVER_OUTPUT
declare -A SOLVER_PID
declare -A SOLVER_START_TIME
declare -A SOLVER_END_TIME
declare -A SOLVER_ELAPSED

# Launch all solvers in parallel
for SOLVER in "${SOLVERS[@]}"; do
  echo "Starting $SOLVER solver..."
  SOLVER_OUTPUT[$SOLVER]=$(mktemp)
  SOLVER_START_TIME[$SOLVER]=$(date +%s.%N)
  
  if [ "$SOLVER" = "cvc5" ]; then
    # For CVC5, use the SMTLIB interface
    esbmc $FILENAME --smtlib --smtlib-solver-prog "cvc5 -L smt2 -m" $ESBMC_ARGS > ${SOLVER_OUTPUT[$SOLVER]} 2>&1 &
  else
    # For other solvers, use the built-in support
    esbmc $FILENAME --$SOLVER $ESBMC_ARGS > ${SOLVER_OUTPUT[$SOLVER]} 2>&1 &
  fi
  
  SOLVER_PID[$SOLVER]=$!
  echo "$SOLVER solver PID: ${SOLVER_PID[$SOLVER]}"
done

echo "Waiting for solvers to finish..."

# Variable to track which solver finished first
WINNER=""
WINNER_TIME=""

# Function to check if a solver has finished
check_solver_finished() {
  local SOLVER=$1
  local PID=${SOLVER_PID[$SOLVER]}
  
  if ! kill -0 $PID 2>/dev/null; then
    if [ -z "$WINNER" ]; then
      WINNER=$SOLVER
      SOLVER_END_TIME[$SOLVER]=$(date +%s.%N)
      SOLVER_ELAPSED[$SOLVER]=$(echo "${SOLVER_END_TIME[$SOLVER]} - ${SOLVER_START_TIME[$SOLVER]}" | bc)
      WINNER_TIME=${SOLVER_ELAPSED[$SOLVER]}
      echo "$SOLVER solver finished first in $(printf "%.3f" ${SOLVER_ELAPSED[$SOLVER]}) seconds"
    else
      SOLVER_END_TIME[$SOLVER]=$(date +%s.%N)
      SOLVER_ELAPSED[$SOLVER]=$(echo "${SOLVER_END_TIME[$SOLVER]} - ${SOLVER_START_TIME[$SOLVER]}" | bc)
      echo "$SOLVER solver finished in $(printf "%.3f" ${SOLVER_ELAPSED[$SOLVER]}) seconds"
    fi
    return 0
  fi
  return 1
}

# Wait for all solvers to finish
while true; do
  ALL_DONE=true
  
  for SOLVER in "${SOLVERS[@]}"; do
    # If we already know this solver is done, skip checking
    if [[ -z "${SOLVER_END_TIME[$SOLVER]}" ]]; then
      if check_solver_finished $SOLVER; then
        # Solver just finished
        true
      else
        # Solver still running
        ALL_DONE=false
      fi
    fi
  done
  
  if $ALL_DONE; then
    break
  fi
  
  sleep 0.1
done

# Display a summary of results
echo ""
echo "===================================================="
echo "VERIFICATION RESULTS SUMMARY"
echo "===================================================="

for SOLVER in "${SOLVERS[@]}"; do
  echo "$SOLVER solver time: $(printf "%.3f seconds" ${SOLVER_ELAPSED[$SOLVER]})"
done

echo ""
echo "WINNER: $WINNER ($(printf "%.3f" $WINNER_TIME) seconds)"
echo "===================================================="

# Write data for plotting with external visualization tool
echo "Solver Time" > $DATA_FILE
for SOLVER in "${SOLVERS[@]}"; do
  echo "$SOLVER ${SOLVER_ELAPSED[$SOLVER]}" >> $DATA_FILE
done

echo "Performance data saved to $DATA_FILE"
echo "You can visualize it with: ./enhanced_visualization.sh $DATA_FILE"

# Display detailed results
for SOLVER in "${SOLVERS[@]}"; do
  echo ""
  echo "===================================================="
  echo "${SOLVER^^} DETAILED RESULTS"
  echo "===================================================="
  cat ${SOLVER_OUTPUT[$SOLVER]}
done

# Clean up temp files
for SOLVER in "${SOLVERS[@]}"; do
  rm -f ${SOLVER_OUTPUT[$SOLVER]}
done

echo ""
echo "Portfolio verification completed."


#!/bin/bash

# The tests to run
TESTS=("test_free_list.c" "test_memory_leak.c" "test_free_literal.c")

# Common arguments
ARGS="--memory-leak-check --unwind 5"

# Create timestamp for unique filenames
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="benchmark_results_${TIMESTAMP}.dat"
GRAPH_FILE="benchmark_comparison_${TIMESTAMP}.png"

# Create results header
echo "TestCase Z3 Boolector" > $RESULTS_FILE

# Run each test
for TEST in "${TESTS[@]}"; do
  echo "Running $TEST..."
  
  # Create temporary file for results
  TEMP_RESULTS=$(mktemp)
  
  # Run the portfolio
  ./portfolio_esbmc.sh "$TEST" $ARGS > $TEMP_RESULTS
  
  # Extract times
  Z3_TIME=$(grep "Z3 solver time:" $TEMP_RESULTS | awk '{print $4}')
  BOOLECTOR_TIME=$(grep "Boolector solver time:" $TEMP_RESULTS | awk '{print $4}')
  
  # Add to results
  echo "$TEST $Z3_TIME $BOOLECTOR_TIME" >> $RESULTS_FILE
  
  echo "Completed $TEST"
  echo "----------------------------------------"
done

# Create gnuplot script for comparison graph
GNUPLOT_SCRIPT=$(mktemp)
cat > $GNUPLOT_SCRIPT << GNUPLOT
set terminal png size 1200,800
set output '$GRAPH_FILE'
set title 'SMT Solver Performance Across Test Cases at $TIMESTAMP'
set style data histogram
set style histogram cluster gap 1
set style fill solid
set boxwidth 0.9
set xtics rotate by -45
set grid ytics
set key top left
set ylabel 'Time (seconds)'
set yrange [0:*]

plot '$RESULTS_FILE' using 2:xtic(1) title 'Z3', \
     '' using 3 title 'Boolector'
GNUPLOT

# Generate the graph
gnuplot $GNUPLOT_SCRIPT
echo "Benchmark comparison graph saved as $GRAPH_FILE"

# Clean up
rm -f $GNUPLOT_SCRIPT

echo "Benchmarking completed."

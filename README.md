# ESBMC Portfolio SMT Solver

This repository contains a portfolio approach for running ESBMC with multiple SMT solvers in parallel.

## Contents

- `portfolio_esbmc.sh`: Main script that runs verification with Z3 and Boolector in parallel
- `run_portfolio_benchmark.sh`: Script to benchmark multiple test cases
- Test cases demonstrating various memory safety issues

## Requirements

- ESBMC 
- Z3 solver
- Boolector solver
- gnuplot (for visualization)

## Usage

```bash
./portfolio_esbmc.sh <filename> [esbmc_options]
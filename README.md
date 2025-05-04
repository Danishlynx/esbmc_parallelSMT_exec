![Mix Test](https://github.com/user-attachments/assets/8b6d5ef2-e309-474a-af52-bd909e41f435)

# ESBMC Portfolio: Multi-Solver Performance Comparison

This project implements a portfolio approach for running ESBMC (Efficient SMT-based Context-Bounded Model Checker) with multiple SMT solvers in parallel. The approach allows for comparing the performance of different solvers on the same verification task and leveraging the fastest solver to get results more quickly.

## Overview

The ESBMC Portfolio uses a parallel execution strategy to:

1. Run verification tasks simultaneously with multiple SMT solvers
2. Identify which solver finishes first
3. Compare performance metrics across solvers
4. Generate visualizations of solver performance

This approach is particularly valuable for complex verification tasks where solver performance can vary significantly depending on the problem domain.

## Included Solvers

The portfolio currently supports the following SMT solvers:

- Z3
- Boolector
- Yices
- CVC5 (via SMTLIB interface)

## Prerequisites

To use this portfolio approach, you need:

1. All SMT solvers installed
2. ESBMC built with solver support
3. Supporting tools:
   - bc (for floating-point arithmetic)
   - gnuplot (for visualization)

## Installation

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install build-essential git cmake python3 libboost-all-dev libgmp-dev curl unzip wget
sudo apt-get install bc gnuplot gperf flex bison
```

### 2. Create a Working Directory

```bash
mkdir -p ~/esbmc-setup
cd ~/esbmc-setup
```

### 3. Install SMT Solvers

#### Z3
```bash
cd ~/esbmc-setup
git clone https://github.com/Z3Prover/z3.git
cd z3
git checkout z3-4.12.2
mkdir build && cd build
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo make install
```

#### Boolector
```bash
cd ~/esbmc-setup
git clone https://github.com/boolector/boolector.git
cd boolector
git checkout 3.2.2
./contrib/setup-lingeling.sh
./contrib/setup-btor2tools.sh
./configure.sh
cd build
make -j$(nproc)
sudo make install
```

#### Yices
```bash
cd ~/esbmc-setup
wget https://yices.csl.sri.com/releases/2.6.4/yices-2.6.4-x86_64-pc-linux-gnu.tar.gz
tar -xzf yices-2.6.4-x86_64-pc-linux-gnu.tar.gz
cd yices-2.6.4
sudo ./install-yices
```

#### CVC5
```bash
cd ~/esbmc-setup
wget https://github.com/cvc5/cvc5/releases/download/cvc5-1.0.5/cvc5-Linux
chmod +x cvc5-Linux
sudo mv cvc5-Linux /usr/local/bin/cvc5
```

### 4. Build ESBMC with SMT Solver Support

```bash
cd ~/esbmc-setup
git clone https://github.com/esbmc/esbmc.git
cd esbmc
mkdir build && cd build

# Configure ESBMC with multiple solver support
cmake .. -DBUILD_TESTING=ON -DENABLE_PYTHON=ON -DENABLE_Z3=ON -DENABLE_BOOLECTOR=ON -DENABLE_YICES=ON -DENABLE_CVC4=OFF -DBUILD_STATIC=OFF -DCMAKE_BUILD_TYPE=Release

# Build and install
make -j$(nproc)
sudo make install
```

### 5. Clone this Repository

```bash
git clone https://github.com/yourusername/esbmc-portfolio.git
cd esbmc-portfolio
chmod +x portfolio.sh plot_solver_times.sh
```

## Usage

### Basic Usage

##  Move inside Parallel_ESBMC_SMT Folder

```bash
./portfolio.sh <source_file> [esbmc_options]
```

Example:
```bash
./portfolio.sh test_memory_leak.c --memory-leak-check --unwind 5
```

### Visualizing Results

After running the portfolio, you can visualize the results using the provided plotting script:

```bash
./plot_solver_times.sh solver_times_*.dat
```

This will generate a PNG file with a bar chart comparing the performance of different solvers.

## Example Test Cases

The repository includes several test cases that demonstrate different verification challenges:

1. **heartbleed_test.c**: Simulates the famous Heartbleed vulnerability with a buffer overflow issue
2. **test_memory_leak.c**: Simple memory leak test
3. **mix_test.c**: Multiple tests targeting different solver strengths

## How It Works

The portfolio approach works as follows:

1. For each solver (Z3, Boolector, Yices, CVC5), the script launches ESBMC in parallel
2. It monitors each process and records when each solver finishes
3. The first solver to complete is identified as the "winner"
4. All solver outputs are saved and compared
5. Performance metrics (execution time) are recorded for analysis
6. Results are formatted for easy visualization


### Adding New Solvers

To add a new solver to the portfolio, modify the `SOLVERS` array in `portfolio.sh` and add appropriate handling code for the new solver.

### Creating Custom Test Cases

You can create your own test cases to evaluate solver performance on specific verification challenges:

1. Create a new C file with the verification task
2. Run the portfolio on your test case
3. Analyze the results to identify which solver performs best

## License

This project is released under the Apache License 2.0.

## Acknowledgments

- ESBMC development team for creating the underlying verification tool
- SMT solver developers (Z3, Boolector, Yices, CVC5)

# TinyML Neural Network Accelerator

A TinyML Neural Network Accelerator implemented in SystemVerilog, with a Python-based model and fixed-point parameter export for hardware verification.

## Project Overview

This project explores the hardware implementation of a small feedforward neural network using fixed-point arithmetic. The accelerator is designed to execute neural network computations in RTL and compare its results against a Python reference model.

## Architecture

- Neural network: 4-8-2 (4 input features, 8 hidden neurons, 2 output neurons)
- Numeric format: Signed Q4.4 fixed-point
- Hardware description language: SystemVerilog
- ML and parameter export: Python / Google Colab
- RTL simulation: EDA Playground with Cadence Xcelium

## Key Components

- Multiply-accumulate (MAC) unit
- Neuron processing unit with ReLU and linear activation options
- Neural network accelerator integration
- Python-to-RTL parameter export and verification
- Multi-vector self-checking testbench

## Verification

The following milestones have passed in simulation:

- MAC unit verification
- Neuron unit verification
- Accelerator integration verification
- Python-to-RTL verification using an exported test vector

Additional multi-vector verification results will be documented after the complete test suite passes.

## Repository Structure

- `rtl/` — SystemVerilog design modules
- `testbench/` — Unit and integration testbenches
- `python/` — Training and parameter-export notebook
- `results/` — Simulation logs and verification evidence

## Tools Used

- SystemVerilog
- EDA Playground
- Cadence Xcelium
- Python
- Google Colab

## Future Improvements

- Expanded multi-vector regression testing
- Hardware resource and timing analysis
- Power, performance, and area evaluation
- Optimization for low-power TinyML applications

## Author

Developed as a learning and hardware-design project exploring the integration of machine learning and digital VLSI design.

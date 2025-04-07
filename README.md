# Long Short Term Memory (LSTM)
## Overview
Long Short Term Memories are a style of Recurrent Neural Networks that separate out long and short term data paths. This makes them a powerful tool for processing time series data where short and long term dependencies may be weighted differently. [Further Reading](https://colah.github.io/posts/2015-08-Understanding-LSTMs/)

This repo contains a Python (`lstm.py`) model and SystemVerilog (`lstm.sv`) design of a Long Short Term Memory. The top level wrapper `axi4_lite_lstm_layers_wrapper.v` instantiates a layered LSTM and an axi4 lite slave interface. When instantiating the top level wrapper, the user may specify the number of layers to be cascaded in the design.

## Python
`lstm.py` contains the Python model of the lstm. The `lstm.py` class can be tested in `lstm_test.py`. The SystemVerilog lookup tables are generated with `create_lstm_luts.py`.
## SystemVerilog
`lstm.sv` implements a Long Short Term Memory using multiplies and lookup tables for tanh and sigmoid activation functions. The designed is parameterized for fixed point data of 16 bits with 8 decimal places (`Q8.8`). 
## CocoTB
Multiple CocoTB testbenches are included to validate subsystems and the entire design

`$ make` runs a top level simulation including axi4-lite configuration and data path input

`$ make -f Makefile_axi` simulates the axi4-lite slave module

`$make -f Makefile_lstm_layers` simulates cascated lstm layers against a python module.

For each simulation, the waveform can be viewed with:
`$ gtkwave -f dump.vcd`

## Hardware Test
`$ sudo python3 lstm_pcie.py` tests the implemented design on a [Litefury board.](https://github.com/RHSResearchLLC/NiteFury-and-LiteFury) The design is instantiated in the block design with an AXI to AXI4-Lite protocol converter and the user must parameterize the address offset. In my implementation, I offset the module at 0x6000.

Example Output:

```
~/Documents/lstm$ sudo python3 lstm_pcie.py
Version Register: ID.Major.Minor.Patch = 34.1.1.6
Batch Size 85
Fixed Point C out Model result 47, hardware: 46
Model result 0.10401, hardware:  0.10156
FIXED POINT: Model result 27, hardware: 26
```

Notice that converting the software model output 0.1041 to fixed point 27 is very close to the hardware output of 26. Some quantization noise is expected since the FPGA has lower resolution.

## Next Steps
### Training and Inference
Integrate an optimizer to run training on the hardware implemented multi layer LSTM.

### Implement other Neural Nets
Experiment with other low level Neural Net cells like Gated Recurrent Unit (GRU).

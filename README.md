# Long Short Term Memory (LSTM)
This repo contains a Python (`lstm.py`) model and SystemVerilog (`lstm.sv`) design of a Long Short Term Memory.

## Python
`lstm.py` contains the Python model of the lstm. The `lstm.py` class can be tested in `lstm_test.py`. The SystemVerilog lookup tables are generated with `create_lstm_luts.py`.
## SystemVerilog
`lstm.sv` implements a Long Short Term Memory using multiplies and lookup tables for tanh and sigmoid lookup tables. The designed is parameterized for fixed point data of 16 bits with 8 decimal places (`Q8.8`). 
## CocoTB
The CocoTB testbench `cocotb_lstm.py` simulates the SystemVerilog design against the Python module. An error of Epsilon is allowed to account for fixed point math and quantization. The test can be run using:

`$ make`

and the `dump.vcd` file can be viewed with 

`$ gtkwave -f dump.vcd`

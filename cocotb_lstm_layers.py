# cocotb_lstm_layers.py

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
import lstm
from lstm import LSTM
from lstm import LAYERED_LSTM
import random

weights = 4
Epsilon = 0.1
verbose = False


async def send_input(dut, x):
    for xi in x:
        dut.x_in.value = lstm.createFixedPoint(xi, lstm.precision)
        dut.x_in_valid.value = 1
        await cocotb.triggers.RisingEdge(dut.clk)
        if dut.ready.value:
            pass
        else:
            await cocotb.triggers.RisingEdge(dut.ready)
            await cocotb.triggers.RisingEdge(dut.clk)
        if verbose:
            print(f"sent {xi}")
        dut.x_in_valid.value = 0
        for lyr in range(dut.LAYERS.value):
            dut.C_in_valid[lyr].value = 0
            dut.h_in_valid[lyr].value = 0
            for i in range(weights):
                dut.weight_x_valid[weights * lyr + i].value = 0
                dut.weight_h_valid[weights * lyr + i].value = 0
                dut.bias_x_valid[weights * lyr + i].value = 0
                dut.bias_h_valid[weights * lyr + i].value = 0


async def wait_output(dut, x):
    i = 1
    for _ in x:
        await cocotb.triggers.RisingEdge(dut.valid)
        if verbose:
            print(f"receiving {dut.y_out.value}, {dut.C_out.value}, {i}/{len(x)}")
        i += 1


async def test_lstm(dut):
    """Pass in the device under test and the python model, randomize inputs and check outputs"""
    while dut.ready.value != 1:
        await cocotb.triggers.RisingEdge(dut.clk)

    pylstms = LAYERED_LSTM(dut.LAYERS.value)
    pylstms.rand()
    for lyr in range(dut.LAYERS.value):
        for i in range(weights):
            dut.weight_x[weights * lyr + i].value = pylstms.layer[lyr].fixed_Wx[i]
            dut.weight_x_valid[weights * lyr + i].value = 1
            dut.weight_h[weights * lyr + i].value = pylstms.layer[lyr].fixed_Wh[i]
            dut.weight_h_valid[weights * lyr + i].value = 1
            dut.bias_x[weights * lyr + i].value = pylstms.layer[lyr].fixed_bx[i]
            dut.bias_x_valid[weights * lyr + i].value = 1
            dut.bias_h[weights * lyr + i].value = pylstms.layer[lyr].fixed_bh[i]
            dut.bias_h_valid[weights * lyr + i].value = 1

    for lyr in range(dut.LAYERS.value):
        dut.C_in[lyr].value = pylstms.layer[lyr].fixed_C_prev
        dut.h_in[lyr].value = pylstms.layer[lyr].fixed_h_prev
        dut.C_in_valid[lyr].value = 1
        dut.h_in_valid[lyr].value = 1

    # create random x input
    x = [random.uniform(-5, 5) for i in range(int(random.uniform(1, 10)))]
    # run against python module
    pylstms.process(x)

    # fork sending and receiving coroutines
    cocotb.start_soon(send_input(dut, x))
    await cocotb.start_soon(
        wait_output(dut, x)
    )  # block on wait_output before advancing to error checking

    # error checking
    floating_point_error = abs(
        lstm.floatingPoint(dut.y_out.value, lstm.precision)
        - pylstms.layer[dut.LAYERS.value - 1].h_prev
    )
    floating_point_error_state = abs(
        lstm.floatingPoint(dut.C_out.value, lstm.precision)
        - pylstms.layer[dut.LAYERS.value - 1].C_prev
    )
    if verbose:
        print("--------------------")
        print(x)
        print(
            f"{floating_point_error:.5f} = |{lstm.floatingPoint(int(dut.y_out.value), lstm.precision):.5f} - {pylstms.layer[dut.LAYERS.value - 1].h_prev}|"
        )
        print(
            f"{floating_point_error_state:.5f} = |{lstm.floatingPoint(int(dut.C_out.value), lstm.precision):.5f} - {pylstms.layer[dut.LAYERS.value - 1].C_prev}|"
        )
    assert floating_point_error < Epsilon
    assert floating_point_error_state < Epsilon


@cocotb.test()
async def lstm_test_suite(dut):
    """Set up LSTM tests."""
    dut.rst.value = 1
    await cocotb.start(cocotb.clock.Clock(dut.clk, 4, "ns").start())
    await cocotb.triggers.Timer(15, units="ns")  # wait a bit
    dut.rst.value = 0
    for _ in range(10):
        await cocotb.triggers.RisingEdge(dut.clk)
        while dut.ready.value != 1:
            await cocotb.triggers.RisingEdge(dut.clk)
        await cocotb.start_soon(test_lstm(dut))
        await cocotb.triggers.RisingEdge(dut.clk)

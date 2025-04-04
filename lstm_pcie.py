#!/usr/bin/env python3
import os
import struct
import sys
import argparse
import random
from lstm import LAYERED_LSTM
import lstm

##############################################
layers = 2
read_write_size = 4
Epsilon = 5


def convert_signed(unsigned, bits):
    if unsigned < (2 ** (bits - 1)):
        return unsigned
    else:
        return unsigned - 2**bits


def write(fd, write_addr, write_data, signed=True):
    return os.pwrite(
        fd, write_data.to_bytes(read_write_size, "little", signed=signed), write_addr
    )


def read(fd, read_addr, signed=True):
    return int.from_bytes(
        os.pread(fd, read_write_size, read_addr),
        byteorder="little",
        signed=signed,
    )


class LAYERED_LSTM_HARDWARE(LAYERED_LSTM):
    def write_config(self, fd):
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                write(
                    fd, self.weight_x_address[lyr][gate], self.layer[lyr].fixed_Wx[gate]
                )
                write(
                    fd, self.weight_h_address[lyr][gate], self.layer[lyr].fixed_Wh[gate]
                )
                write(
                    fd, self.bias_x_address[lyr][gate], self.layer[lyr].fixed_bx[gate]
                )
                write(
                    fd, self.bias_h_address[lyr][gate], self.layer[lyr].fixed_bh[gate]
                )

            write(fd, self.C_prev_address[lyr], self.layer[lyr].fixed_C_prev)
            write(fd, self.h_prev_address[lyr], self.layer[lyr].fixed_h_prev)

    def read_config(self, fd):
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                read_data = read(fd, self.weight_x_address[lyr][gate])
                assert self.layer[lyr].fixed_Wx[gate] == read_data
                read_data = read(fd, self.weight_h_address[lyr][gate])
                assert self.layer[lyr].fixed_Wh[gate] == read_data
                read_data = read(fd, self.bias_x_address[lyr][gate])
                assert self.layer[lyr].fixed_bx[gate] == read_data
                read_data = read(fd, self.bias_h_address[lyr][gate])
                assert self.layer[lyr].fixed_bh[gate] == read_data
            read_data = read(fd, self.C_prev_address[lyr])
            assert self.layer[lyr].fixed_C_prev == read_data
            read_data = read(fd, self.h_prev_address[lyr])
            assert self.layer[lyr].fixed_h_prev == read_data

    def process_hw(self, fd, x):
        for xi in x:
            write_data = lstm.fixedPoint(xi, lstm.precision)
            write(fd, self.x_in_address, write_data)
            read_data = read(fd, self.x_in_address)
            assert write_data == read_data

        y_out_hw_fixed = read(fd, self.y_out_address)
        y_out_hw_fixed = convert_signed(y_out_hw_fixed, 16)
        C_out_hw_fixed = read(fd, self.C_out_address)
        C_out_hw_fixed = convert_signed(C_out_hw_fixed, 16)
        self.process(x)
        print(
            f"C out Model result {self.layer[-1].fixed_C_prev}, hardware: {C_out_hw_fixed}"
        )
        y_out_hw = lstm.floatingPoint(y_out_hw_fixed, lstm.precision)
        print(f"Model result {self.layer[-1].h_prev:.5}, hardware: {y_out_hw: .5}")
        print(
            f"FIXED POINT: Model result {self.layer[-1].fixed_h_prev}, hardware: {y_out_hw_fixed}"
        )
        assert abs(self.layer[-1].fixed_h_prev - y_out_hw_fixed) < Epsilon


def main():

    fd = os.open("/dev/xdma0_user", os.O_RDWR)

    # Product
    pid_string = os.pread(fd, read_write_size, 0x0)[::-1]
    pvrsn = read(fd, 0x8, signed=False)
    print("Found product ID %s version %d" % (pid_string, pvrsn))

    lstmHW = LAYERED_LSTM_HARDWARE(layers=layers, offset=0x6000)
    ver_dec = []
    version_register = read(fd, lstmHW.version_address)
    for i in range(4):
        ver_dec.append(version_register & 0xFF)
        version_register >>= 8
    print(f"ID.Major.Minor.Patch = {ver_dec[3]}.{ver_dec[2]}.{ver_dec[1]}.{ver_dec[0]}")
    lstmHW.rand()
    lstmHW.write_config(fd)
    lstmHW.read_config(fd)
    x = [random.uniform(-5, 5) for i in range(int(random.uniform(1, 100)))]
    print(lstm.createFixedPoint(x, lstm.precision))
    lstmHW.process_hw(fd, x)


if __name__ == "__main__":

    main()

#!/usr/bin/env python3
import os
import struct
import time
import sys
import argparse
import random
from lstm import LAYERED_LSTM
import lstm

##############################################

layers = 1
read_write_size = 4


class LAYERED_LSTM_HARDWARE(LAYERED_LSTM):
    def write_config(self, fd):
        print(f"fixed_h_prev: {self.layer[0].fixed_h_prev}")
        print(f"fixed_bx: {self.layer[0].fixed_bx}")
        print(f"fixed_bh: {self.layer[0].fixed_bh}")
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                write_addr, write_data = (
                    self.weight_x_address[lyr][gate],
                    self.layer[lyr].fixed_Wx[gate],
                )
                os.pwrite(
                    fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr
                )
                write_addr, write_data = (
                    self.weight_h_address[lyr][gate],
                    self.layer[lyr].fixed_Wh[gate],
                )
                os.pwrite(
                    fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr
                )
                write_addr, write_data = (
                    self.bias_x_address[lyr][gate],
                    self.layer[lyr].fixed_bx[gate],
                )
                os.pwrite(
                    fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr
                )
                write_addr, write_data = (
                    self.bias_h_address[lyr][gate],
                    self.layer[lyr].fixed_bh[gate],
                )
                os.pwrite(
                    fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr
                )

            write_addr, write_data = (
                self.C_prev_address[lyr],
                self.layer[lyr].fixed_C_prev,
            )
            os.pwrite(fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr)

            write_addr, write_data = (
                self.h_prev_address[lyr],
                self.layer[lyr].fixed_h_prev,
            )
            os.pwrite(fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr)

    def read_config(self, fd):
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                read_addr, expected_data = (
                    self.weight_x_address[lyr][gate],
                    self.layer[lyr].fixed_Wx[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.weight_h_address[lyr][gate],
                    self.layer[lyr].fixed_Wh[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.bias_x_address[lyr][gate],
                    self.layer[lyr].fixed_bx[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.bias_h_address[lyr][gate],
                    self.layer[lyr].fixed_bh[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
                )
                assert expected_data == read_data

            read_addr, expected_data = (
                self.C_prev_address[lyr],
                self.layer[lyr].fixed_C_prev,
            )
            read_data = int.from_bytes(
                os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
            )
            assert expected_data == read_data

            read_addr, expected_data = (
                self.h_prev_address[lyr],
                self.layer[lyr].fixed_h_prev,
            )
            read_data = int.from_bytes(
                os.pread(fd, read_write_size, read_addr), byteorder="little", signed=True
            )
            assert expected_data == read_data

    def process_hw(self, fd, x):
        for xi in x:
            # print(f"x_in: {lstm.fixedPoint(xi, lstm.precision)};  h_prev: {self.layer[0].fixed_h_prev}; bx[0]: {self.layer[0].fixed_bx[0]}; bh[0]: {self.layer[0].fixed_bh[0]}")
            write_addr, write_data = self.x_in_address, lstm.fixedPoint(
                xi, lstm.precision
            )
            print(f"write_addr: {write_addr:#x}, write_data: {write_data:#x}")
            os.pwrite(fd, write_data.to_bytes(read_write_size, "little", signed=True), write_addr)
            read_data = int.from_bytes(
                os.pread(fd, read_write_size, write_addr), byteorder="little", signed=True
            )
            assert write_data == read_data
            time.sleep(0.1)

        self.process(x)
        time.sleep(0.1)
        C_out_hw_fixed = int.from_bytes(
            os.pread(fd, read_write_size, self.C_out_address), byteorder="little", signed=True
        )
        print(
            f"C out Model result {self.layer[-1].fixed_C_prev:x}, hardware: {C_out_hw_fixed:x}"
        )
        y_out_hw_fixed = int.from_bytes(
            os.pread(fd, read_write_size, self.y_out_address), byteorder="little", signed=True
        )
        print(f"{y_out_hw_fixed:#x}")
        y_out_hw = lstm.floatingPoint(y_out_hw_fixed, lstm.precision)
        print(f"Model result {self.layer[-1].h_prev:.5}, hardware: {y_out_hw: .5}")
        print(
            f"FIXED POINT: Model result {self.layer[-1].fixed_h_prev}, hardware: {y_out_hw_fixed}"
        )


def main():

    fd = os.open("/dev/xdma0_user", os.O_RDWR)

    # Product
    pid_string = os.pread(fd, read_write_size, 0x0)[::-1]
    pvrsn = int.from_bytes(os.pread(fd, read_write_size, 0x8), byteorder="little")

    print("Found product ID %s version %d" % (pid_string, pvrsn))

    lstmHW = LAYERED_LSTM_HARDWARE(layers=layers, offset=0x6000)
    ver_dec = []
    version_register = int.from_bytes(
        os.pread(fd, read_write_size, lstmHW.version_address), byteorder="little"
    )
    print(f"version_register = {version_register:#x}")
    for i in range(4):
        ver_dec.append(version_register & 0xFF)
        version_register >>= 8
    print(f"ID.Major.Minor.Patch = {ver_dec[3]}.{ver_dec[2]}.{ver_dec[1]}.{ver_dec[0]}")
    lstmHW.rand()
    lstmHW.write_config(fd)
    lstmHW.read_config(fd)
    x = [random.uniform(-5, 5) for i in range(int(random.uniform(1, 1)))]
    print(lstm.createFixedPoint(x, lstm.precision))
    lstmHW.process_hw(fd, x)


if __name__ == "__main__":

    main()

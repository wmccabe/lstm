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


class LAYERED_LSTM_HARDWARE(LAYERED_LSTM):
    def write_config(self, fd):
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                write_addr, write_data = (
                    self.weight_x_address[lyr][gate],
                    self.layer[lyr].fixed_Wx[gate],
                )
                os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)
                write_addr, write_data = (
                    self.weight_h_address[lyr][gate],
                    self.layer[lyr].fixed_Wh[gate],
                )
                os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)
                write_addr, write_data = (
                    self.bias_x_address[lyr][gate],
                    self.layer[lyr].fixed_bx[gate],
                )
                os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)
                write_addr, write_data = (
                    self.bias_h_address[lyr][gate],
                    self.layer[lyr].fixed_bh[gate],
                )
                os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)

            write_addr, write_data = (
                self.C_prev_address[lyr],
                self.layer[lyr].fixed_C_prev,
            )
            os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)

            write_addr, write_data = (
                self.h_prev_address[lyr],
                self.layer[lyr].fixed_h_prev,
            )
            os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)

    def read_config(self, fd):
        for lyr in range(self.layers):
            for gate in range(lstm.gates):
                read_addr, expected_data = (
                    self.weight_x_address[lyr][gate],
                    self.layer[lyr].fixed_Wx[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, 8, read_addr), byteorder="little"
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.weight_h_address[lyr][gate],
                    self.layer[lyr].fixed_Wh[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, 8, read_addr), byteorder="little"
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.bias_x_address[lyr][gate],
                    self.layer[lyr].fixed_bx[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, 8, read_addr), byteorder="little"
                )
                assert expected_data == read_data

                read_addr, expected_data = (
                    self.bias_h_address[lyr][gate],
                    self.layer[lyr].fixed_bh[gate],
                )
                read_data = int.from_bytes(
                    os.pread(fd, 8, read_addr), byteorder="little"
                )
                assert expected_data == read_data

            read_addr, expected_data = (
                self.C_prev_address[lyr],
                self.layer[lyr].fixed_C_prev,
            )
            read_data = int.from_bytes(os.pread(fd, 8, read_addr), byteorder="little")
            assert expected_data == read_data

            read_addr, expected_data = (
                self.h_prev_address[lyr],
                self.layer[lyr].fixed_h_prev,
            )
            read_data = int.from_bytes(os.pread(fd, 8, read_addr), byteorder="little")
            assert expected_data == read_data

    def process_hw(self, fd, x):
        self.process(x)
        for xi in x:
            write_addr, write_data = self.x_in_address, lstm.fixedPoint(
                xi, lstm.precision
            )
            print(f"write_addr: {write_addr:#x}, write_data: {write_data:#x}")
            os.pwrite(fd, write_data.to_bytes(8, "little"), write_addr)
            read_data = int.from_bytes(os.pread(fd, 8, write_addr), byteorder="little")
            assert write_data == read_data
            time.sleep(0.1)

        time.sleep(0.1)
        C_out_hw_fixed = int.from_bytes(
            os.pread(fd, 8, self.C_out_address), byteorder="little"
        )
        print(
            f"C out Model result {self.layer[-1].fixed_C_prev:x}, hardware: {C_out_hw_fixed:x}"
        )
        y_out_hw_fixed = int.from_bytes(
            os.pread(fd, 8, self.y_out_address), byteorder="little"
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
    pid_string = os.pread(fd, 4, 0x0)[::-1]
    pvrsn = int.from_bytes(os.pread(fd, 4, 0x8), byteorder="little")

    print("Found product ID %s version %d" % (pid_string, pvrsn))

    # read / write to gpio bits
    gpio_led = 0x2008
    read_data = int.from_bytes(os.pread(fd, 4, gpio_led), byteorder="little")
    print("GPIO LED: %x" % read_data)
    write_data = 0xCAFEF00D
    write_bytes = write_data.to_bytes(8, "little")
    os.pwrite(fd, write_data.to_bytes(8, "little"), gpio_led)
    read_data = int.from_bytes(os.pread(fd, 4, gpio_led), byteorder="little")
    print("GPIO LED: %x" % read_data)

    axi_lstm_address = 0x0000_6020
    write_data = 0xCAFEBABE
    write_bytes = write_data.to_bytes(8, "little")
    os.pwrite(fd, write_data.to_bytes(8, "little"), axi_lstm_address)
    read_data = int.from_bytes(os.pread(fd, 4, axi_lstm_address), byteorder="little")
    print(f"written: {write_data: x}; read: {read_data: x}")

    lstmHW = LAYERED_LSTM_HARDWARE(layers=4, offset=0x6000)
    ver_dec = []
    version_register = int.from_bytes(os.pread(fd, 4, lstmHW.version_address))
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

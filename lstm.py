from enum import Enum
import math
import random

precision = 8
fullPrecision = 16
gates = 4
addressStep = 4


def sigmoid(x):
    if x > 100:
        return 1
    elif x < -100:
        return 0
    else:
        return 1 / (1 + math.exp(-x))


def asigmoid(y):
    return math.log(y / (1 - y))


class Index(Enum):
    i = 0
    f = 1
    g = 2
    o = 3


def round_precision(x, precision):
    return round(x * (2**precision)) / (2**precision)


def floatingPoint(fixed_x, precision):
    assert int(fixed_x) == fixed_x
    x = int(fixed_x)
    if x > 2 ** (fullPrecision - 1):
        return -1 * (2**fullPrecision - x) / (2**precision)
    else:
        return x / (2**precision)


def fixedPoint(floating_x, precision):
    x = round_precision(floating_x, precision)
    return round(x * 2**precision)


def createFixedPoint(x, precision):
    try:
        return [fixedPoint(i, precision) for i in x]
    except:
        return fixedPoint(x, precision)


class LSTM:
    def updateFixed(self):
        # create fixed point values for verilog
        self.fixed_Wh = createFixedPoint(self.Wh, precision)
        self.fixed_Wx = createFixedPoint(self.Wx, precision)
        self.fixed_bh = createFixedPoint(self.bh, precision)
        self.fixed_bx = createFixedPoint(self.bx, precision)
        self.fixed_C_prev = createFixedPoint(self.C_prev, precision)
        self.fixed_h_prev = createFixedPoint(self.h_prev, precision)

    def __init__(self, Wh=0, Wx=0, bh=0, bx=0, C_prev=0, h_prev=0):
        self.Wh = Wh  # weights
        self.Wx = Wx  # weights
        self.bh = bh  # bias
        self.bx = bx  # bias
        self.C_prev = C_prev
        self.h_prev = h_prev
        self.updateFixed()

    def rand(self):
        min = -5
        max = 5
        self.Wh = [random.uniform(min, max) for i in range(Index.o.value + 1)]
        self.Wx = [random.uniform(min, max) for i in range(Index.o.value + 1)]
        self.bh = [random.uniform(min, max) for i in range(Index.o.value + 1)]
        self.bx = [random.uniform(min, max) for i in range(Index.o.value + 1)]
        self.C_prev = random.uniform(min, max)
        self.h_prev = random.uniform(min, max)
        self.updateFixed()

    def process(self, X):
        useSigmoid = [True, True, False, True]
        for x in X:
            scaled = gates * [None]
            activated = gates * [None]
            for i in range(gates):
                scaled[i] = (
                    self.Wx[i] * x + self.Wh[i] * self.h_prev + self.bx[i] + self.bh[i]
                )
                # branch on activation functions
                if useSigmoid[i]:
                    activated[i] = sigmoid(scaled[i])
                else:
                    activated[i] = math.tanh(scaled[i])
            # long term
            C_t = (
                activated[Index.f.value] * self.C_prev
                + activated[Index.i.value] * activated[Index.g.value]
            )
            # short term
            h_t = activated[Index.o.value] * math.tanh(C_t)
            self.C_prev = C_t
            self.h_prev = (
                h_t  # h_prev is also the y value which is compared to expected
            )
            # update fixed point values
            self.updateFixed()


class LAYERED_LSTM:
    def __init__(self, layers=1, offset=0):
        self.layers = layers
        self.layer = [LSTM() for layer in range(layers)]
        self.offset = offset
        address = self.offset
        self.weight_x_address = [
            [(lyr * gates + i) * addressStep + address for i in range(gates)]
            for lyr in range(self.layers)
        ]
        address = self.weight_x_address[-1][-1] + addressStep
        self.weight_h_address = [
            [(lyr * gates + i) * addressStep + address for i in range(gates)]
            for lyr in range(self.layers)
        ]
        address = self.weight_h_address[-1][-1] + addressStep
        self.bias_x_address = [
            [(lyr * gates + i) * addressStep + address for i in range(gates)]
            for lyr in range(self.layers)
        ]
        address = self.bias_x_address[-1][-1] + addressStep
        self.bias_h_address = [
            [(lyr * gates + i) * addressStep + address for i in range(gates)]
            for lyr in range(self.layers)
        ]
        address = self.bias_h_address[-1][-1] + addressStep
        self.C_prev_address = [
            address + lyr * addressStep for lyr in range(self.layers)
        ]
        address = self.C_prev_address[-1] + addressStep
        self.h_prev_address = [
            address + lyr * addressStep for lyr in range(self.layers)
        ]
        address = self.h_prev_address[-1] + addressStep
        self.x_in_address = address
        address = self.x_in_address + addressStep
        self.y_out_address = address
        address = self.y_out_address + addressStep
        self.C_out_address = address
        address = self.C_out_address + addressStep
        self.version_address = address

    def rand(self):
        [layer.rand() for layer in self.layer]

    def process(self, X):
        """
        For each x in X representing an input at a timestep, send x through self.layers lstm where layers 1+
        take in y from the previous layer as x. After the first timestep, allow the updated states to recur in each layer.
        """
        for x in X:  # time steps
            for lyr in range(self.layers):  # layers
                if lyr == 0:
                    layer_input = x
                else:
                    layer_input = self.layer[lyr - 1].h_prev
                self.layer[lyr].process([layer_input])

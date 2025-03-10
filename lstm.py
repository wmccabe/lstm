from enum import Enum
import math
import random

precision = 8
fullPrecision = 16
gates = 4

def sigmoid(x):
    if x > 100:
        return 1
    elif x < -100:
        return 0
    else:
        return 1 / (1 + math.exp(-x))

def asigmoid(y):
    return math.log(y/(1-y))     

class Index(Enum):
    i = 0
    f = 1
    g = 2
    o = 3


def floatingPoint(fixed_x, precision):
    assert int(fixed_x) == fixed_x
    x = int(fixed_x)
    if (x > 2**(fullPrecision - 1)):
        return -1*(2**fullPrecision - x)/(2**precision)
    else:
        return x/(2**precision)
    
def fixedPoint(floating_x, precision):
    x = floating_x
    if (x < 0):
        # two's compliment
        magnitude = round(abs(x)*2**precision)
        return int(2**fullPrecision - magnitude)
    else:
        return round(x*2**precision)

def createFixedPoint(x, precision):
    try:
        return [fixedPoint(i, precision) for i in x]
    except:
        return fixedPoint(x, precision)
 

class LSTM:
    def updateFixed(self):
        # create fixed point values for verilog
        self.fixed_Wh     = createFixedPoint(self.Wh, precision)
        self.fixed_Wx     = createFixedPoint(self.Wx, precision)
        self.fixed_bh     = createFixedPoint(self.bh, precision)
        self.fixed_bx     = createFixedPoint(self.bx, precision)
        self.fixed_C_prev = createFixedPoint(self.C_prev, precision)
        self.fixed_h_prev = createFixedPoint(self.h_prev, precision)
        
    def __init__(self, Wh=0, Wx=0, bh=0, bx=0, C_prev=0, h_prev=0):
        self.Wh = Wh # weights
        self.Wx = Wx # weights
        self.bh = bh # bias
        self.bx = bx # bias
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
            scaled = gates*[None]
            activated = gates*[None]
            for i in range(gates):
                scaled[i] = self.Wx[i]*x + self.Wh[i]*self.h_prev + self.bx[i] + self.bh[i]
                # branch on activation functions
                if useSigmoid[i]:
                    activated[i] = sigmoid(scaled[i])
                else:
                    activated[i] = math.tanh(scaled[i])
            # long term
            C_t = activated[Index.f.value]*self.C_prev + activated[Index.i.value]*activated[Index.g.value]
            # short term
            h_t = activated[Index.o.value]*math.tanh(C_t)
            self.C_prev = C_t
            self.h_prev = h_t # h_prev is also the y value which is compared to expected
            # update fixed point values
            self.updateFixed()


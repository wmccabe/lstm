from enum import Enum
import math
import random

precision = 8
fullPrecision = 8

def sigmoid(x):
    if x > 100:
        return 1
    elif x < 100:
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

def fixedPoint(x, precision):
    if x >= 0:
        return round(x*2**precision)
    else:
        # two's compliment
        return round(2**fullPrecision - round(x*2**precision) + 1)

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
        self.Wh = [random.uniform(-256, 255) for i in range(Index.o.value + 1)] 
        self.Wx = [random.uniform(-256, 255) for i in range(Index.o.value + 1)] 
        self.bh = [random.uniform(-256, 255) for i in range(Index.o.value + 1)] 
        self.bx = [random.uniform(-256, 255) for i in range(Index.o.value + 1)] 
        self.C_prev = random.uniform(-256, 255)
        self.h_prev = random.uniform(-256, 255)
        self.updateFixed()
        
         
    def process(self, X):
        for x in X:
            # forget
            f_t       =   sigmoid(self.Wx[Index.f.value]*x + self.Wh[Index.f.value]*self.h_prev + self.bx[Index.f.value] + self.bh[Index.f.value])
            # input 
            i_t       =   sigmoid(self.Wx[Index.i.value]*x + self.Wh[Index.i.value]*self.h_prev + self.bx[Index.i.value] + self.bh[Index.i.value])
            tilde_C_t = math.tanh(self.Wx[Index.g.value]*x + self.Wh[Index.g.value]*self.h_prev + self.bx[Index.g.value] + self.bh[Index.g.value])
            # output 
            o_t       =   sigmoid(self.Wx[Index.o.value]*x + self.Wh[Index.o.value]*self.h_prev + self.bx[Index.o.value] + self.bh[Index.o.value])
            # long term
            C_t = f_t*self.C_prev + i_t*tilde_C_t
            # short term
            h_t = o_t*math.tanh(C_t)
            self.C_prev = C_t
            self.h_prev = h_t # h_prev is also the y value which is compared to expected
            # update fixed point values
            self.updateFixed()
            # print(self.h_prev, self.fixed_h_prev)


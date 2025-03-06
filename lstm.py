from enum import Enum
import math

def sigmoid(x):
  return 1 / (1 + math.exp(-x))

def asigmoid(y):
  return math.log(y/(1-y))     

class Index(Enum):
    i = 0
    f = 1
    g = 2
    o = 3

def createFixedPoint(x, precision):
    return [round(i*2**precision) for i in x]

class LSTM:
    # def __new__(cls, parameters):
    #     instance = super(ClassName, cls).__new__(cls)
    #     return instance
    precision = 8
    def __init__(self, Wh, Wx, bh, bx, C_prev=0, h_prev=0):
        self.Wh = Wh # weights
        self.Wx = Wx # weights
        self.bh = bh # bias
        self.bx = bx # bias
        self.C_prev = C_prev
        self.h_prev = h_prev
        # create fixed point values for verilog
        self.fixed.Wh     = createFixedPoint(self.Wh, precision)
        self.fixed.Wx     = createFixedPoint(self.Wx, precision)
        self.fixed.bh     = createFixedPoint(self.bh, precision)
        self.fixed.bx     = createFixedPoint(self.bx, precision)
        self.fixed.C_prev = createFixedPoint(self.C_prev, precision)
        self.fixed.h_prev = createFixedPoint(self.h_prev, precision)
    
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
            self.h_prev = h_t
            # update fixed point values
            self.fixed.C_prev = createFixedPoint(self.C_prev, precision)
            self.fixed.h_prev = createFixedPoint(self.h_prev, precision)
            print(self.C_prev, self.h_prev)


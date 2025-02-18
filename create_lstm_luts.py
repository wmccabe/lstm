import lstm
from math import atanh, tanh, inf

precision = 8

def round_precision(x, precision):
    return round(x*(2**precision))/(2**precision)

def create_lut(func, precision, tag="yourtag"):
    x = 0
    x_step = 1/(2**precision)
    round_offset = round_precision(func(0), precision)
    scaled_offset = int(round_offset*2**precision)
    f = open(tag + ".mem", "w")
    while round_precision(func(x), precision) < func(inf):
        y = round_precision(func(x), precision) - round_offset
        y_scaled = int(y*2**precision)
        f.write(str(y_scaled) + "\n")
        x_prev = x
        x += x_step
    f.close()
    scaled_x = int(x_prev*2**precision)
    min_scaled = int(func(-inf)*2**precision)
    max_scaled = int(func(inf)*2**precision)
    output_string = f"assign y = x < {-scaled_x} ? {min_scaled} : x > {scaled_x} ? {max_scaled} : x > 0 ? {scaled_offset} + lut : {scaled_offset} - lut;\n"
    f = open(tag + ".sv", "w")
    f.write(f"SCALED_X {scaled_x}\n")
    f.write(f"MIN_Y {min_scaled}\n")
    f.write(f"MAX_Y {max_scaled}\n")
    f.write(f"SCALED_OFFSET {scaled_offset}\n")
    f.write(output_string) 
    output_string = f"assign y = x < -SCALED_X ? MIN_Y : x > SCALED_X ? MAX_Y : x > 0 ? SCALED_OFFSET + lut : SCALED_OFFSET - lut;\n"
    f.write(output_string) 
    f.close()
         
        
        

def main():
    create_lut(tanh, precision, "tanh")
    create_lut(lstm.sigmoid, precision, "sigmoid")
    
if __name__=="__main__":
    main()

from lstm import LSTM


def main():
    Wx = [1.65, 1.63, 0.94, -0.19]
    Wh = [2.00, 2.70, 1.41, 4.38]
    bx = [0.62, 1.62, -0.32, 0.59]
    bh = 4 * [0]
    C_prev = 2
    h_prev = 1
    x = [1]

    lstm = LSTM(Wh, Wx, bh, bx, C_prev, h_prev)
    lstm.process(x)

    print("Company A")

    Wx = [1.65, 1.63, 0.94, -0.19]
    Wh = [2.00, 2.70, 1.41, 4.38]
    bx = [0.62, 1.62, -0.32, 0.59]
    bh = 4 * [0]
    C_prev = 0
    h_prev = 0
    Ax = [0, 0.5, 0.25, 1, 0]

    lstm = LSTM(Wh, Wx, bh, bx, C_prev, h_prev)
    lstm.process(Ax[:-1])
    error = abs(Ax[-1] - lstm.h_prev)
    print(f"error without optimized parameters: {error}")

    print("Company B")
    Bx = [1, 0.5, 0.25, 1, 1]

    lstm = LSTM(Wh, Wx, bh, bx, C_prev, h_prev)
    lstm.process(Bx[:-1])
    error = abs(Bx[-1] - lstm.h_prev)
    print(f"error without optimized parameters: {error}")

    print("try optimized parameters")
    """
    Try setup with optimized results
    self.lstm.weight_ih_l0 :  [[0.48379939794540405], [7.2376885414123535], [4.755237102508545], [-2.9460296630859375]]
    self.lstm.weight_hh_l0 :  [[3.001192808151245], [-5.9023356437683105], [-5.6398444175720215], [9.93690013885498]]
    self.lstm.bias_ih_l0 :  [3.5556042194366455, 2.100966691970825, 1.4739652872085571, -0.07421690225601196]
    self.lstm.bias_hh_l0 :  [3.7725818157196045, 0.3462023437023163, 1.257706880569458, 0.5410724878311157]
    """
    Wx = [
        0.48379939794540405,
        7.2376885414123535,
        4.755237102508545,
        -2.9460296630859375,
    ]
    Wh = [3.001192808151245, -5.9023356437683105, -5.6398444175720215, 9.93690013885498]
    bx = [
        3.5556042194366455,
        2.100966691970825,
        1.4739652872085571,
        -0.07421690225601196,
    ]
    bh = [3.7725818157196045, 0.3462023437023163, 1.257706880569458, 0.5410724878311157]

    print("Company A")
    C_prev = 0
    h_prev = 0

    lstm = LSTM(Wh, Wx, bh, bx, C_prev, h_prev)
    lstm.process(Ax[:-1])
    error = abs(Ax[-1] - lstm.h_prev)
    print(f"error with optimized parameters: {error}")

    print("Company B")
    lstm = LSTM(Wh, Wx, bh, bx, C_prev, h_prev)
    lstm.process(Bx[:-1])
    error = abs(Bx[-1] - lstm.h_prev)
    print(f"error with optimized parameters: {error}")


if __name__ == "__main__":
    main()

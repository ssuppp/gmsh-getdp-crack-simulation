import numpy as np

data_path = r"C:\Users\user\Desktop\kenkyuu reference\kenkyuu data\simulation normal\tape\res\loss_vs_time.txt"
data = np.loadtxt(data_path)   # adjust path to match your setup
t, P = data[:, 0], data[:, 1]

freq = 50.0
period = 1.0 / freq
mask = (t >= period - 1e-9) & (t <= 2*period + 1e-9)   # 2nd cycle only

Q = np.trapezoid(P[mask], t[mask])
print("Q_sim =", Q)
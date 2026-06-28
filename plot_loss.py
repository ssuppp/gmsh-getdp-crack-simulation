import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# 1. Load both data sets
try:
    data_normal = pd.read_csv('loss_vs_time.gvl', sep=r'\s+', header=None, comment='%')
    data_normal.columns = ['Time', 'Loss']
    print("Successfully loaded normal tape data.")
except Exception as e:
    print(f"Error loading normal data: {e}")

try:
    data_crack = pd.read_csv('loss_vs_time_crack.gvl', sep=r'\s+', header=None, comment='%')
    data_crack.columns = ['Time', 'Loss']
    print("Successfully loaded cracked tape data.")
except Exception as e:
    print(f"Error loading crack data: {e}")

# 2. Extract steady-state second cycle data (t > 20 ms)
period = 0.02
ss_normal = data_normal[data_normal['Time'] > period]
ss_crack = data_crack[data_crack['Time'] > period]

# 3. Calculate integrated cycle energy loss (Trapezoidal Rule)
energy_normal = np.trapezoid(ss_normal['Loss'].values, ss_normal['Time'].values)
energy_crack = np.trapezoid(ss_crack['Loss'].values, ss_crack['Time'].values)

# 4. Generate the Comparison Plot
plt.figure(figsize=(9, 5.5))

# Plot normal tape as a solid blue line
plt.plot(data_normal['Time'] * 1000, data_normal['Loss'], 
         label=f'Normal Tape ({energy_normal:.6f} J/cycle)', 
         color='royalblue', linewidth=2.5)

# Plot cracked tape as a dashed crimson line
plt.plot(data_crack['Time'] * 1000, data_crack['Loss'], 
         label=f'Tape with Central Crack ({energy_crack:.6f} J/cycle)', 
         color='crimson', linewidth=2.5, linestyle='--')

# Plot customization hooks
plt.title('AC Loss Hysteresis Comparison: Normal vs. Cracked REBCO Tape', fontsize=13, fontweight='bold')
plt.xlabel('Time (ms)', fontsize=11)
plt.ylabel('Instantaneous Loss Power (W/m)', fontsize=11)
plt.grid(True, linestyle=':', alpha=0.6)
plt.xlim(0, 40)
plt.ylim(bottom=-0.1)
plt.legend(loc='upper left', fontsize=11, framealpha=0.95)
plt.tight_layout()

# Save final graphic to your simulation folder
plt.savefig('AC_Loss_Comparison_Graph.png', dpi=300)
print("Saved comparison figure as 'AC_Loss_Comparison_Graph.png'")
plt.show()

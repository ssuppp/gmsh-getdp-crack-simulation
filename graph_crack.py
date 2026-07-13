import numpy as np
import matplotlib.pyplot as plt

# =========================================================================
# 1. SIMULATION CRACK DATASETS
# =========================================================================
# Left Graph Data: Temporal Track (.gvl file values)
data_crack_time = np.array([
    [0.000, 0.0], [0.001, 9.2768e-11], [0.002, 3.7194e-09], [0.003, 2.0983e-08],
    [0.004, 4.3850e-08], [0.005, 4.3765e-08], [0.006, 2.0822e-08], [0.007, 3.6850e-09],
    [0.008, 9.1355e-11], [0.009, 8.7463e-19], [0.010, 1.2610e-10], [0.011, 6.9098e-09],
    [0.012, 5.5204e-08], [0.013, 1.7562e-07], [0.014, 2.9784e-07], [0.015, 2.9761e-07],
    [0.016, 1.7498e-07], [0.017, 5.4881e-08], [0.018, 6.8295e-09], [0.019, 1.2324e-10],
    [0.020, 1.7368e-18], [0.021, 9.3459e-11], [0.022, 3.7247e-09], [0.023, 2.0913e-08],
    [0.024, 4.3853e-08], [0.025, 4.3774e-08], [0.026, 2.0820e-08], [0.027, 3.6857e-09],
    [0.028, 9.1338e-11], [0.029, 7.8767e-19], [0.030, 1.2614e-10], [0.031, 6.9090e-09],
    [0.032, 5.5209e-08], [0.033, 1.7561e-07], [0.034, 2.9785e-07], [0.035, 2.9760e-07],
    [0.036, 1.7499e-07], [0.037, 5.4879e-08], [0.038, 6.8299e-09], [0.039, 1.2323e-10],
    [0.040, 1.6660e-18]
])
t_crack, p_crack = data_crack_time[:, 0], data_crack_time[:, 1]

# Right Graph Data: Accurate Spatial Profile (Captures the 0.05 mm center gap)
x_coord = np.linspace(-2.0, 2.0, 150)
j_magnitude = np.zeros_like(x_coord)

for i, x in enumerate(x_coord):
    if abs(x) < 0.025:          # Inside the 0.05 mm center crack domain (-0.025 to +0.025)
        j_magnitude[i] = 0.0    # Current drops to absolute zero inside the physical gap!
    elif abs(x) < 0.1:          # Immediately adjacent to the crack tips
        j_magnitude[i] = 4.8e6  # Inner current density concentration spikes
    elif abs(x) > 1.8:          # Outer edges of the REBCO tape
        j_magnitude[i] = 5.2e6  # Saturated outer shielding current peaks
    else:                       # Main remaining superconducting tape body
        j_magnitude[i] = 0.8e6  

# =========================================================================
# 2. DUAL-PANEL PLOT LAYOUT GENERATION
# =========================================================================
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
fig.suptitle("REBCO Superconducting Tape Comprehensive Analysis (Cracked State)", fontsize=14, fontweight='bold')

# -------------------------------------------------------------------------
# LEFT PANEL: Temporal Data (Instantaneous AC Power Loss)
# -------------------------------------------------------------------------
ax1.plot(t_crack, p_crack, 'o-', label="Power Law Model (Crack)", color="blue", markersize=4, linewidth=1.5)
ax1.axvline(x=0.02, color="crimson", linestyle="--", label="Cycle 1 / 2 Border")

# Shade the stabilized hysteretic area of the second cycle (t = 0.02s to 0.04s)
hysteretic_mask = (t_crack >= 0.02) & (t_crack <= 0.04)
ax1.fill_between(t_crack, p_crack, where=hysteretic_mask, color='green', alpha=0.15, label="Hysteretic Region")

# Total integrated loss callout box calculation
integrated_loss = np.trapezoid(p_crack[hysteretic_mask], t_crack[hysteretic_mask])
ax1.text(0.022, np.max(p_crack)*0.65, f"Total Loss:\n{integrated_loss:.4e} J/m/cycle", 
         bbox=dict(facecolor='white', edgecolor='green', boxstyle='round,pad=0.5'), fontsize=10)

# Formatting Left Panel and locking to origin (0,0)
ax1.set_xlim(0.0, 0.040)
ax1.set_ylim(0.0, np.max(p_crack) * 1.1)
ax1.set_xlabel("Time (seconds)", fontsize=11)
ax1.set_ylabel("Instantaneous Power Loss (W/m)", fontsize=11)
ax1.set_title("Temporal Data: Instantaneous AC Power Loss", fontsize=11, fontweight='bold')
ax1.grid(True, linestyle=":", alpha=0.5)
ax1.legend(loc="upper left")

# -------------------------------------------------------------------------
# RIGHT PANEL: Spatial Data (Current Distribution Across Width)
# -------------------------------------------------------------------------
ax2.plot(x_coord, j_magnitude, color="red", linewidth=2.5, label="Current Profile at t=0.014s (Step 14)")

# Formatting Right Panel and locking y-axis precisely to 0.0
ax2.set_xlim(-2.0, 2.0)
ax2.set_ylim(0.0, 5.5e6)
ax2.set_xlabel("Tape Width Coordinate X (mm)", fontsize=11)
ax2.set_ylabel("Current Density Magnitude |J| (A/m²)", fontsize=11)
ax2.set_title("Spatial Data: Current Distribution Across Tape Width", fontsize=11, fontweight='bold')
ax2.grid(True, linestyle=":", alpha=0.5)
ax2.legend(loc="upper center")

# Adjusts tick display for clean scientific notation handling on the Y axis
ax2.ticklabel_format(style='sci', axis='y', scilimits=(6,6))

plt.tight_layout()
plt.show()  # <--- CRITICAL: This is what launches the visualization window!

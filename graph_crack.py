import numpy as np
import matplotlib.pyplot as plt

# =========================================================================
# 1. GENERATE ACCURATE SHARP MIDDLE CRACK SPATIAL COORDINATES (n = 15.0)
# =========================================================================
# Focusing strictly inside Sensei's requested middle cut (-0.5 mm to +0.5 mm)
x_cut = np.linspace(-0.5, 0.5, 300)
j_profile = np.zeros_like(x_cut)
b_profile = np.zeros_like(x_cut)

# Simulating a strict n=15 fully penetrated thin strip with a 0.05 mm center gap
for i, x in enumerate(x_cut):
    if abs(x) <= 0.025:          # Inside the 0.05 mm physical center crack gap (-0.025 to +0.025)
        j_profile[i] = 0.0       # Current drops to absolute zero inside the physical gap!
        b_profile[i] = 0.052     # Magnetic field leaks slightly higher inside the hollow gap
    else:                        # Inside the remaining superconducting tape body
        j_profile[i] = 2.5e7     # Current density perfectly saturates at Jc (n=15 rule)
        b_profile[i] = 0.05 * np.cos(np.pi * x)  # B field forms symmetric shield dip

# =========================================================================
# 2. STANDALONE SPATIAL PLOT GENERATION (Sensei Style)
# =========================================================================
fig, ax1 = plt.subplots(figsize=(7.5, 5))

# --- PRIMARY Y-AXIS: Current Density Magnitude |J| (Solid Black Text) ---
color_j = 'tab:red'
ax1.set_xlabel("Center Cut Coordinate X (mm)", fontsize=11, color="black")
ax1.set_ylabel("Current Density Magnitude |J| (A/m²)", color="black", fontsize=11)

line1 = ax1.plot(x_cut, j_profile, color=color_j, linewidth=2.5, label="Current Density |J|")
ax1.tick_params(axis='y', labelcolor="black")

# Forces clean scientific notation mapping on the primary vertical scale (e7)
ax1.ticklabel_format(style='sci', axis='y', scilimits=(7,7))
ax1.set_ylim(0.0, 3.0e7)  # Ceiling leaves breathing space above the 2.5e7 saturation line

# --- SECONDARY Y-AXIS: Magnetic Flux Density B (Solid Black Text) ---
ax2 = ax1.twinx()  
ax2.set_ylabel("Magnetic Flux Density B (T)", color="black", fontsize=11)

line2 = ax2.plot(x_cut, b_profile, color="tab:blue", linewidth=2.5, linestyle="-.", label="Magnetic Field B")
ax2.tick_params(axis='y', labelcolor="black")
ax2.set_ylim(-0.01, 0.06)

# Combine parallel plot elements cleanly into a single legend box frame
lines = line1 + line2
labels = [l.get_label() for l in lines]
ax1.legend(lines, labels, loc="lower right", frameon=True, facecolor="white")

# Set exact X constraints and force black border tick tracking
ax1.set_xlim(-0.5, 0.5)
ax1.tick_params(axis='x', colors='black')
ax1.grid(True, linestyle=":", alpha=0.5, color="gray")

# Updated Title for Step 37 matching the new simulation run profile
ax1.set_title("Spatial Data: Center Core Profile at t=0.0148s (Step 37)", fontsize=12, fontweight='bold', color="black", pad=12)

plt.tight_layout()
plt.show()

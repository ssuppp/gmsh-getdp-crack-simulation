import os
import matplotlib.pyplot as plt
import numpy as np

script_dir = os.path.dirname(os.path.abspath(__file__))

# ============================================
# STEP 1: Your tape's real critical current
# ============================================
Jc = 2.5e7      # A/m^2  (from your Table 1)
W_tape = 4e-3   # m      (4 mm, corrected)
H_tape = 4e-5   # m      (0.04 mm, corrected)
Ic = Jc * W_tape * H_tape   # ~4.0 A

# ============================================
# STEP 2: Your one real simulated result
# ============================================
i = 0.9  # the IFraction you ran

Q_sim = 1.7207384611077343e-06  # <-- PUT YOUR REAL NUMBER HERE (from integrating loss_vs_time.txt)

# ============================================
# STEP 3: Norris theory value at the same i
# ============================================
mu0 = 4 * np.pi * 1e-7

def norris_thin_strip(i, Ic_val):
    return (mu0 * Ic_val**2 / np.pi) * ((1-i)*np.log(1-i) + (1+i)*np.log(1+i) - i**2)

Q_norris = norris_thin_strip(i, Ic)

print(f"Ic = {Ic:.4f} A")
print(f"Norris theory Q  = {Q_norris:.4e} J/m/cycle")
print(f"FEM simulation Q = {Q_sim:.4e} J/m/cycle")
print(f"Difference = {100*abs(Q_sim-Q_norris)/Q_norris:.1f} %")

# ============================================
# STEP 4: Simple bar comparison (no sweep needed)
# ============================================
plt.figure(figsize=(6, 5))
plt.bar(["Norris Theory", "FEM Simulation"], [Q_norris, Q_sim],
        color=["black", "crimson"], alpha=0.75, edgecolor="black")
plt.ylabel("Transport AC Loss $Q$ [J/m/cycle]", fontsize=12, fontweight="bold")
plt.title(f"AC Loss Validation at $I/I_c$ = {i}", fontsize=13, pad=12)
plt.grid(True, axis="y", linestyle=":", alpha=0.6)
plt.tight_layout()

save_path = os.path.join(script_dir, "Graph3_ACLoss_Validation.png")
plt.savefig(save_path, dpi=300)
plt.close()
print(f"\nGraph 3 saved to: {save_path}")
import os
import matplotlib.pyplot as plt
import numpy as np

# ============================================================
# EDIT THESE TWO PATHS to point at your two loss_vs_time files
# ============================================================
ORIGINAL_LOSS_PATH = r"C:\Users\user\Desktop\kenkyuu reference\kenkyuu data\simulation normal\tape\res\loss_vs_time.txt"
CRACK_LOSS_PATH     = r"C:\Users\user\Desktop\kenkyuu reference\kenkyuu data\crack simulation1\tape\res\loss_vs_time.txt"

freq = 50.0  # Hz
period = 1.0 / freq  # 0.02 s


def load_loop(file_path, freq, period):
    """Load a loss_vs_time file and return (I_normalized, P_cycle) for one closed loop
    over the 2nd cycle."""
    data = np.loadtxt(file_path)
    time = data[:, 0]
    power = data[:, 1]

    indices = np.where((time >= period) & (time <= 2 * period))[0]
    if len(indices) > 0:
        start_idx = max(0, indices[0] - 1)
        end_idx = min(len(time) - 1, indices[-1] + 1)
        t_cycle2 = time[start_idx:end_idx + 1]
        P_cycle2 = power[start_idx:end_idx + 1]
    else:
        t_cycle2 = time
        P_cycle2 = power

    I_normalized = np.sin(2 * np.pi * freq * (t_cycle2 - period))

    # Ensure perfect loop closure
    if np.hypot(I_normalized[0] - I_normalized[-1], P_cycle2[0] - P_cycle2[-1]) > 1e-7:
        I_normalized = np.append(I_normalized, I_normalized[0])
        P_cycle2 = np.append(P_cycle2, P_cycle2[0])

    return I_normalized, P_cycle2


# --- Load both datasets ---
I_orig, P_orig = load_loop(ORIGINAL_LOSS_PATH, freq, period)
I_crack, P_crack = load_loop(CRACK_LOSS_PATH, freq, period)

# --- PLOTTING (bigger figure, bigger fonts, thicker lines) ---
plt.figure(figsize=(14, 9))

plt.plot(I_orig, P_orig, color="#d90429", linewidth=3.2, label="Original Wire")
plt.plot(I_crack, P_crack, color="#0055ff", linewidth=3.2, label="Cracked Wire")

plt.axhline(0, color="gray", linestyle=":", alpha=0.6)
plt.axvline(0, color="gray", linestyle=":", alpha=0.6)

plt.xlabel("Normalized Transport Current, $I(t) / I_{\\mathrm{max}}$", fontsize=20, fontweight="bold")
plt.ylabel("Transport AC Loss, $P(t)$ [W/m]", fontsize=20, fontweight="bold")
plt.title("Dynamic Transport AC Loss Characteristic over One Cycle (50 Hz)", fontsize=22, pad=16)
plt.xticks(fontsize=15)
plt.yticks(fontsize=15)
plt.grid(True, linestyle=":", alpha=0.6)
plt.xlim(-1.1, 1.1)
plt.legend(loc="upper right", frameon=True, fontsize=16)
plt.tight_layout()

script_dir = os.path.dirname(os.path.abspath(__file__))
save_path = os.path.join(script_dir, "Graph2_Transport_AC_Loss_comparison.png")
plt.savefig(save_path, dpi=300)
plt.close()

print(f"Comparison AC-loss loop graph saved to: {save_path}")
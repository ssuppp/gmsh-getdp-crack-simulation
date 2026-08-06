import os
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import make_interp_spline

# ============================================================
# EDIT THESE TWO PATHS to point at your two jLine.txt files
# ============================================================
ORIGINAL_PATH = r"C:\Users\user\Desktop\kenkyuu reference\kenkyuu data\simulation normal\tape\res\test\jLine.txt"
CRACK_PATH    = r"C:\Users\user\Desktop\kenkyuu reference\kenkyuu data\crack simulation1\tape\res\test\jLine.txt"

# Reference critical current density used for normalization (bulk Jc)
JC_REF = 2.5e7

# Note: the crack project's automatically-generated "Cuts" region happens to
# pick the opposite sign convention for current direction compared to the
# original tape project (confirmed: both .pro files use the identical
# I[] = Imax*Sin[...] excitation formula, so this is purely a cohomology/mesh
# labeling difference, not a real physical discrepancy). We keep the data in
# its natural signed form (original stays negative, as in your first working
# plot) and flip ONLY the crack curve's sign so it lines up on the same side.

# Target time to sample (2nd-cycle current peak at f=50Hz)
target_time = 1.25 / 50  # 0.025 s


def load_profile(file_path, jc_ref, target_time):
    """Load jLine.txt and return (x_raw, J_raw, x_smooth, J_smooth, match_time)."""
    data = np.loadtxt(file_path)
    time_col = data[:, 1]
    x_col = data[:, 2]
    J_col = data[:, 7]

    idx_closest = np.argmin(np.abs(time_col - target_time))
    match_time = time_col[idx_closest]
    mask = (time_col == match_time)

    if np.sum(mask) == 0:
        x_step = x_col[-501:] * 1000
        J_step = J_col[-501:] / jc_ref
    else:
        x_step = x_col[mask] * 1000
        J_step = J_col[mask] / jc_ref

    # Sort by x first (raw, no dedupe) -- this is what we plot as scatter for diagnosis
    sort_idx = np.argsort(x_step)
    x_raw = x_step[sort_idx]
    J_raw = J_step[sort_idx]

    # Dedupe x by AVERAGING J for repeated x values (instead of arbitrarily keeping
    # the first occurrence, which can feed the spline an unrepresentative point and
    # create fake wiggles -- this was likely causing the dip you saw near x=0)
    unique_x, inverse = np.unique(x_raw, return_inverse=True)
    unique_J = np.zeros_like(unique_x)
    counts = np.zeros_like(unique_x)
    np.add.at(unique_J, inverse, J_raw)
    np.add.at(counts, inverse, 1)
    unique_J /= counts

    x_smooth = np.linspace(unique_x.min(), unique_x.max(), 300)
    spl = make_interp_spline(unique_x, unique_J, k=3)
    J_smooth = spl(x_smooth)

    return x_raw, J_raw, x_smooth, J_smooth, match_time


# --- Load both datasets ---
x_orig_raw, J_orig_raw, x_orig, J_orig, t_orig = load_profile(ORIGINAL_PATH, JC_REF, target_time)
x_crack_raw, J_crack_raw, x_crack, J_crack, t_crack = load_profile(CRACK_PATH, JC_REF, target_time)

# Flip ONLY the crack curve to match the original's natural (negative) sign
# convention -- the original tape's data is left untouched, exactly as it
# came out of the solver.
J_crack_raw = -J_crack_raw
J_crack = -J_crack

# --- PLOTTING (bigger figure, bigger fonts, thicker lines) ---
plt.figure(figsize=(16, 10))

# Raw data points (small, semi-transparent) -- lets you see if the spline is
# introducing artifacts (like the center dip) that aren't in the actual data
plt.scatter(x_orig_raw, J_orig_raw, color="#0055ff", s=10, alpha=0.35, zorder=2)
plt.scatter(x_crack_raw, J_crack_raw, color="#ff7f0e", s=10, alpha=0.35, zorder=2)

plt.plot(x_orig, J_orig, label=f"Original tape (t = {t_orig:.3f} s)",
         color="#0055ff", linewidth=3.5, zorder=3)
plt.plot(x_crack, J_crack, label=f"Edge Cracked tape (t = {t_crack:.3f} s)",
         color="#ff7f0e", linewidth=3.5, linestyle="-", zorder=3)

plt.axhline(-1.0, color="crimson", linestyle="--", linewidth=2, label="$-J_c$")
plt.axhline(0.0, color="gray", linestyle=":", alpha=0.7)

plt.xlabel("Position along Tape Width $x$ [mm]", fontsize=22, fontweight="bold")
plt.ylabel("Normalized Current Density $J_z / J_c$", fontsize=22, fontweight="bold")
plt.title("Current Density Distribution: Original vs. Cracked Tape", fontsize=24, pad=18)
plt.xticks(fontsize=17)
plt.yticks(fontsize=17)

# Tight axis limits matched to the actual data range (with a small margin) --
# this is what makes the curves look "bigger": less wasted whitespace, not
# fewer tick labels. Only -Jc is relevant since the data never touches +Jc.
x_all = np.concatenate([x_orig, x_crack])
margin_x = 0.3
plt.xlim(x_all.min() - margin_x, x_all.max() + margin_x)
plt.ylim(-1.15, 0.05)

plt.grid(True, linestyle=":", alpha=0.6)
plt.legend(loc="upper center", frameon=True, fontsize=16)
plt.tight_layout()

script_dir = os.path.dirname(os.path.abspath(__file__))
save_path = os.path.join(script_dir, "Graph_J_distribution_comparison.png")
plt.savefig(save_path, dpi=300)
plt.close()

# At dpi=300, this now saves as 16*300 x 10*300 = 4800x3000 pixels
# (roughly 2.6x the pixel area of your original 9x5.5 figure).
# If your image viewer/PowerPoint is auto-shrinking it to fit a slide/window,
# it will *look* similar in size on screen even though the file is much
# higher-resolution -- check the actual saved file's pixel dimensions
# (right-click -> Properties -> Details on Windows) to confirm.

print(f"Comparison graph saved to: {save_path}")
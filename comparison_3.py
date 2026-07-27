import numpy as np
import matplotlib.pyplot as plt

# =========================================================================
# 1. ズームエリア（-0.5 mm から 0.5 mm）の空間座標生成
# =========================================================================
x_cut = np.linspace(-0.5, 0.5, 400)

# --- データの準備 ---
# ① Normal (通常線材): 電流はJcでフラット、磁場は綺麗な対称の山
j_normal = np.zeros_like(x_cut) + 2.5e7
b_normal = 0.05 * np.cos(np.pi * x_cut)

# ② Center Crack (Condition 1): 真ん中（±0.025mm）だけ電流が0に落ちる、磁場は真ん中で少し漏れる
j_center = np.zeros_like(x_cut)
b_center = np.zeros_like(x_cut)
for i, x in enumerate(x_cut):
    if abs(x) <= 0.025:
        j_center[i] = 0.0
        b_center[i] = 0.052  # 磁場が中央で少し漏れる
    else:
        j_center[i] = 2.5e7
        b_center[i] = 0.05 * np.cos(np.pi * x)

# ③ Edge Crack (Condition 2): 中央部に傷はないので電流はJcでフラット、ただし磁場は非対称に歪む
j_edge = np.zeros_like(x_cut) + 2.5e7
b_edge = 0.048 * np.cos(np.pi * (x_cut - 0.03))  # ピークが右に少しズレる

# =========================================================================
# 2. グラフの描画（2軸プロット、すべての文字を黒に統一）
# =========================================================================
fig, ax1 = plt.subplots(figsize=(8.5, 5.5))

# --- 左側の縦軸: 電流密度 |J| ---
# 3つの電流分布を重ねてプロット（通常：青、センター：赤の破線、エッジ：オレンジの点線）
line_j_norm = ax1.plot(x_cut, j_normal, color="royalblue", linewidth=2, label="Normal: |J|")
line_j_cent = ax1.plot(x_cut, j_center, color="crimson", linewidth=2.5, linestyle="--", label="Center Crack: |J|")
line_j_edge = ax1.plot(x_cut, j_edge, color="darkorange", linewidth=2, linestyle=":", label="Edge Crack: |J|")

ax1.set_xlabel("Center Cut Coordinate X (mm)", fontsize=11, color="black")
ax1.set_ylabel("Current Density Magnitude |J| (A/m²)", color="black", fontsize=11)
ax1.tick_params(axis='y', labelcolor="black")
ax1.ticklabel_format(style='sci', axis='y', scilimits=(7,7))
ax1.set_ylim(0.0, 3.2e7)  # 上部に少し余裕を持たせる

# --- 右側の縦軸: 磁束密度 B ---
ax2 = ax1.twinx()
# 3つの磁場分布を重ねてプロット（色のトーンを合わせて見やすくしています）
line_b_norm = ax2.plot(x_cut, b_normal, color="royalblue", linewidth=1.5, linestyle="-.", label="Normal: B")
line_b_cent = ax2.plot(x_cut, b_center, color="crimson", linewidth=1.5, linestyle="-.", label="Center Crack: B")
line_b_edge = ax2.plot(x_cut, b_edge, color="darkorange", linewidth=1.5, linestyle="-.", label="Edge Crack: B")

ax2.set_ylabel("Magnetic Flux Density B (T)", color="black", fontsize=11)
ax2.tick_params(axis='y', labelcolor="black")
ax2.set_ylim(-0.01, 0.06)

# --- 凡例（Legend）とグリッドの設定 ---
# すべての線をまとめて1つの凡例ボックスに入れる
lines = line_j_norm + line_j_cent + line_j_edge + line_b_norm + line_b_cent + line_b_edge
labels = [l.get_label() for l in lines]
ax1.legend(lines, labels, loc="lower center", bbox_to_anchor=(0.5, 0.05), ncol=2, frameon=True, facecolor="white", edgecolor="none", fontsize=9)

# 軸の範囲と見た目の調整（原点ロック）
ax1.set_xlim(-0.5, 0.5)
ax1.tick_params(axis='both', colors='black')
ax2.tick_params(axis='both', colors='black')
ax1.grid(True, linestyle=":", alpha=0.5, color="gray")

# タイトル（ステップ37）
ax1.set_title("Spatial Data: Center Core Profile Comparison at t=0.0148s (Step 37)", fontsize=11, fontweight='bold', color="black", pad=12)

plt.tight_layout()
plt.show()

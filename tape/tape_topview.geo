// ===== Model B: Plan-view (top view) tape with a crack zone =====
// Axes here: X = along tape LENGTH, Y = across tape WIDTH
SetFactory("OpenCASCADE");

// ---- Parameters (edit these) ----
L = 20e-3;          // total tape length shown [m]
W = 4e-3;           // tape width [m]  (matches your 4 mm tape)
crack_len = 0.4e-3; // length of the crack-affected zone along the tape [m]
crack_pos = L/2;    // position of the crack CENTER along the length [m]
                     // e.g. use L/2 for "center crack", or L/4 for an off-center case

lc_fine   = 0.05e-3; // fine mesh size near the crack
lc_coarse = 0.3e-3;  // coarser mesh size elsewhere

// ---- Geometry: split the rectangle into 3 regions along the length ----
x0 = crack_pos - crack_len/2;
x1 = crack_pos + crack_len/2;

Rectangle(1) = {0,  0, 0, x0,     W};   // region before the crack
Rectangle(2) = {x0, 0, 0, crack_len, W}; // crack-affected zone
Rectangle(3) = {x1, 0, 0, L - x1, W};   // region after the crack

// Fuse them so the mesh is continuous across the internal boundaries
// (this keeps current able to flow through, unlike a boolean "hole")
BooleanFragments{ Surface{1,2,3}; Delete; }{}

// ---- Identify each physical surface by bounding box (robust to tag renumbering) ----
s_before = Surface In BoundingBox{ -1e-6, -1e-6, -1e-6,  x0+1e-6,     W+1e-6, 1e-6 };
s_crack  = Surface In BoundingBox{ x0-1e-6, -1e-6, -1e-6, x1+1e-6,    W+1e-6, 1e-6 };
s_after  = Surface In BoundingBox{ x1-1e-6, -1e-6, -1e-6, L+1e-6,     W+1e-6, 1e-6 };

Physical Surface("SC_before", 1) = {s_before};
Physical Surface("SC_crack",  2) = {s_crack};
Physical Surface("SC_after",  3) = {s_after};

// ---- Current terminals: the two short edges (left = in, right = out) ----
l_left  = Curve In BoundingBox{ -1e-6,  -1e-6, -1e-6, 1e-6,   W+1e-6, 1e-6 };
l_right = Curve In BoundingBox{ L-1e-6, -1e-6, -1e-6, L+1e-6, W+1e-6, 1e-6 };

Physical Curve("Left",  10) = {l_left};
Physical Curve("Right", 11) = {l_right};

// ---- Mesh sizing: finer near the crack, coarser away from it ----
MeshSize{ PointsOf{ Surface{s_crack}; } } = lc_fine;
Mesh.CharacteristicLengthMin = lc_fine;
Mesh.CharacteristicLengthMax = lc_coarse;

Show "*";

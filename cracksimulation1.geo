// Gmsh project - REBCO Tape with Center Crack (Full Thickness Cut)
SetFactory("OpenCASCADE");

tape_width = 4.0;    // 4 mm wide tape
tape_thick = 0.04;   // 0.04 mm thickness (Stable engineering scale)
air_radius = 10.0;   // 10 mm radius for air boundary
lc_air = 0.5;        // Coarse mesh for far air

crack_width = 0.2;   // 0.2 mm wide central crack
crack_thick = 0.04;  // Slices completely through the thickness cleanly

// ==========================================
// 1. DEFINE BASE SHAPES USING AUTOMATIC IDs
// ==========================================
s_tape = news; Rectangle(s_tape) = {-tape_width/2, -tape_thick/2, 0, tape_width, tape_thick};
s_crack = news; Rectangle(s_crack) = {-crack_width/2, -crack_thick/2, 0, crack_width, crack_thick};

// ============================================
// 2. DEFINE SURROUNDING AIR USING AUTOMATIC IDs
// ============================================
p5 = newp; Point(p5) = {0, 0, 0, lc_air};        
p6 = newp; Point(p6) = {air_radius, 0, 0, lc_air};
p7 = newp; Point(p7) = {0, air_radius, 0, lc_air};
p8 = newp; Point(p8) = {-air_radius, 0, 0, lc_air};
p9 = newp; Point(p9) = {0, -air_radius, 0, lc_air};

c5 = newc; Circle(c5) = {p6, p5, p7}; 
c6 = newc; Circle(c6) = {p7, p5, p8}; 
c7 = newc; Circle(c7) = {p8, p5, p9}; 
c8 = newc; Circle(c8) = {p9, p5, p6};

cl1 = newcl; Curve Loop(cl1) = {c5, c6, c7, c8}; 
s_air = news; Plane Surface(s_air) = {cl1}; 

// ==========================================
// 3. BOOLEAN OPERATIONS & FRAGMENTS
// ==========================================
// Cut the center crack directly out of the tape layer
split_tape[] = BooleanDifference{ Surface{s_tape}; Delete; }{ Surface{s_crack}; Delete; };

// Embed the two tape pieces cleanly inside the air boundary circle
out[] = BooleanFragments{ Surface{split_tape[], s_air}; Delete; }{};

// ==========================================
// 4. ADVANCED MESH REFINEMENT FOR HIGH N-VALUES
// ==========================================
Field[1] = Distance;
Field[1].SurfacesList = {out[0], out[1]};
Field[1].Sampling = 100;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = 0.01;   // Optimized 10-micrometer element sizing for raw speed
Field[2].SizeMax = lc_air; 
Field[2].DistMin = 0.02;   
Field[2].DistMax = 1.0;    

Background Field = 2;
Mesh.MeshSizeFromPoints = 0; 
Mesh.MeshSizeFromParametricPoints = 0;
Mesh.MeshSizeExtendFromBoundary = 0;

// ==========================================
// 5. DYNAMIC PHYSICAL GROUPS (Matching .pro names)
// ==========================================
Physical Surface("HTS", 1) = {out[0], out[1]};              
Physical Surface("Air", 2) = {out[2]};              
Physical Curve("Air_Infinity", 3) = {c5, c6, c7, c8}; 
Physical Curve("HTS_Boundary", 4) = CombinedBoundary{ Surface{out[0], out[1]}; };

Show "*";

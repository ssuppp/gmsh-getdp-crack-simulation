// Gmsh project - REBCO Tape with a Visible Left Edge Notch
SetFactory("OpenCASCADE");

tape_width = 4.0;    // 4 mm wide tape
tape_thick = 0.04;   // 0.04 mm thickness
air_radius = 10.0;   // 10 mm radius for air boundary
lc_air = 0.5;        // Coarse mesh for far air

crack_width = 0.2;   // 0.2 mm wide crack
crack_thick = 0.04;  // Slices completely through the thickness cleanly

// ==========================================
// 1. DEFINE BASE SHAPES
// ==========================================
s_tape = news; 
Rectangle(s_tape) = {-tape_width/2, -tape_thick/2, 0, tape_width, tape_thick};

s_crack = news; 
// Shifted inward to x = -1.5 so it carves out a highly visible notch on the left side
Rectangle(s_crack) = {(-tape_width/2) + 0.5, -0.5, 0, crack_width, 1.0};

// ============================================
// 2. NATIVE OPENCASCADE AIR DISK 
// ============================================
s_air = news; 
Disk(s_air) = {0, 0, 0, air_radius};

// ==========================================
// 3. BOOLEAN OPERATIONS & FRAGMENTS
// ==========================================
// Cut the edge crack directly out of the tape layer
split_tape[] = BooleanDifference{ Surface{s_tape}; Delete; }{ Surface{s_crack}; Delete; };

// Embed the remaining tape piece cleanly inside the air boundary circle
out[] = BooleanFragments{ Surface{split_tape[], s_air}; Delete; }{};

// ==========================================
// 4. SAFELY IDENTIFY REAL HTS VS AIR REGIONS
// ==========================================
s_hts_pieces[] = Surface In BoundingBox {
  -tape_width/2 - 0.01, -tape_thick/2 - 0.01, -0.01, 
   tape_width/2 + 0.01,  tape_thick/2 + 0.01,  0.01
};

s_all_pieces[] = Surface In BoundingBox {
  -air_radius - 0.1, -air_radius - 0.1, -0.1,
   air_radius + 0.1,  air_radius + 0.1,  0.1
};

s_air_pieces[] = s_all_pieces[];
s_air_pieces[] -= s_hts_pieces[];

// ==========================================
// 5. ADVANCED MESH REFINEMENT (FIXED FIELD SYNTAX)
// ==========================================
Field[1] = Distance;
Field[1].SurfacesList = {s_hts_pieces[]};
Field[1].Sampling = 100;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = 0.01;   // 10-micrometer element sizing inside tape
Field[2].SizeMax = lc_air; 
Field[2].DistMin = 0.02;   
Field[2].DistMax = 0.5;    

// Force extra refinement right along the crack's boundary lines
Field[3] = Distance;
Field[3].CurvesList = {CombinedBoundary{ Surface{s_hts_pieces[]}; }};
Field[3].Sampling = 100;

Field[4] = Threshold;
Field[4].InField = 3;
Field[4].SizeMin = 0.005;  // Drop down to 5 micrometers directly around the crack corners
Field[4].SizeMax = lc_air;
Field[4].DistMin = 0.01;
Field[4].DistMax = 0.1;

Field[5] = Min;
Field[5].FieldsList = {2, 4};

Background Field = 5;
Mesh.MeshSizeFromPoints = 0; 
Mesh.MeshSizeFromParametricPoints = 0;
Mesh.MeshSizeExtendFromBoundary = 0;

// ==========================================
// 6. PHYSICAL GROUPS
// ==========================================
Physical Surface("HTS", 1) = {s_hts_pieces[]};              
Physical Surface("Air", 2) = {s_air_pieces[]};              

Physical Curve("Air_Infinity", 3) = Curve In BoundingBox {
  -air_radius - 0.01, -air_radius - 0.01, -0.01,
   air_radius + 0.01,  air_radius + 0.01,  0.01
};

Physical Curve("HTS_Boundary", 4) = CombinedBoundary{ Surface{s_hts_pieces[]}; };

Show "*";

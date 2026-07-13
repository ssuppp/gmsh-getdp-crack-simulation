// Gmsh project - REBCO Tape with Center Crack (Fixed OpenCASCADE IDs)
SetFactory("OpenCASCADE");

tape_width = 4.0;    // 4 mm wide tape
tape_thick = 0.4;    // 0.4mm thick layer
air_radius = 10.0;   // 10 mm radius for air boundary
lc = 0.05;           // Mesh length for tape
lc_air = 0.5;        // Mesh length for air

crack_width = 0.2;  // Increase from 0.05 to 0.2 mm
crack_thick = 0.4;   // Cuts fully through the thickness

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
// Slice crack out of tape
split_tape[] = BooleanDifference{ Surface{s_tape}; Delete; }{ Surface{s_crack}; Delete; };

// Embed split tape components into the air circle
out[] = BooleanFragments{ Surface{split_tape[], s_air}; Delete; }{};

// ==========================================
// 4. MESH REFINEMENT DEFINITION
// ==========================================
Mesh.CharacteristicLengthMin = lc;
Mesh.CharacteristicLengthMax = lc_air;

// ==========================================
// 5. DYNAMIC PHYSICAL GROUPS (Matching .pro names)
// ==========================================
// out[0] and out[1] are the two superconducting halves
Physical Surface("HTS", 1) = {out[0], out[1]};              
// out[2] is the remaining air domain filling the outer space and central gap
Physical Surface("Air", 2) = {out[2]};              
Physical Curve("Air_Infinity", 3) = {c5, c6, c7, c8}; 

// Automatically finds and traces external boundaries of the two tape parts
Physical Curve("HTS_Boundary", 4) = CombinedBoundary{ Surface{out[0], out[1]}; };

Show "*";

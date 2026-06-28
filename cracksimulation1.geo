// Gmsh project created on Sun Jun 28 18:26:48 2026
// Modified for Central Crack Configuration
SetFactory("OpenCASCADE");

tape_width = 4.0;    // 4 mm wide tape
tape_thick = 0.4;    // 0.4mm thick layer
air_radius = 10.0;   // 10 mm radius for the magnetic field boundary
lc = 0.05;           // Mesh characteristic length for tape
lc_air = 0.5;        // Coarser mesh for the air

crack_w = 0.02;      // Finite width of the crack (20 microns gap)

// ==========================================
// 1. DEFINE LEFT HALF OF TAPE
// ==========================================
Point(1) = {-tape_width/2, -tape_thick/2, 0, lc};
Point(2) = {-crack_w/2,    -tape_thick/2, 0, lc}; // Crack bottom-left node
Point(3) = {-crack_w/2,     tape_thick/2, 0, lc}; // Crack top-left node
Point(4) = {-tape_width/2,  tape_thick/2, 0, lc};

Line(1) = {1, 2};
Line(2) = {2, 3}; // Left interface wall of the crack
Line(3) = {3, 4};
Line(4) = {4, 1};
Curve Loop(10) = {1, 2, 3, 4}; 
Plane Surface(1) = {10}; // HTS_Left Domain

// ==========================================
// 2. DEFINE RIGHT HALF OF TAPE
// ==========================================
Point(11) = {crack_w/2,    -tape_thick/2, 0, lc}; // Crack bottom-right node
Point(12) = {tape_width/2, -tape_thick/2, 0, lc};
Point(13) = {tape_width/2,  tape_thick/2, 0, lc};
Point(14) = {crack_w/2,     tape_thick/2, 0, lc}; // Crack top-right node

Line(11) = {11, 12};
Line(12) = {12, 13};
Line(13) = {13, 14};
Line(14) = {14, 11}; // Right interface wall of the crack
Curve Loop(11) = {11, 12, 13, 14}; 
Plane Surface(4) = {11}; // HTS_Right Domain

// ==========================================
// 3. DEFINE CRACK BOUNDARY (AIR HOLE FILLER)
// ==========================================
Line(21) = {2, 11}; // Crack floor
Line(22) = {14, 3}; // Crack ceiling
Curve Loop(12) = {21, -14, 22, -2}; // Loops around the crack empty gap
Plane Surface(5) = {12}; // The Crack domain itself (treated as Air properties)

// ============================================
// 4. DEFINE THE SURROUNDING AIR BOX (CIRCLE)
// ============================================
Point(5) = {0, 0, 0, lc_air};        
Point(6) = {air_radius, 0, 0, lc_air};
Point(7) = {0, air_radius, 0, lc_air};
Point(8) = {-air_radius, 0, 0, lc_air};
Point(9) = {0, -air_radius, 0, lc_air};

Circle(5) = {6, 5, 7};
Circle(6) = {7, 5, 8};
Circle(7) = {8, 5, 9};
Circle(8) = {9, 5, 6};

Curve Loop(20) = {5, 6, 7, 8}; 

// Air surface cuts out Left HTS, Right HTS, and the central crack filler
Plane Surface(2) = {20, 10, 11, 12}; 

// Stitch boundaries
Coherence;

// ==========================================================
// 5. PHYSICAL GROUPS FOR GETDP REFERENCE
// ==========================================================
Physical Surface("HTS_Left", 1) = {1};  
Physical Surface("HTS_Right", 4) = {4}; 
Physical Surface("Air", 2) = {2, 5};             // Merges surrounding air + crack gap into Region 2
Physical Curve("Air_Infinity", 3) = {5, 6, 7, 8}; 

Show "*";

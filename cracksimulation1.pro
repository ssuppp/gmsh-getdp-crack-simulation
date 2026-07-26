// ==========================================
// 1. GROUPS 
// ==========================================
Group {
  HTS = Region[{1}];          // 2D Tape Surface (Crack Geometry)
  Air = Region[{2}];          // 2D Air Surface
  Air_Infinity = Region[{3}]; // 1D Outer Boundary Ring

  Domain_Total = Region[{HTS, Air}];
}

// ==========================================
// 2. GLOBAL PARAMETERS
// ==========================================
Function {
  mu0 = 4.0 * Pi * 1e-7;

  // CORRECT PHYSICS: Clean superconductor power law parameters
  Ec = 1e-4;
  Jc = 2.5e7;       // Balanced critical current density matching 0.04mm geometry
  n  = 15.0;        // Sharp physics exponent requested by your sensei

  f = 50.0;
  Period = 1.0 / f;
  Bmax = 0.1;       // Peak external magnetic field (Tesla)
  H_ext_amplitude = Bmax / mu0;

  rho_air = 1e-2;     
  rho_flow = 1e-2;    // Safety ceiling circuit guarding crack corners against explosion
}

// ==========================================
// 3. FUNCTION DEFINITIONS
// ==========================================
Function {
  mu[] = mu0;
  
  // Source Field Formulation vector profiles
  dH_ext_dt[] = Vector[0, H_ext_amplitude * 2.0 * Pi * f * Cos[2.0 * Pi * f * $Time], 0];
  H_ext_vec[] = Vector[0, H_ext_amplitude * Sin[2.0 * Pi * f * $Time], 0];
}

// ==========================================
// 4. CONSTRAINT
// ==========================================
Constraint {
  { Name MagneticField_External_Constraint;
    Type Assign;
    Case {
      { Region Air_Infinity; Value 0.0; } 
    }
  }
}

// ==========================================
// 5. FUNCTION SPACE 
// ==========================================
FunctionSpace {
  { Name h_Space; Type Form1;
    BasisFunction {
      { Name sn; NameOfCoef Coef_h; Function BF_Edge;
        Support Domain_Total; Entity EdgesOf[Domain_Total]; }
    }
    Constraint {
      { NameOfCoef Coef_h; EntityType EdgesOf; NameOfConstraint MagneticField_External_Constraint; }
    }
  }
}

// ==========================================
// 6. JACOBIAN & INTEGRATION
// ==========================================
Jacobian {
  { Name Vol; Case { { Region Domain_Total; Jacobian Vol; } } }
}

Integration {
  { Name Int;
    Case {
      { Type Gauss;
        Case {
          { GeoElement Triangle; NumberOfPoints 7; }
          { GeoElement Line;     NumberOfPoints 4; }
        }
      }
    }
  }
}

// ==========================================
// 7. FORMULATION
// ==========================================
Formulation {
  { Name Magnetics_H; Type FemEquation;
    Quantity {
      { Name h; Type Local; NameOfSpace h_Space; }
    }

    Equation {
      // Inline execution block mapping nonlinear resistivity
      Galerkin {
        [ (1.0 / ( (1.0 / ((Ec / Jc) * (Norm[{d h}] / Jc + 1e-5)^(n - 1.0))) + (1.0 / rho_flow) )) * Dof{d h}, {d h} ];
        In HTS; Jacobian Vol; Integration Int;
      }
      
      // Air domain equation
      Galerkin {
        [ rho_air * Dof{d h}, {d h} ];
        In Air; Jacobian Vol; Integration Int;
      }

      // Magnetic Induction time derivative term
      Galerkin {
        DtDof [ mu[] * Dof{h} , {h} ];
        In Domain_Total; Jacobian Vol; Integration Int;
      }
      
      // Source Term injecting external field time derivative profile
      Galerkin {
        [ -1.0 * mu[] * dH_ext_dt[] , {h} ]; 
        In Domain_Total; Jacobian Vol; Integration Int;
      }
    }
  }
}

// ==========================================
// 8. RESOLUTION (STABILIZED FOR CRACK CORNERS)
// ==========================================
Resolution {
  { Name Analysis;
    System {
      { Name Sys; NameOfFormulation Magnetics_H; }
    }
    Operation {
      InitSolution[Sys];
      SaveSolution[Sys];

      // Lowered relaxation to 0.3 and bumped iterations to 150 to handle crack tip singularities
      TimeLoopTheta[0, 2.0 * Period, Period / 50.0, 0.55] {
        IterativeLoop[150, 1e-4, 0.3] { 
          Generate[Sys];    
          Solve[Sys]; 
        }
        SaveSolution[Sys];
        PostOperation[Map];
      }
    }
  }
}

// ==========================================
// 9. POST-PROCESSING 
// ==========================================
PostProcessing {
  { Name Magnetics_H; NameOfFormulation Magnetics_H;
    Quantity {
      { Name h;      Value { Local { [ {h} + H_ext_vec[] ];  In Domain_Total; Jacobian Vol; } } }
      { Name b;      Value { Local { [ mu[] * ({h} + H_ext_vec[]) ]; In Domain_Total; Jacobian Vol; } } }
      { Name normb;  Value { Local { [ Norm[mu[] * ({h} + H_ext_vec[])] ]; In Domain_Total; Jacobian Vol; } } }
      { Name j;      Value { Local { [ {d h} ];          In HTS; Jacobian Vol; } } }
      { Name normj;  Value { Local { [ Norm[{d h}] ];    In HTS; Jacobian Vol; } } }
      
      { Name PowerDensity; Value { Local { [ (1.0 / ( (1.0 / ((Ec / Jc) * (Norm[{d h}] / Jc + 1e-5)^(n - 1.0))) + (1.0 / rho_flow) )) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; } } }
      { Name Loss_HTS;     Value { Integral { [ (1.0 / ( (1.0 / ((Ec / Jc) * (Norm[{d h}] / Jc + 1e-5)^(n - 1.0))) + (1.0 / rho_flow) )) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; Integration Int; } } }
    }
  }
}

// ==========================================
// 10. POST-OPERATION (CLEAN & RECOVERED)
// ==========================================
PostOperation {
  { Name Map; NameOfPostProcessing Magnetics_H;
    Operation {
      // Default formatting completely avoids broken comma syntax errors
      Print[b,            OnElementsOf Domain_Total, File "b_crack.msh"];
      Print[normb,        OnElementsOf Domain_Total, File "normb_crack.msh"];
      Print[j,            OnElementsOf HTS,          File "j_crack.msh"];
      Print[normj,        OnElementsOf HTS,          File "normj_crack.msh"];
      Print[PowerDensity, OnElementsOf HTS,          File "power_crack.msh"];
      
      Print[Loss_HTS[HTS], OnGlobal,                 File "loss_vs_time_crack.gvl", Format Table];
    }
  }
}

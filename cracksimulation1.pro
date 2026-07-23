// ==========================================
// 1. GROUPS 
// ==========================================
Group {
  HTS = Region[{1}];          // 2D Tape Surface
  Air = Region[{2}];          // 2D Air Surface
  Air_Infinity = Region[{3}]; // 1D Outer Boundary Ring

  Domain_Total = Region[{HTS, Air}];
}

// ==========================================
// 2. GLOBAL PARAMETERS (Updated for 0.04mm Thickness)
// ==========================================
Function {
  mu0 = 4.0 * Pi * 1e-7;

  // CORRECT PHYSICS: Clean superconductor power law parameters
  Ec = 1e-4;
  Jc = 1.0e9;       // FIXED: Raised from 2.5e7 to 1.0e9 A/m^2 (Real REBCO scale)
  n  = 15.0;        // Keep at 15 for stability

  f = 50.0;
  Period = 1.0 / f;
  Bmax = 0.1;       // FIXED: Drop back to 0.1T temporarily until Jc stability is verified
  H_ext_amplitude = Bmax / mu0;

  rho_air = 1e-2;     
  rho_flow = 1e-3;    // FIXED: Slightly lower ceiling to catch the divergence early
}

// ==========================================
// 3. FUNCTION DEFINITIONS
// ==========================================
Function {
  mu[] = mu0;
  
  // Clean Source Formulation vector wave definition
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
// 7. FORMULATION (Robust Regularization for Crack Corners)
// ==========================================
Formulation {
  { Name Magnetics_H; Type FemEquation;
    Quantity {
      { Name h; Type Local; NameOfSpace h_Space; }
    }

    Equation {
      // REGULARIZED POWER LAW: Employs an parallel flux-flow ceiling (rho_flow).
      // This protects the crack corners where current density tries to go to infinity.
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
      
      // Source Term injecting the opposing derivative vector profile
      Galerkin {
        [ -1.0 * mu[] * dH_ext_dt[] , {h} ]; 
        In Domain_Total; Jacobian Vol; Integration Int;
      }
    }
  }
}

// ==========================================
// 8. RESOLUTION (Optimized Non-Linear Convergence Solver)
// ==========================================
Resolution {
  { Name Analysis;
    System {
      { Name Sys; NameOfFormulation Magnetics_H; }
    }
    Operation {
      InitSolution[Sys];
      SaveSolution[Sys];

      // CRUCIAL CHANGE: Time step reduced from Period/20 to Period/100 (100 steps per cycle)
      // This is absolutely mandatory so the Newton-Raphson solver can handle high n-values smoothly.
      TimeLoopTheta[0, 2.0 * Period, Period / 100.0, 0.5] {
        
        // RELAXATION APPLIED: Maximum iterations bumped to 100, relaxation set to 0.1 to 0.3.
        // This dampens the solver's adjustments so it doesn't overshoot into math bugs.
        IterativeLoop[100, 1e-4, 0.2] {
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
      { Name j;      Value { Local { [ {d h} ];          In Domain_Total; Jacobian Vol; } } }
      { Name normj;  Value { Local { [ Norm[{d h}] ];    In Domain_Total; Jacobian Vol; } } }
      
      // Exact calculation of localized power density & total integration loss
      { Name PowerDensity; Value { Local { [ (Ec / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; } } }
      { Name Loss_HTS;     Value { Integral { [ (Ec / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; Integration  Int; } } }
    }
  }
}

// ==========================================
// 10. POST-OPERATION (Cleaned Syntax)
// ==========================================
PostOperation {
  { Name Map; NameOfPostProcessing Magnetics_H;
    Operation {
      Print[b,            OnElementsOf Domain_Total, File "b_crack.msh"];
      Print[normb,        OnElementsOf Domain_Total, File "normb_crack.msh"];
      Print[j,            OnElementsOf HTS,          File "j_crack.msh"];
      Print[normj,        OnElementsOf HTS,          File "normj_crack.msh"];
      Print[PowerDensity, OnElementsOf HTS,          File "power_crack.msh"];
      
      Print[Loss_HTS[HTS], OnGlobal,                 File "loss_vs_time_crack.gvl", Format Table];
    }
  }
}

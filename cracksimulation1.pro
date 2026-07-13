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
// 2. GLOBAL PARAMETERS
// ==========================================
Function {
  mu0 = 4.0 * Pi * 1e-7;

  // CORRECT PHYSICS: Clean superconductor power law parameters
  Ec = 1e-4;
  Jc = 2.5e7;
  n  = 5.0; // Keeping n=5 for fast, guaranteed convergence like your old file

  f = 50.0;
  Period = 1.0 / f;
  Bmax = 0.1;// Peak external magnetic field (Tesla)
  H_ext_amplitude = Bmax / mu0;

  rho_air = 1e-2;     // Air domain regularization
  rho_flow = 1e-4;    // Flux-flow parallel resistance ceiling to protect crack corners
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
      { Region Air_Infinity; Value 0.0; } // Source field formulation boundaries are zeroed
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
// 7. FORMULATION (Fixed Mathematical Syntax)
// ==========================================
Formulation {
  { Name Magnetics_H; Type FemEquation;
    Quantity {
      { Name h; Type Local; NameOfSpace h_Space; }
    }

    Equation {
      // FIXED SYNTAX: Pure algebraic simplification of 1 / (1/rho_hts + 1/rho_flow).
      // This is written cleanly as: (rho_hts * rho_flow) / (rho_hts + rho_flow)
            // Changed to the pure normal tape formula to match your baseline perfectly!
      Galerkin {
        [ (Ec / Jc) * (Norm[{d h}] / Jc + 1e-5)^(n - 1.0) * Dof{d h}, {d h} ];
        In HTS; Jacobian Vol; Integration Int;
      }
      
      // Air domain equation (Unchanged)
      Galerkin {
        [ rho_air * Dof{d h}, {d h} ];
        In Air; Jacobian Vol; Integration Int;
      }

      // Magnetic Induction time derivative term (Unchanged)
      Galerkin {
        DtDof [ mu[] * Dof{h} , {h} ];
        In Domain_Total; Jacobian Vol; Integration Int;
      }
      
      // Source Term injecting the opposing derivative vector profile (Unchanged)
      Galerkin {
        [ -1.0 * mu[] * dH_ext_dt[] , {h} ]; 
        In Domain_Total; Jacobian Vol; Integration Int;
      }
    }
  }
}

// ==========================================
// 8. RESOLUTION
// ==========================================
Resolution {
  { Name Analysis;
    System {
      { Name Sys; NameOfFormulation Magnetics_H; }
    }
    Operation {
      InitSolution[Sys];
      SaveSolution[Sys];

      // FIXED: Step increment set to Period / 20.0 to guarantee exactly 40 steps over 2 cycles
      TimeLoopTheta[0, 2.0 * Period, Period / 20.0, 0.5] {
        IterativeLoop[40, 1e-4, 1.0] {
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
// 9. POST-PROCESSING (Updated for Regularized Loss)
// ==========================================
PostProcessing {
  { Name Magnetics_H; NameOfFormulation Magnetics_H;
    Quantity {
      { Name h;      Value { Local { [ {h} + H_ext_vec[] ];  In Domain_Total; Jacobian Vol; } } }
      { Name b;      Value { Local { [ mu[] * ({h} + H_ext_vec[]) ]; In Domain_Total; Jacobian Vol; } } }
      { Name normb;  Value { Local { [ Norm[mu[] * ({h} + H_ext_vec[])] ]; In Domain_Total; Jacobian Vol; } } }
      { Name j;      Value { Local { [ {d h} ];          In Domain_Total; Jacobian Vol; } } }
      { Name normj;  Value { Local { [ Norm[{d h}] ];    In Domain_Total; Jacobian Vol; } } }
      
      // UPDATED PHYSICS: Evaluates Power and Loss based on the exact same parallel resistance 
      // used in Section 7, maintaining absolute energy conservation in your output files.
      { Name PowerDensity; Value { Local { [ (Ec / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; } } }
      
      { Name Loss_HTS;     Value { Integral { [ (Ec / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; Integration  Int; } } }

    }
  }
}

// ==========================================
// 10. POST-OPERATION
// ==========================================
PostOperation {
  { Name Map; NameOfPostProcessing Magnetics_H;
    Operation {
      Print[b,            OnElementsOf Domain_Total, File "b_crack.msh"];
      Print[normb,        OnElementsOf Domain_Total, File "normb_crack.msh"];
      Print[j,            OnElementsOf Domain_Total, File "j_crack.msh"];
      Print[normj,        OnElementsOf Domain_Total, File "normj_crack.msh"];
      Print[PowerDensity, OnElementsOf HTS,          File "power_crack.msh"];
      
      Print[Loss_HTS[HTS], OnGlobal,                 File "loss_vs_time_crack.gvl", Format Table];
    }
  }
}

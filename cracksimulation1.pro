// Gmsh project created on Sun Jun 28 18:47:23 2026
// ==========================================
// 1. GROUPS (Direct Integer Arrays with Crack)
// ==========================================
Group {
  HTS_Left = Region[{1}];      // Matches Physical Surface("HTS_Left", 1)
  HTS_Right = Region[{4}];     // Matches Physical Surface("HTS_Right", 4)
  Air = Region[{2}];           // Matches Physical Surface("Air", 2) and the crack
  Air_Infinity = Region[{3}];  // Matches Physical Curve("Air_Infinity", 3)
  
  // Combine both superconducting pieces into one master physics group
  HTS = Region[{HTS_Left, HTS_Right}];
  
  Domain_Total = Region[{HTS, Air}];
  Domain_Magnetic = Region[{HTS, Air}];
}

// ==========================================
// 2. GLOBAL PARAMETERS
// ==========================================
mu0 = 4.0 * 3.141592653589793 * 1e-7;
E0 = 1e-4;         
Jc = 25000000.0;   // Critical current density (A/m^2)
n = 5.0;           // Exponent

f = 50.0;
Freq = f;
Period = 1.0 / Freq;
Bmax = 0.1;        // Peak external magnetic field (Tesla)

rho_air = 1e-2;     // Electrical resistivity of air and the crack

// ==========================================
// 3. FUNCTION DEFINITIONS
// ==========================================
Function {
  mu[] = mu0;
  H_ext_amplitude = Bmax / mu0;
  
  dH_ext_dt[] = Vector[0, H_ext_amplitude * 2.0 * 3.141592653589793 * Freq * Cos[2.0 * 3.141592653589793 * Freq * $Time], 0];
  H_ext_vec[] = Vector[0, H_ext_amplitude * Sin[2.0 * 3.141592653589793 * Freq * $Time], 0];
}

// ==========================================
// 4. CONSTRAINT
// ==========================================
Constraint {
  { Name MagneticField_External_Constraint;
    Type Assign;
    Case {
      { Region Air_Infinity; Value H_ext_amplitude * Sin[2.0 * 3.141592653589793 * Freq * $Time]; }
    }
  }
}

// ==========================================
// 5. FUNCTION SPACE (EDGE ELEMENTS)
// ==========================================
FunctionSpace {
  { Name h_Space; Type Form1;
    BasisFunction {
      { Name sn; NameOfCoef Coef_h; Function BF_Edge;
        Support Domain_Total; Entity EdgesOf[Domain_Total]; }
    }
    Constraint {
      { NameOfCoef Coef_h;
        // FIXED: Removed the invalid ActiveRegion syntax line entirely.
        // GetDP automatically resolves and assigns this boundary loop mapping.
        EntityType EdgesOf;
        NameOfConstraint MagneticField_External_Constraint;
      }
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
      // Superconductor power-law covers both HTS fragments simultaneously
      Galerkin {
        [ (E0 / Jc) * ((1.0 + Norm[{d h}]) / Jc)^(n - 1.0) * Dof{d h}, {d h} ];
        In HTS; Jacobian Vol; Integration Int;
      }
      
      // Air domain equation (covers ambient air and the high-resistance crack zone)
      Galerkin {
        [ rho_air * Dof{d h}, {d h} ];
        In Air; Jacobian Vol; Integration Int;
      }

      Galerkin {
        DtDof [ mu[] * Dof{h} , {h} ];
        In Domain_Total; Jacobian Vol; Integration Int;
      }
      
      // Background excitation input field driving force
      Galerkin {
        [ mu[] * dH_ext_dt[] , {h} ];
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

      TimeLoopTheta[0, 2.0 * Period, Period / 20.0, 0.5] {
        IterativeLoop[100, 1e-4, 1.0] {
          Generate[Sys];    
          GenerateJac[Sys]; 
          SolveJac[Sys];
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
      { Name h;      Value { Local { [ {h} + H_ext_vec[] ];  In Domain_Magnetic; Jacobian Vol; } } }
      { Name b;      Value { Local { [ mu[] * ({h} + H_ext_vec[]) ]; In Domain_Magnetic; Jacobian Vol; } } }
      { Name normb;  Value { Local { [ Norm[mu[] * ({h} + H_ext_vec[])] ]; In Domain_Magnetic; Jacobian Vol; } } }
      { Name j;      Value { Local { [ {d h} ];          In Domain_Magnetic; Jacobian Vol; } } }
      { Name normj;  Value { Local { [ Norm[{d h}] ];    In Domain_Magnetic; Jacobian Vol; } } }
      
      { Name PowerDensity; Value { Local { [ (E0 / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; } } }
      
      // Integrates losses over both the left and right fragments together
      { Name Loss_HTS;     Value { Integral { [ (E0 / Jc) * (Norm[{d h}] / Jc)^(n - 1.0) * SquNorm[{d h}] ]; In HTS; Jacobian Vol; Integration Int; } } }
    }
  }
}

// ==========================================
// 10. POST-OPERATION
// ==========================================
PostOperation {
  { Name Map; NameOfPostProcessing Magnetics_H;
    Operation {
      Print[b,            OnElementsOf Domain_Magnetic, File "b_crack.msh"];
      Print[normb,        OnElementsOf Domain_Magnetic, File "normb_crack.msh"];
      Print[j,            OnElementsOf Domain_Magnetic, File "j_crack.msh"];
      Print[normj,        OnElementsOf Domain_Magnetic, File "normj_crack.msh"];
      Print[PowerDensity, OnElementsOf HTS,             File "power_crack.msh"];
      
      // Saves the data to a distinct file name so it does not overwrite your normal data
      Print[Loss_HTS[HTS], OnGlobal,                    File "loss_vs_time_crack.gvl", Format Table];
    }
  }
}

// ===== Model B: Plan-view current conduction with a crack zone =====
// Center-crack condition (uses tape_topview.geo with crack_pos = L/2)

Group {
  SCbefore = Region[1];
  SCcrack  = Region[2];
  SCafter  = Region[3];
  SC       = Region[{SCbefore, SCcrack, SCafter}];
  Left     = Region[10];
  Right    = Region[11];
}

Function {
  Ec = 1e-4;                 // critical electric field criterion [V/m]
  n  = 15;                   // power-law exponent (matches your Table 1)
  Jc_normal = 2.5e7;         // critical current density, undamaged region [A/m^2]
  Jc_crack  = 0.05*Jc_normal;// degraded critical current density in the crack zone
                             // (edit this fraction to represent a more/less severe crack)

  Jc[SCbefore] = Jc_normal;
  Jc[SCafter]  = Jc_normal;
  Jc[SCcrack]  = Jc_crack;

  f = 50;                    // frequency [Hz]
  IFraction = 0.9;           // same operating point as your validated baseline
  W_tape = 4e-3;             // tape width [m]
  H_tape = 4e-5;             // effective sheet thickness [m] (same as your baseline)
  Imax = IFraction * Jc_normal * W_tape * H_tape;
  I[]  = Imax * Sin[2*Pi*f*$Time];

  // Nonlinear resistivity (E-J power law) and its inverse (conductivity)
  rho[]   = (Ec/Jc[$1]) * (Norm[$2]/Jc[$1] + 1e-8)^(n-1);
  sigma[] = 1.0 / (rho[$1,$2] + 1e-14);
}

FunctionSpace {
  { Name Vspace; Type Form0;
    BasisFunction {
      { Name sn; NameOfCoef vn; Function BF_Node; Support SC; Entity NodesOf[SC]; }
    }
    GlobalQuantity {
      { Name I; Type AliasOf;        NameOfCoef Ii; }
      { Name V; Type AssociatedWith; NameOfCoef Ii; }
    }
    Constraint {
      { NameOfCoef vn; EntityType NodesOf;       NameOfConstraint Ground; }
      { NameOfCoef I;  EntityType GroupsOfNodesOf; NameOfConstraint ImposedCurrent; }
    }
  }
}

Constraint {
  { Name Ground;
    Case { { Region Right; Value 0; } }
  }
  { Name ImposedCurrent;
    Case { { Region Left; Value 1; TimeFunction I[]; } }
  }
}

Jacobian { { Name Vol; Case { { Region SC; Jacobian Vol; } } } }
Integration {
  { Name Int; Case { { Type Gauss;
      Case { { GeoElement Triangle; NumberOfPoints 7; }
             { GeoElement Line;     NumberOfPoints 4; } } } }
  }
}

Formulation {
  { Name CurrentConduction; Type FemEquation;
    Quantity {
      { Name v; Type Local;  NameOfSpace Vspace; }
      { Name I; Type Global; NameOfSpace Vspace [I]; }
      { Name U; Type Global; NameOfSpace Vspace [V]; }
    }
    Equation {
      Galerkin { [ sigma[Jc[], {d v}] * Dof{d v} , {d v} ];
                 In SC; Jacobian Vol; Integration Int; }
      GlobalTerm { [ Dof{I} , {U} ]; In Left; }
    }
  }
}

Resolution {
  { Name Analysis;
    System { { Name Sys; NameOfFormulation CurrentConduction; } }
    Operation {
      InitSolution[Sys]; SaveSolution[Sys];
      TimeLoopTheta[0, 2.0/f, (1/f)/60, 0.55] {
        IterativeLoop[40, 1e-4, 0.5] { Generate[Sys]; Solve[Sys]; }
        SaveSolution[Sys];
        PostOperation[MapTop];
      }
    }
  }
}

PostProcessing {
  { Name CurrentConduction; NameOfFormulation CurrentConduction;
    Quantity {
      { Name v;    Value{ Local{ [ {v} ]; In SC; Jacobian Vol; } } }
      { Name j;    Value{ Local{ [ -sigma[Jc[], {d v}] * {d v} ]; In SC; Jacobian Vol; } } }
      { Name normj;Value{ Local{ [ Norm[ -sigma[Jc[], {d v}] * {d v} ] ]; In SC; Jacobian Vol; } } }
      { Name Itot; Value{ Global{ [ {I} ]; In Left; } } }
    }
  }
}

PostOperation {
  { Name MapTop; NameOfPostProcessing CurrentConduction;
    Operation {
      Print[ j,     OnElementsOf SC, File "res_topview/j.pos",     Name "j [A/m2]" ];
      Print[ normj, OnElementsOf SC, File "res_topview/normj.pos", Name "|j| [A/m2]" ];
      Print[ Itot,  OnRegion Left, Format Table, File "res_topview/current_check.txt" ];
    }
  }
}

Function {
    mu0 = Pi*4e-7; // [H/m]
    nu0 = 1.0/mu0; // [m/H]

    DefineConstant[ec, jc, n];           // normal superconductor
    DefineConstant[jc_crack, n_crack];   // crack region
    DefineConstant[mur0, m0];
    DefineConstant[Delta];

    // Missing constants for the power-law sigma model
    epsSigma  = 1e-8;   // Importance of the linear part for a-formulation [-]
    epsSigma2 = 1e-15;  // To prevent division by 0 in sigma [-]

       // ... (ferro and copper parts unchanged) ...

    // ------- Superconductor (normal region) -------
    If(Flag_jcb == 1)
        jcb_norm[] = jc / (1 + Norm[$1]/b0);
    Else
        jcb_norm[] = jc;
    EndIf

    If(Flag_nb == 1)
        nb_norm[] = n1 + (n0-n1)/(1 + Norm[$1]/b0);
    Else
        nb_norm[] = n;
    EndIf

    rho_power_norm[] = ec / jcb_norm[$2] *
        (Min[($TimeStep<-1)?1.5*jcb_norm[$2]:1e99, Norm[$1]]/jcb_norm[$2])^(nb_norm[$2] - 1);

    dedj_power_norm[] = (1.0/$relaxFactor) *
      (ec / jcb_norm[$2] *
         (Min[($TimeStep<-1)?1.5*jcb_norm[$2]:1e99, Norm[$1]]/jcb_norm[$2])^(nb_norm[$2]#7 - 1) * TensorDiag[1, 1, 1] +
       ec / jcb_norm[$2]^3 * (#7 - 1) *
         (Min[($TimeStep<-1)?1.5*jcb_norm[$2]:1e99, Norm[$1]]/jcb_norm[$2])^(#7 - 3) * SquDyadicProduct[$1]);

    sigma_power_norm[] = jcb_norm[$2] / ec * 1.0 /
        ( epsSigma + ( Norm[$1]/ec )^((nb_norm[$2]-1.0)/nb_norm[$2]) );

    djde_power_norm[] = ($iter > -1) ? ((1.0/$relaxFactor) *
        ( jcb_norm[$2] / ec *
          (1.0 / (epsSigma + ( (Norm[$1]/ec)#3 )^((nb_norm[$2]#7-1.0)/#7) ))#4 * TensorDiag[1, 1, 1]
        + jcb_norm[$2]/ec^3 * (1.0-#7)/#7 *
          (#4)^(2) * 1/((#3)^((#7+1.0)/#7) + epsSigma2 ) * SquDyadicProduct[$1]))
        : (jcb_norm[$2] / ec * 1.0 /
          ( epsSigma + ( Norm[$1]/ec )^((nb_norm[$2]#7-1.0)/#7) ) * TensorDiag[1, 1, 1] );

    // ------- Superconductor (crack / weak region) -------
    If(Flag_jcb == 1)
        jcb_crk[] = jc_crack / (1 + Norm[$1]/b0);
    Else
        jcb_crk[] = jc_crack;
    EndIf

    If(Flag_nb == 1)
        nb_crk[] = n1 + (n0-n1)/(1 + Norm[$1]/b0);
    Else
        nb_crk[] = n_crack;
    EndIf

    rho_power_crk[] = ec / jcb_crk[$2] *
        (Min[($TimeStep<-1)?1.5*jcb_crk[$2]:1e99, Norm[$1]]/jcb_crk[$2])^(nb_crk[$2] - 1);

    dedj_power_crk[] = (1.0/$relaxFactor) *
      (ec / jcb_crk[$2] *
         (Min[($TimeStep<-1)?1.5*jcb_crk[$2]:1e99, Norm[$1]]/jcb_crk[$2])^(nb_crk[$2]#7 - 1) * TensorDiag[1, 1, 1] +
       ec / jcb_crk[$2]^3 * (#7 - 1) *
         (Min[($TimeStep<-1)?1.5*jcb_crk[$2]:1e99, Norm[$1]]/jcb_crk[$2])^(#7 - 3) * SquDyadicProduct[$1]);

    sigma_power_crk[] = jcb_crk[$2] / ec * 1.0 /
        ( epsSigma + ( Norm[$1]/ec )^((nb_crk[$2]-1.0)/nb_crk[$2]) );

    djde_power_crk[] = ($iter > -1) ? ((1.0/$relaxFactor) *
        ( jcb_crk[$2] / ec *
          (1.0 / (epsSigma + ( (Norm[$1]/ec)#3 )^((nb_crk[$2]#7-1.0)/#7) ))#4 * TensorDiag[1, 1, 1]
        + jcb_crk[$2]/ec^3 * (1.0-#7)/#7 *
          (#4)^(2) * 1/((#3)^((#7+1.0)/#7) + epsSigma2 ) * SquDyadicProduct[$1]))
        : (jcb_crk[$2] / ec * 1.0 /
          ( epsSigma + ( Norm[$1]/ec )^((nb_crk[$2]#7-1.0)/#7) ) * TensorDiag[1, 1, 1] );

    // ------- Copper constitutive law -------
    sigma_copper[] = 58e6; // [S/m]
    rho_copper[] = 1./sigma_copper[]; //1e-2*1.81e-10;//

    // ------- Using built-in functions for the power-law model -------
    // rho_power_built_in[] = RhoPowerLaw[Norm[$1], jcb[$2], nb[$2]]{ec};
   // drhodj_timesj_power_built_in[] = DRhoDJTimesJPowerLaw[$1, jcb[$2], nb[$2]]{ec};
  // dedj_power_built_in[] = DEDJPowerLaw[$1, jcb[$2], nb[$2]]{ec};
}

// Predefined regions
Function{
    Flag_LinearProblem = (IsThereSuper == 1 || IsThereFerro == 1) ? 0 : 1;

    // ------- Air Properties -------
    mu[Air] = mu0;
    nu[Air] = nu0;

    // ------- Copper Properties -------
    rho[Copper] = rho_copper[];
    sigma[Copper] = sigma_copper[];
    mu[Copper] = mu0;
    nu[Copper] = nu0;

    // ------- Normal Superconductor Bulk Properties -------
    If(IsThereSuper)
        rho[Super]   = rho_power_norm[$1,$2];
        dedj[Super]  = dedj_power_norm[$1,$2];
        sigma[Super] = sigma_power_norm[$1,$2];
        djde[Super]  = djde_power_norm[$1,$2];
        mu[Super]    = mu0;
        nu[Super]    = nu0;
    EndIf

    // ------- Thin-Shell Crack / Weak Surface Properties -------
    // We apply the crack constitutive laws directly to GammaS (SHELL_UP/DOWN)
    If(formulation == h_phi_ts_formulation)
        rho[GammaS]   = rho_power_crk[$1,$2];
        dedj[GammaS]  = dedj_power_crk[$1,$2];
        sigma[GammaS] = sigma_power_crk[$1,$2];
        djde[GammaS]  = djde_power_crk[$1,$2];
        mu[GammaS]    = mu0;
        nu[GammaS]    = nu0;
    EndIf

    // ------- Ferromagnetic Properties -------
    If(IsThereFerro)
        mu[Ferro]   = mu_anhyModel[$1];
        dbdh[Ferro] = dbdh_anhyModel[$1];
        nu[Ferro]   = nu_anhyModel[$1];
        dhdb[Ferro] = dhdb_anhyModel[$1];
    EndIf
}

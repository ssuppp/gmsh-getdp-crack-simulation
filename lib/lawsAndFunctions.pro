Function {
    mu0 = Pi*4e-7; // [H/m]
    nu0 = 1.0/mu0; // [m/H]

    dbdh_anhyModel[] = TensorDiag[mu0, mu0, mu0];
    nu_anhyModel[]   = nu0;
    dhdb_anhyModel[] = TensorDiag[nu0, nu0, nu0];
    
    DefineConstant[ec, jc, n];           // normal superconductor
    DefineConstant[jc_crack, n_crack];   // crack region
    DefineConstant[mur0, m0];
    DefineConstant[Delta];

    // Missing constants for the power-law sigma model
    epsSigma  = 1e-8;   // Importance of the linear part for a-formulation [-]
    epsSigma2 = 1e-15;  // To prevent division by 0 in sigma [-]

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
    
    // ======= ALIASES FOR THE H-PHI THIN-SHELL FORMULATION =======
    rho_powerTS[]   = rho_power_crk[$1,$2];
    dedj_powerTS[]  = dedj_power_crk[$1,$2];
    sigma_powerTS[] = sigma_power_crk[$1,$2];
    djde_powerTS[]  = djde_power_crk[$1,$2];
    sigmae[]        = sigma_power_norm[$1,$2]; 
    // ============================================================
}

// Predefined regions
Function {

}

// Predefined regions
Function {
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
        
        // ======= ADDED: Crack Superconductor Bulk Properties =======
        rho[CrackSuper]   = rho_power_crk[$1,$2];
        dedj[CrackSuper]  = dedj_power_crk[$1,$2];
        sigma[CrackSuper] = sigma_power_crk[$1,$2];
        djde[CrackSuper]  = djde_power_crk[$1,$2];
        mu[CrackSuper]    = mu0;
        nu[CrackSuper]    = nu0;
    EndIf

    // ------- Thin-Shell Crack / Weak Surface Properties -------
    If(formulation == h_phi_ts_formulation)
        rho[GammaS]   = rho_power_crk[$1,$2];
        dedj[GammaS]  = dedj_power_crk[$1,$2];
        sigma[GammaS] = sigma_power_crk[$1,$2];
        djde[GammaS]  = djde_power_crk[$1,$2];
        mu[GammaS]    = mu0;
        nu[GammaS]    = nu0;
    EndIf

    // ------- Ferromagnetic Properties -------
    mu[Ferro]   = mu0;
    dbdh[Ferro] = TensorDiag[mu0, mu0, mu0]; 
    nu[Ferro]   = nu0;
    dhdb[Ferro] = TensorDiag[nu0, nu0, nu0];
}

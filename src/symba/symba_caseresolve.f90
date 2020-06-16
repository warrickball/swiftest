!**********************************************************************************************************************************
!
!  Unit Name   : symba_caseresolve
!  Unit Type   : subroutine
!  Project     : Swiftest
!  Package     : symba
!  Language    : Fortran 90/95
!
!  Description : Merge massive bodies
!
!  Input
!    Arguments : t            : time
!                npl          : number of massive bodies
!                nsppl        : number of spilled massive bodies
!                symba_pl1P   : pointer to head of SyMBA massive body structure linked-list
!                symba_pld1P  : pointer to head of discard SyMBA massive body structure linked-list
!                nplplenc     : number of massive body-massive body encounters
!                plplenc_list : array of massive body-massive body encounter structures
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : npl          : number of massive bodies
!                nsppl        : number of spilled massive bodies
!                symba_pl1P   : pointer to head of SyMBA massive body structure linked-list
!                symba_pld1P  : pointer to head of discard SyMBA massive body structure linked-list
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL symba_caseresolve(t, npl, nsppl, symba_pl1P, symba_pld1P, nplplenc, plplenc_list)
!
!  Notes       : Adapted from Hal Levison's Swift routine discard_mass_merge.f
!
!**********************************************************************************************************************************
SUBROUTINE symba_caseresolve (t, dt, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, eoffset, vbs, & 
     npl, symba_plA, nplplenc, plplenc_list, regime, nplmax, ntpmax, fragmax, mres, rres, array_index1_child, array_index2_child, &
     m1, m2, rad1, rad2, x1, x2, v1, v2)

! Modules
     use swiftest, EXCEPT_THIS_ONE => symba_caseresolve
     IMPLICIT NONE

! Arguments
     INTEGER(I4B), INTENT(IN)                         :: index_enc, nplmax, ntpmax
     INTEGER(I4B), INTENT(INOUT)                      :: npl, nmergeadd, nmergesub, nplplenc, fragmax
     REAL(DP), INTENT(IN)                             :: t, dt
     REAL(DP), INTENT(INOUT)                          :: eoffset, m1, m2, rad1, rad2
     REAL(DP), DIMENSION(:), INTENT(INOUT)            :: mres, rres
     REAL(DP), DIMENSION(:), INTENT(IN)            :: vbs
     REAL(DP), DIMENSION(:), INTENT(INOUT)         :: x1, x2, v1, v2
     TYPE(symba_plplenc), INTENT(INOUT)               :: plplenc_list
     TYPE(symba_merger), INTENT(INOUT)                :: mergeadd_list, mergesub_list
     TYPE(symba_pl), INTENT(INOUT)                    :: symba_plA
     INTEGER(I4B), INTENT(IN)                         :: regime
     INTEGER(I4B), DIMENSION(npl), INTENT(INOUT)      :: array_index1_child, array_index2_child

! Internals

! Executable code

          SELECT CASE (regime)

          CASE (COLLRESOLVE_REGIME_DISRUPTION)
               CALL symba_casedisruption (t, dt, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, eoffset, vbs, & 
               symba_plA, nplplenc, plplenc_list, nplmax, ntpmax, fragmax, mres, rres, m1, m2, rad1, rad2, x1, x2, v1, v2)

          CASE (COLLRESOLVE_REGIME_SUPERCATASTROPHIC)
               CALL symba_casesupercatastrophic (t, dt, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, &
               eoffset, vbs, symba_plA, nplplenc, &
               plplenc_list, nplmax, ntpmax, fragmax, mres, rres, m1, m2, rad1, &
               rad2, x1, x2, v1, v2)

          CASE (COLLRESOLVE_REGIME_GRAZE_AND_MERGE)
               CALL symba_casemerge (t, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, eoffset, vbs, & 
               npl, symba_plA, nplplenc, plplenc_list, array_index1_child, array_index2_child, m1, m2, rad1, rad2, x1, &
               x2, v1, v2)

          CASE (COLLRESOLVE_REGIME_HIT_AND_RUN)
               CALL symba_casehitandrun (t, dt, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, eoffset, vbs, & 
               symba_plA, nplplenc, plplenc_list, &
               nplmax, ntpmax, fragmax, mres, rres, m1, m2, rad1, rad2, x1, x2, v1, v2)

          CASE (COLLRESOLVE_REGIME_MERGE)
               CALL symba_casemerge (t, index_enc, nmergeadd, nmergesub, mergeadd_list, mergesub_list, eoffset, vbs, & 
               npl, symba_plA, nplplenc, plplenc_list, array_index1_child, array_index2_child, m1, m2, rad1, rad2, x1, &
               x2, v1, v2)
          
          CASE DEFAULT 
               WRITE(*,*) "ERROR IN SYMBA_CASERESOLVE, NO REGIME SELECTED"
          END SELECT


RETURN
END SUBROUTINE symba_caseresolve

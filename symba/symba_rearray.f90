!**********************************************************************************************************************************
!
!  Unit Name   : symba_rearray
!  Unit Type   : subroutine
!  Project     : Swiftest
!  Package     : symba
!  Language    : Fortran 90/95
!
!  Description : Redo array of pl and tp based on discarded and added pl and tp
!
!  Input
!    Arguments : t           : time
!                npl         : number of planets
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : npl         : number of planets
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL symba_discard_pl(t, npl, nplmax, nsp, symba_pl1P, symba_pld1P, rmin, rmax, rmaxu, qmin, qmin_coord,
!                                      qmin_alo, qmin_ahi, j2rp2, j4rp4, eoffset)
!
!  Notes       : Adapted from Hal Levison's Swift routine discard_massive5.f
!
!**********************************************************************************************************************************
SUBROUTINE symba_rearray(t, npl, ntp, nsppl, nsptp, symba_plA, symba_tpA, nmergeadd, mergeadd_list, discard_plA, &
    discard_tpA, discard_plA_id_status,discard_tpA_id_status, NPLMAX, j2rp2, j4rp4)

! Modules
     USE module_parameters
     USE module_swiftestalloc 
     USE module_swiftest
     USE module_helio
     USE module_symba
     USE module_interfaces, EXCEPT_THIS_ONE => symba_rearray
     IMPLICIT NONE

! Arguments
     INTEGER(I4B), INTENT(INOUT)                      :: npl, ntp, nsppl, nsptp, nmergeadd, NPLMAX !change to fragadd
     REAL(DP), INTENT(IN)                             :: t, j2rp2, j4rp4
     TYPE(symba_pl), INTENT(INOUT)                    :: symba_plA
     TYPE(symba_tp), INTENT(INOUT)                    :: symba_tpA
     TYPE(symba_merger), INTENT(INOUT)                 :: mergeadd_list !change to fragadd_list
     REAL(DP), DIMENSION(11,npl), INTENT(OUT)          :: discard_plA
     REAL(DP), DIMENSION(8,ntp), INTENT(OUT)         :: discard_tpA
     INTEGER(I4B), DIMENSION(2,npl), INTENT(OUT)    :: discard_plA_id_status
     INTEGER(I4B), DIMENSION(2,ntp), INTENT(OUT)     :: discard_tpA_id_status

! Internals
     INTEGER(I4B)                                   :: i, index, j, ncomp, ierr, nplm, nkpl, nktp, k
     REAL(DP)                                       :: ke, pe, tei, tef
     REAL(DP), DIMENSION(NDIM)                      :: htot
     REAL(DP), DIMENSION(12,NPLMAX)                 :: keep_plA
     REAL(DP), DIMENSION(11,ntp)                    :: keep_tpA
     INTEGER(I4B), DIMENSION(2,NPLMAX)              :: keep_plA_id_status
     INTEGER(I4B), DIMENSION(2,ntp)                 :: keep_tpA_id_status                    

! Executable code

    IF (ldiscard .eqv. .TRUE.) THEN 
        nsppl = 0
        nkpl = 0
        DO i = 1, npl 
            IF (symba_plA%helio%swiftest%status(i) /= ACTIVE) THEN !do we ever mark the keep particle as ACTIVE or do we mark both as =/ACTIVE
                nsppl = nsppl+1
                discard_plA_id_status(1,nsppl) = symba_plA%helio%swiftest%name(i)
                discard_plA_id_status(2,nsppl) = symba_plA%helio%swiftest%status(i)
                discard_plA(1,nsppl) = symba_plA%helio%swiftest%mass(i)
                discard_plA(2,nsppl) = symba_plA%helio%swiftest%radius(i)
                discard_plA(3,nsppl) = symba_plA%helio%swiftest%xh(1,i)
                discard_plA(4,nsppl) = symba_plA%helio%swiftest%xh(2,i)
                discard_plA(5,nsppl) = symba_plA%helio%swiftest%xh(3,i)
                discard_plA(6,nsppl) = symba_plA%helio%swiftest%vh(1,i)
                discard_plA(7,nsppl) = symba_plA%helio%swiftest%vh(2,i)
                discard_plA(8,nsppl) = symba_plA%helio%swiftest%vh(3,i)
                discard_plA(9,nsppl) = symba_plA%helio%ah(1,i)
                discard_plA(10,nsppl) = symba_plA%helio%ah(2,i)
                discard_plA(11,nsppl) = symba_plA%helio%ah(3,i)
                
            ELSE
                nkpl = nkpl + 1                                   ! both keep_plA and discard_plA will have the same x-coords during a merger
                keep_plA_id_status(1,nkpl) = symba_plA%helio%swiftest%name(i)
                keep_plA_id_status(2,nkpl) = symba_plA%helio%swiftest%status(i)
                keep_plA(1,nkpl) = symba_plA%helio%swiftest%mass(i)
                keep_plA(2,nkpl) = symba_plA%helio%swiftest%radius(i)
                keep_plA(3,nkpl) = symba_plA%helio%swiftest%xh(1,i)
                keep_plA(4,nkpl) = symba_plA%helio%swiftest%xh(2,i)
                keep_plA(5,nkpl) = symba_plA%helio%swiftest%xh(3,i)
                keep_plA(6,nkpl) = symba_plA%helio%swiftest%vh(1,i)
                keep_plA(7,nkpl) = symba_plA%helio%swiftest%vh(2,i)
                keep_plA(8,nkpl) = symba_plA%helio%swiftest%vh(3,i)
                keep_plA(9,nkpl) = symba_plA%helio%ah(1,i)
                keep_plA(10,nkpl) = symba_plA%helio%ah(2,i)
                keep_plA(11,nkpl) = symba_plA%helio%ah(3,i)
                keep_plA(12,nkpl) = symba_plA%helio%swiftest%rhill(i)

            END IF 
        END DO

        npl = nkpl

        ! remove all mentions of mergeadd and mergeadd_list from this loop after fragmentation 
        IF (nmergeadd == 0) THEN !this will change to nfragadd when fragmentation is implemented 
            CALL symba_pl_deallocate(symba_plA)
            CALL symba_pl_allocate(symba_plA, nkpl)
            DO k = 1, nkpl
                symba_plA%helio%swiftest%name(k) = keep_plA_id_status(1,k)
                symba_plA%helio%swiftest%status(k) = keep_plA_id_status(2,k)
                symba_plA%helio%swiftest%mass(k) = keep_plA(1,k)
                symba_plA%helio%swiftest%radius(k) = keep_plA(2,k)
                symba_plA%helio%swiftest%xh(1,k) = keep_plA(3,k)
                symba_plA%helio%swiftest%xh(2,k) = keep_plA(4,k)
                symba_plA%helio%swiftest%xh(3,k) = keep_plA(5,k)
                symba_plA%helio%swiftest%vh(1,k) = keep_plA(6,k)
                symba_plA%helio%swiftest%vh(2,k) = keep_plA(7,k)
                symba_plA%helio%swiftest%vh(3,k) = keep_plA(8,k)
                symba_plA%helio%ah(1,k) = keep_plA(9,k)
                symba_plA%helio%ah(2,k) = keep_plA(10,k)
                symba_plA%helio%ah(3,k) = keep_plA(11,k)
                symba_plA%helio%swiftest%rhill(k) = keep_plA(12,k)
            END DO
        ELSE 
            CALL symba_pl_deallocate(symba_plA)
            CALL symba_pl_allocate(symba_plA, nkpl)
            DO k = 1, nkpl
                symba_plA%helio%swiftest%name(k) = keep_plA_id_status(1,k)
                symba_plA%helio%swiftest%status(k) = keep_plA_id_status(2,k)
                symba_plA%helio%swiftest%mass(k) = keep_plA(1,k)
                symba_plA%helio%swiftest%radius(k) = keep_plA(2,k)
                symba_plA%helio%swiftest%xh(1,k) = keep_plA(3,k)
                symba_plA%helio%swiftest%xh(2,k) = keep_plA(4,k)
                symba_plA%helio%swiftest%xh(3,k) = keep_plA(5,k)
                symba_plA%helio%swiftest%vh(1,k) = keep_plA(6,k)
                symba_plA%helio%swiftest%vh(2,k) = keep_plA(7,k)
                symba_plA%helio%swiftest%vh(3,k) = keep_plA(8,k)
                symba_plA%helio%ah(1,k) = keep_plA(9,k)
                symba_plA%helio%ah(2,k) = keep_plA(10,k)
                symba_plA%helio%ah(3,k) = keep_plA(11,k)
                symba_plA%helio%swiftest%rhill(k) = keep_plA(12,k)
            END DO
        END IF
    END IF 

    IF (ldiscard_tp .eqv. .TRUE.) THEN 
        nktp = 0
        nsptp = 0  
        DO i = 1, ntp
            IF (symba_tpA%helio%swiftest%status(i) /= ACTIVE) THEN 
                nsptp = nsptp+1
                discard_tpA_id_status(1,nsptp) = symba_tpA%helio%swiftest%name(i)
                discard_tpA_id_status(2,nsptp) = symba_tpA%helio%swiftest%status(i)
                discard_tpA(1,nsptp) = 0.0_DP
                discard_tpA(2,nsptp) = 0.0_DP
                discard_tpA(3,nsptp) = symba_tpA%helio%swiftest%xh(1,i)
                discard_tpA(4,nsptp) = symba_tpA%helio%swiftest%xh(2,i)
                discard_tpA(5,nsptp) = symba_tpA%helio%swiftest%xh(3,i)
                discard_tpA(6,nsptp) = symba_tpA%helio%swiftest%vh(1,i)
                discard_tpA(7,nsptp) = symba_tpA%helio%swiftest%vh(2,i)
                discard_tpA(8,nsptp) = symba_tpA%helio%swiftest%vh(3,i)
                
            ELSE 
                nktp = nktp+1
                keep_tpA_id_status(1,nktp) = symba_tpA%helio%swiftest%name(i)
                keep_tpA_id_status(2,nktp) = symba_tpA%helio%swiftest%status(i)
                keep_tpA(1,nktp) = 0.0_DP
                keep_tpA(2,nktp) = 0.0_DP
                keep_tpA(3,nktp) = symba_tpA%helio%swiftest%xh(1,i)
                keep_tpA(4,nktp) = symba_tpA%helio%swiftest%xh(2,i)
                keep_tpA(5,nktp) = symba_tpA%helio%swiftest%xh(3,i)
                keep_tpA(6,nktp) = symba_tpA%helio%swiftest%vh(1,i)
                keep_tpA(7,nktp) = symba_tpA%helio%swiftest%vh(2,i)
                keep_tpA(8,nktp) = symba_tpA%helio%swiftest%vh(3,i)
                keep_tpA(9,nktp) = symba_tpA%helio%ah(1,i)
                keep_tpA(10,nktp) = symba_tpA%helio%ah(2,i)
                keep_tpA(11,nktp) = symba_tpA%helio%ah(3,i)

            END IF 
        END DO 

        ntp = nktp

        CALL symba_tp_deallocate(symba_tpA)
        CALL symba_tp_allocate(symba_tpA, nktp)

        symba_tpA%helio%swiftest%name(1:nktp) = keep_tpA_id_status(1,:)
        symba_tpA%helio%swiftest%name(2:nktp) = keep_tpA_id_status(2,:)
        symba_tpA%helio%swiftest%xh(1,1:nktp) = keep_tpA(3,:)
        symba_tpA%helio%swiftest%xh(2,1:nktp) = keep_tpA(4,:)
        symba_tpA%helio%swiftest%xh(3,1:nktp) = keep_tpA(5,:)
        symba_tpA%helio%swiftest%vh(1,1:nktp) = keep_tpA(6,:)
        symba_tpA%helio%swiftest%vh(2,1:nktp) = keep_tpA(7,:)
        symba_tpA%helio%swiftest%vh(3,1:nktp) = keep_tpA(8,:)
        symba_tpA%helio%ah(1,1:nktp) = keep_tpA(9,:)
        symba_tpA%helio%ah(2,1:nktp) = keep_tpA(10,:)
        symba_tpA%helio%ah(3,1:nktp) = keep_tpA(11,:)

    END IF 


END SUBROUTINE symba_rearray


    



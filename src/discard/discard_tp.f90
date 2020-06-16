!**********************************************************************************************************************************
!
!  Unit Name   : discard
!  Unit Type   : subroutine
!  Project     : Swiftest
!  Package     : discard
!  Language    : Fortran 90/95
!
!  Description : Check to see if test particles should be discarded based on their positions or because they are unbound from
!                the system
!
!  Input
!    Arguments : t              : time
!                dt             : time step
!                npl            : number of massive bodies
!                ntp            : number of test particles
!                swifter_pl1P   : pointer to head of Swifter massive body structure linked-list
!                swifter_tp1P   : pointer to head of active Swifter test particle structure linked-list
!                rmin           : minimum heliocentric radius for test particle
!                rmax           : maximum heliocentric radius for test particle
!                rmaxu          : maximum unbound heliocentric radius for test particle
!                qmin           : minimum pericenter distance for test particle
!                qmin_alo       : minimum semimajor axis for qmin
!                qmin_ahi       : maximum semimajor axis for qmin
!                qmin_coord     : coordinate frame to use for qmin
!                lclose         : logical flag indicating whether to check for massive body-test particle encounters
!                lrhill_present : logical flag indicating whether Hill sphere radii for massive bodies are present
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : swifter_tp1P   : pointer to head of active Swifter test particle structure linked-list
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL discard_tpt, dt, npl, ntp, swifter_pl1P, swifter_tp1P, rmin, rmax, rmaxu, qmin, qmin_alo, qmin_ahi,
!                             qmin_coord, lclose, lrhill_present)
!
!  Notes       : Adapted from Hal Levison's Swift routine discard.f
!
!**********************************************************************************************************************************
SUBROUTINE discard_tp(t, dt, npl, ntp, swiftest_plA, swiftest_tpA, rmin, rmax, rmaxu, &
     qmin, qmin_alo, qmin_ahi, qmin_coord, lclose,  &
     lrhill_present)

! Modules
     USE swiftest, EXCEPT_THIS_ONE => discard_tp
     IMPLICIT NONE

! Arguments
     LOGICAL(LGT), INTENT(IN)  :: lclose, lrhill_present
     INTEGER(I4B), INTENT(IN)  :: npl, ntp
     REAL(DP), INTENT(IN)      :: t, dt, rmin, rmax, rmaxu, qmin, qmin_alo, qmin_ahi
     CHARACTER(*), INTENT(IN)  :: qmin_coord
     TYPE(swiftest_pl), INTENT(INOUT) :: swiftest_plA
     TYPE(swiftest_tp), INTENT(INOUT) :: swiftest_tpA

! Internals
     REAL(DP) :: msys

! Executable code
     IF ((rmin >= 0.0_DP) .OR. (rmax >= 0.0_DP) .OR. (rmaxu >= 0.0_DP) .OR. ((qmin >= 0.0_DP) .AND. (qmin_coord == "BARY"))) THEN
          CALL coord_h2b(npl, swiftest_plA, msys)
          CALL coord_h2b_tp(ntp, swiftest_tpA, swiftest_plA)
     END IF
     IF ((rmin >= 0.0_DP) .OR. (rmax >= 0.0_DP) .OR. (rmaxu >= 0.0_DP)) CALL discard_sun(t, ntp, msys, swiftest_tpA, rmin, rmax,  &
          rmaxu)
     IF (qmin >= 0.0_DP) CALL discard_peri(t, npl, ntp, swiftest_plA, swiftest_tpA, msys, qmin, qmin_alo, qmin_ahi, qmin_coord,   &
          lrhill_present)
     IF (lclose) CALL discard_pl(t, dt, npl, ntp, swiftest_plA, swiftest_tpA)

     RETURN

END SUBROUTINE discard_tp
!**********************************************************************************************************************************
!
!  Author(s)   : David E. Kaufmann
!
!  Revision Control System (RCS) Information
!
!  Source File : $RCSfile$
!  Full Path   : $Source$
!  Revision    : $Revision$
!  Date        : $Date$
!  Programmer  : $Author$
!  Locked By   : $Locker$
!  State       : $State$
!
!  Modification History:
!
!  $Log$
!**********************************************************************************************************************************

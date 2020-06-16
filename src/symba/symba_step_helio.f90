!**********************************************************************************************************************************
!
!  Unit Name   : symba_step_helio
!  Unit Type   : subroutine
!  Project     : Swiftest
!  Package     : symba
!  Language    : Fortran 90/95
!
!  Description : Step massive bodies and test particles ahead in democratic heliocentric coordinates
!
!  Input
!    Arguments : lfirst       : logical flag indicating whether current invocation is the first
!                lextra_force : logical flag indicating whether to include user-supplied accelerations
!                t            : time
!                npl          : number of massive bodies
!                nplm         : number of massive bodies with mass > mtiny
!                nplmax       : maximum allowed number of massive bodies
!                ntp          : number of active test particles
!                ntpmax       : maximum allowed number of test particles
!                helio_pl1P   : pointer to head of helio massive body structure linked-list
!                helio_tp1P   : pointer to head of helio test particle structure linked-list
!                j2rp2        : J2 * R**2 for the Sun
!                j4rp4        : J4 * R**4 for the Sun
!                dt           : time step
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : lfirst       : logical flag indicating whether current invocation is the first
!                helio_pl1P   : pointer to head of helio massive body structure linked-list
!                helio_tp1P   : pointer to head of helio test particle structure linked-list
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL symba_step_helio(lfirst, lextra_force, t, npl, nplm, nplmax, ntp, ntpmax, helio_pl1P, helio_tp1P, j2rp2,
!                                      j4rp4, dt)
!
!  Notes       : 
!
!**********************************************************************************************************************************
SUBROUTINE symba_step_helio(lfirst, lextra_force, t, npl, nplm, nplmax, ntp, ntpmax, helio_plA, helio_tpA, j2rp2, j4rp4, dt)

! Modules
     use swiftest, EXCEPT_THIS_ONE => symba_step_helio
     IMPLICIT NONE

! Arguments
     LOGICAL(LGT), INTENT(IN)                       :: lextra_force
     LOGICAL(LGT), INTENT(INOUT)                    :: lfirst
     INTEGER(I4B), INTENT(IN)                       :: npl, nplm, nplmax, ntp, ntpmax
     REAL(DP), INTENT(IN)                           :: t, j2rp2, j4rp4, dt
     TYPE(helio_pl), INTENT(INOUT)                  :: helio_plA
     TYPE(helio_tp), INTENT(INOUT)                  :: helio_tpA

! Internals
     LOGICAL(LGT)                                   :: lfirsttp
     REAL(DP), DIMENSION(NDIM)                      :: ptb, pte
     REAL(DP), DIMENSION(NDIM, nplm)                :: xbeg, xend

! Executable code
     lfirsttp = lfirst
     CALL symba_step_helio_pl(lfirst, lextra_force, t, npl, nplm, nplmax, helio_plA, j2rp2, j4rp4, dt, xbeg, xend, ptb, pte)
     IF (ntp > 0) CALL helio_step_tp(lfirsttp, lextra_force, t, nplm, nplmax, ntp, ntpmax, helio_plA, helio_tpA, j2rp2, j4rp4,  &
          dt, xbeg, xend, ptb, pte)

     RETURN

END SUBROUTINE symba_step_helio
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

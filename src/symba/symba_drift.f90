!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 

  submodule (symba_classes) s_symba_drift
   use swiftest
contains

   module subroutine symba_drift_pl(self, system, param, dt)
      !! author: David A. Minton
      !!
      !! Wrapper function used to call the body drift routine from a symba_pl structure
      implicit none
      ! Arguments
      class(symba_pl),              intent(inout) :: self   !! Helio massive body object
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest nbody system object
      class(swiftest_parameters),   intent(in)    :: param  !! Current run configuration parameters 
      real(DP),                     intent(in)    :: dt     !! Stepsize

      if (self%nbody == 0) return
      associate(pl => self, npl => self%nbody)
         select type(system)
         class is (symba_nbody_system)
            pl%lmask(1:npl) = pl%status(1:npl) /= INACTIVE .and. pl%levelg(1:npl) == system%irec
            call helio_drift_body(pl, system, param, dt)
            pl%lmask(1:npl) = pl%status(1:npl) /= INACTIVE 
         end select
      end associate

      return
   end subroutine symba_drift_pl


   module subroutine symba_drift_tp(self, system, param, dt)
      !! author: David A. Minton
      !!
      !! Wrapper function used to call the body drift routine from a symba_pl structure
      implicit none
      ! Arguments
      class(symba_tp),              intent(inout) :: self   !! Helio massive body object
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest nbody system object
      class(swiftest_parameters),   intent(in)    :: param  !! Current run configuration parameters 
      real(DP),                     intent(in)    :: dt     !! Stepsize

      if (self%nbody == 0) return
      associate (tp => self, ntp => self%nbody)
         select type(system)
         class is (symba_nbody_system)
            tp%lmask(1:ntp) = tp%status(1:ntp) /= INACTIVE .and. tp%levelg(1:ntp) == system%irec
            call helio_drift_body(tp, system, param, dt)
            tp%lmask(1:ntp) = tp%status(1:ntp) /= INACTIVE 
         end select
      end associate

      return
   end subroutine symba_drift_tp

end submodule s_symba_drift

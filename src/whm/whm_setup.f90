!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 

submodule(whm_classes) s_whm_setup
   use swiftest
contains

   module subroutine whm_setup_pl(self, n, param)
      !! author: David A. Minton
      !!
      !! Allocate WHM planet structure
      !!
      !! Equivalent in functionality to David E. Kaufmann's Swifter routine whm_setup.f90
      implicit none
      ! Arguments
      class(whm_pl),             intent(inout) :: self  !! Swiftest test particle object
      integer(I4B),              intent(in)    :: n     !! Number of particles to allocate space for
      class(swiftest_parameters), intent(in)    :: param !! Current run configuration parameter

      !> Call allocation method for parent class
      call setup_pl(self, n, param) 
      if (n == 0) return

      allocate(self%eta(n))
      allocate(self%muj(n))
      allocate(self%xj(NDIM, n))
      allocate(self%vj(NDIM, n))
      allocate(self%ir3j(n))

      self%eta(:)   = 0.0_DP
      self%muj(:)   = 0.0_DP
      self%xj(:,:)  = 0.0_DP
      self%vj(:,:)  = 0.0_DP
      self%ir3j(:) = 0.0_DP

      return
   end subroutine whm_setup_pl 


   module subroutine whm_util_set_mu_eta_pl(self, cb)
      !! author: David A. Minton
      !!
      !! Sets the Jacobi mass value eta for all massive bodies
      implicit none
      ! Arguments
      class(whm_pl),      intent(inout) :: self   !! WHM system object
      class(swiftest_cb), intent(inout) :: cb     !! Swiftest central body object
      ! Internals
      integer(I4B)                                 :: i

      associate(pl => self, npl => self%nbody)
         if (npl == 0) return
         call util_set_mu_pl(pl, cb)
         pl%eta(1) = cb%Gmass + pl%Gmass(1)
         pl%muj(1) = pl%eta(1)
         do i = 2, npl
            pl%eta(i) = pl%eta(i - 1) + pl%Gmass(i)
            pl%muj(i) = cb%Gmass * pl%eta(i) / pl%eta(i - 1)
         end do
      end associate

      return
   end subroutine whm_util_set_mu_eta_pl


   module subroutine whm_setup_initialize_system(self, param)
      !! author: David A. Minton
      !!
      !! Initialize a WHM nbody system from files
      !!
      implicit none
      ! Arguments
      class(whm_nbody_system),    intent(inout) :: self   !! WHM nbody system object
      class(swiftest_parameters), intent(inout) :: param  !! Current run configuration parameters 

      call setup_initialize_system(self, param)
      ! First we need to make sure that the massive bodies are sorted by heliocentric distance before computing jacobies
      call util_set_ir3h(self%pl)
      call self%pl%sort("ir3h", ascending=.false.)
      call self%pl%flatten(param)

      ! Make sure that the discard list gets allocated initially
      call self%tp_discards%setup(0, param)
      call self%pl%set_mu(self%cb)
      call self%tp%set_mu(self%cb)
      if (param%lgr .and. ((param%in_type == REAL8_TYPE) .or. (param%in_type == REAL4_TYPE))) then !! pseudovelocity conversion for NetCDF input files is handled by NetCDF routines
         call self%pl%v2pv(param)
         call self%tp%v2pv(param)
      end if

      return
   end subroutine whm_setup_initialize_system

end submodule s_whm_setup
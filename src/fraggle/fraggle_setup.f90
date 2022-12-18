!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 

submodule (fraggle_classes) s_fraggle_setup
   use swiftest
contains

   module subroutine fraggle_setup_reset_fragments(self)
      !! author: David A. Minton
      !!
      !! Resets all position and velocity-dependent fragment quantities in order to do a fresh calculation (does not reset mass, radius, or other values that get set prior to the call to fraggle_generate)
      implicit none
      ! Arguments
      class(fraggle_fragments), intent(inout) :: self

      self%rb(:,:) = 0.0_DP
      self%vb(:,:) = 0.0_DP
      self%rot(:,:) = 0.0_DP
      self%v_r_unit(:,:) = 0.0_DP
      self%v_t_unit(:,:) = 0.0_DP
      self%v_n_unit(:,:) = 0.0_DP

      self%rmag(:) = 0.0_DP
      self%rotmag(:) = 0.0_DP
      self%v_r_mag(:) = 0.0_DP
      self%v_t_mag(:) = 0.0_DP

      return
   end subroutine fraggle_setup_reset_fragments


   module subroutine fraggle_setup_fragments(self, n, param)
      !! author: David A. Minton
      !!
      !! Allocates arrays for n fragments in a Fraggle system. Passing n = 0 deallocates all arrays.
      implicit none
      ! Arguments
      class(fraggle_fragments),   intent(inout) :: self 
      integer(I4B),               intent(in)    :: n
      class(swiftest_parameters), intent(in) :: param

      call collision_setup_fragments(self, n, param) 
      if (n < 0) return

      if (allocated(self%rotmag)) deallocate(self%rotmag) 
      if (allocated(self%v_r_mag)) deallocate(self%v_r_mag) 
      if (allocated(self%v_t_mag)) deallocate(self%v_t_mag) 
      if (allocated(self%v_n_mag)) deallocate(self%v_t_mag) 

      if (n == 0) return

      allocate(self%rotmag(n)) 
      allocate(self%v_r_mag(n)) 
      allocate(self%v_t_mag(n)) 
      allocate(self%v_n_mag(n)) 

      call self%reset()

      return
   end subroutine fraggle_setup_fragments

   

end submodule s_fraggle_setup
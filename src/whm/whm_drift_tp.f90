submodule(whm_classes) s_whm_drift_tp
contains
   module procedure whm_drift_tp
      !! author: David A. Minton
      !!
      !! Loop through test particles and call Danby drift routine
      !!
      !! Adapted from Hal Levison's Swift routine drift_tp.f 
      !! Includes 
      !! Adapted from David E. Kaufmann's Swifter routine whm_drift_tp.f90
      use swiftest
      implicit none
      integer(I4B)          :: i, iflag
      real(DP)            :: dtp, energy, vmag2, rmag

      associate( ntp => self%nbody)
         do i = 1, ntp
            if (self%status(i) == ACTIVE) then
               if (config%lgr) then
                  rmag = .mag. self%xh(:,i) 
                  vmag2 = dot_product(self%vh(:,i), self%vh(:,i))
                  energy = 0.5_DP * vmag2 - cb%Gmass / rmag
                  dtp = dt * (1.0_DP + 3 * config%inv_c2 * energy)
               else
                  dtp = dt
               end if
               iflag = self%drift(cb, config, dtp) !drift_one(mu, swifter_tpp%xh(:), swifter_tpp%vh(:), dtp, iflag)
               if (iflag /= 0) then
                  self%status(i) = DISCARDED_DRIFTERR
                  write(*, *) "Particle ", swifter_tpp%id, " lost due to error in danby drift"
               end if
            end if
            whm_tpp => whm_tpp%nextp
         end do
      end associate

      return

      end procedure whm_drift_tp
end submodule s_whm_drift_tp

submodule(whm_classes) whm_drift
contains



module procedure whm_drift_pl
   !! author: David A. Minton
   !!
   !! Loop through planets and call Danby drift routine
   !!
   !! Adapted from Hal Levison's Swift routine drift.f
   !! Adapted from David E. Kaufmann's Swifter routine whm_drift.f90
   use swiftest
   implicit none
   integer(I4B)          :: i
   real(DP)     :: dtp, energy, vmag2, rmag  !! Variables used in GR calculation
   integer(I4B), dimension(:), allocatable  :: iflag

   associate(npl    => self%nbody, &
      xj     => self%xj &
      vj     => self%vj &
      status => self%status,&
      mu     => self%mu_vec)

      allocate(iflag(npl))
      iflag(:) = 0
      
      do concurrent (i = 1:npl, status == ACTIVE)
         if (config%lgr) then
            rmag = .mag. xj(i, :)
            vmag2 = vj(i, :) .dot. vj(i,:) 
            energy = 0.5_DP * vmag2 - cb%Gmass / rmag
            dtp = dt * (1.0_DP + 3 * config%inv_c2 * energy)
         else
            dtp = dt
         end if
         call drift_one(mu, xj(i,:), vj(i,:), dtp, iflag(i))
      end do 
      if (any(iflag(1:npl) /= 0)) then
         do i = 1, npl
            write(*, *) " Planet ", self%name(i), " is lost!!!!!!!!!!"
            write(*, *) xj
            write(*, *) vj
            write(*, *) " stopping "
            call util_exit(FAILURE)
         end do
      end if
   end associate

   return

   end procedure whm_drift_pl

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
      integer(I4B)                            :: i   
      real(DP)     :: dtp, energy, vmag2, rmag  !! Variables used in GR calculation
      integer(I4B), dimension(:), allocatable  :: iflag

      associate(ntp    => self%nbody, &
                xh     => self%xh(i, :), &
                vh     => self%vh(i, :), &
                status => self%status(i),&
                mu     => self%mu_vec(i))
         allocate(iflag(ntp))
         iflag(:) = 0
         do concurrent (i = 1:ntp, status == ACTIVE) 
            if (config%lgr) then
               rmag = .mag. xh
               vmag2 = vh .dot. vh
               energy = 0.5_DP * vmag2 - cb%Gmass / rmag
               dtp = dt * (1.0_DP + 3 * config%inv_c2 * energy)
            else
               dtp = dt
            end if
            call drift_one(mu, xh, vh, dtp, iflag(i))
            if (iflag(i) /= 0) status = DISCARDED_DRIFTERR
         end do
         if (any(iflag(1:ntp) /= 0)) then
            do i = 1, ntp
               if (iflag(i) /= 0) write(*, *) "Particle ", self%name(i), " lost due to error in Danby drift"
            end do
         end if
      end associate

      return

      end procedure whm_drift_tp
end submodule whm_drift

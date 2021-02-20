submodule(rmvs_classes) s_rmvs_discard
contains  

   module procedure rmvs_discard_pl_tp
      !! author: David A. Minton
      !!
      !! Check to see if test particles should be discarded based on pericenter passage distances with respect to
      !!  planets encountered
      !!
      !! Adapted from Hal Levison's Swift routine discard_pl.f
      !! Adapted from Hal Levison's Swift routine rmvs_discard_pl.f90
      use swiftest
      implicit none

      integer(I4B) :: i

      associate(tp => self, ntp => self%nbody)
         do i = 1, ntp
            associate(iplperP => tp%plperP(i))
               if ((tp%status(i) == ACTIVE) .and. (tp%lperi(i))) then 
                  if ((tp%peri(i) < pl%radius(iplperP))) then
                     tp%status(i) = DISCARDED_PLQ
                     write(*, *) "Particle ",tp%name(i)," q with respect to Planet ",pl%name(iplperP)," is too small at t = ",t
                  end if
               end if
            end associate
         end do
         call discard_pl_tp(tp, cb, pl, config, t, dt)
      end associate

   end procedure rmvs_discard_pl_tp
end submodule s_rmvs_discard
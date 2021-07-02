submodule(whm_classes) s_whm_getacch
   use swiftest
contains
   module subroutine whm_getacch_pl(self, system, param, t)
      !! author: David A. Minton
      !!
      !! Compute heliocentric accelerations of planets
      !!
      !! Adapted from Hal Levison's Swift routine getacch.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch.f90
      implicit none
      ! Arguments
      class(whm_pl),              intent(inout) :: self   !! WHM massive body particle data structure
      class(whm_nbody_system),    intent(inout) :: system !! Swiftest central body particle data structure
      class(swiftest_parameters), intent(in)    :: param  !! Current run configuration parameters of 
      real(DP),                   intent(in)    :: t       !! Current time
      ! Internals
      integer(I4B)                                 :: i
      real(DP), dimension(NDIM)                    :: ah0

      associate(pl => self, cb => system%cb, npl => self%nbody)
         if (npl == 0) return
         call pl%set_ir3()

         ah0 = whm_getacch_ah0(pl%Gmass(2:npl), pl%xh(:,2:npl), npl-1)
         do i = 1, npl
            pl%ah(:, i) = ah0(:)
         end do
         call whm_getacch_ah1(cb, pl) 
         call whm_getacch_ah2(cb, pl) 
         call whm_getacch_ah3(pl)

         if (param%loblatecb) call pl%obl_acc(cb)
         if (param%lextra_force) call pl%user_getacch(cb, param, t)
         if (param%lgr) call pl%gr_getacch(param) 

      end associate
      return
   end subroutine whm_getacch_pl

   module subroutine whm_getacch_tp(self, system, param, t, xh)
      !! author: David A. Minton
      !!
      !! Compute heliocentric accelerations of test particles
      !!
      !! Adapted from Hal Levison's Swift routine getacch_tp.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch_tp.f90
      implicit none
      ! Arguments
      class(whm_tp),              intent(inout) :: self   !! WHM test particle data structure
      class(whm_nbody_system),    intent(inout) :: system !! Swiftest central body particle data structure
      class(whm_pl),              intent(inout) :: pl     !! Generic Swiftest massive body particle data structure. 
      class(swiftest_parameters), intent(in)    :: param !! Current run configuration parameters of 
      real(DP),                   intent(in)    :: t      !! Current time
      real(DP), dimension(:,:),   intent(in)    :: xh     !! Heliocentric positions of planets
      ! Internals
      integer(I4B)                              :: i
      real(DP), dimension(NDIM)                 :: ah0
   
      associate(tp => self, ntp => self%nbody, pl => system%pl, npl => system%pl%nbody)
         if (ntp == 0 .or. npl == 0) return

         ah0 = whm_getacch_ah0(pl%Gmass(:), xh(:,:), npl)
         do i = 1, ntp
            tp%ah(:, i) = ah0(:)
         end do
         call whm_getacch_ah3_tp(system, xh)
         if (param%loblatecb) call tp%obl_acc(cb)
         if (param%lextra_force) call tp%user_getacch(cb, param, t)
         if (param%lgr) call tp%gr_getacch(param) 
      end associate
      return
   end subroutine whm_getacch_tp

   function whm_getacch_ah0(mu, xh, n) result(ah0)
      !! author: David A. Minton
      !!
      !! Compute zeroth term heliocentric accelerations of planets 
      implicit none
      ! Arguments
      real(DP), dimension(:),   intent(in)         :: mu
      real(DP), dimension(:,:), intent(in)         :: xh
      integer(I4B),             intent(in)         :: n
      ! Result
      real(DP), dimension(NDIM)                    :: ah0
      ! Internals
      real(DP)                                     :: fac, r2, ir3h
      integer(I4B)                                 :: i

      ah0(:) = 0.0_DP
      do i = 1, n
         r2 = dot_product(xh(:, i), xh(:, i))
         ir3h = 1.0_DP / (r2 * sqrt(r2))
         fac = mu(i) * ir3h 
         ah0(:) = ah0(:) - fac * xh(:, i)
      end do

      return
   end function whm_getacch_ah0

   pure subroutine whm_getacch_ah1(cb, pl)
      !! author: David A. Minton
      !!
      !! Compute first term heliocentric accelerations of planets
      !!
      !! Adapted from Hal Levison's Swift routine getacch_ah1.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch_ah1.f90
      implicit none
      ! Arguments
      class(swiftest_cb), intent(in)  :: cb !! Swiftest central body object
      class(whm_pl), intent(inout)    :: pl !! WHM massive body object
      ! Internals
      integer(I4B)                    :: i
      real(DP), dimension(NDIM)       :: ah1h, ah1j

      associate(npl => pl%nbody, msun => cb%Gmass, xh => pl%xh, xj => pl%xj, ir3j => pl%ir3j, ir3h => pl%ir3h )
         do i = 2, npl
            ah1j(:) = xj(:, i) * ir3j(i)
            ah1h(:) = xh(:, i) * ir3h(i)
            pl%ah(:, i) = pl%ah(:, i) + msun * (ah1j(:) - ah1h(:))
         end do
      end associate
   
      return
   
   end subroutine whm_getacch_ah1

   pure subroutine whm_getacch_ah2(cb, pl)
      !! author: David A. Minton
      !!
      !! Compute second term heliocentric accelerations of planets
      !!
      !! Adapted from Hal Levison's Swift routine getacch_ah2.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch_ah2.f90
      implicit none
      ! Arguments
      class(swiftest_cb), intent(in)     :: cb !! Swiftest central body object
      class(whm_pl),      intent(inout)  :: pl !! WHM massive body object
      ! Internals
      integer(I4B)                                 :: i
      real(DP)                                     :: etaj, fac
      real(DP), dimension(NDIM)                    :: ah2, ah2o
   
      associate(npl => pl%nbody, Gmsun => cb%Gmass, xh => pl%xh, xj => pl%xj, Gmpl => pl%Gmass, ir3j => pl%ir3j)
         ah2(:) = 0.0_DP
         ah2o(:) = 0.0_DP
         etaj = Gmsun
         do i = 2, npl
            etaj = etaj + Gmpl(i - 1)
            fac = Gmpl(i) * Gmsun * ir3j(i) / etaj
            ah2(:) = ah2o + fac * xj(:, i)
            pl%ah(:,i) = pl%ah(:, i) + ah2(:)
            ah2o(:) = ah2(:)
         end do
      end associate
   
      return
   end subroutine whm_getacch_ah2

   pure subroutine whm_getacch_ah3(pl)
      !! author: David A. Minton
      !!
      !! Compute direct cross (third) term heliocentric accelerations of planets
      !!
      !! Adapted from Hal Levison's Swift routine getacch_ah3.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch_ah3.f90
      implicit none

      class(whm_pl),           intent(inout)       :: pl
      integer(I4B)                                 :: i, j
      real(DP)                                     :: rji2, irij3, faci, facj
      real(DP), dimension(NDIM)                    :: dx
      real(DP), dimension(:,:), allocatable        :: ah3
   
      associate(npl => pl%nbody, xh => pl%xh, Gmpl => pl%Gmass) 
         allocate(ah3, mold=pl%ah)
         ah3(:, 1:npl) = 0.0_DP

         do i = 1, npl - 1
            do j = i + 1, npl
               dx(:) = xh(:, j) - xh(:, i)
               rji2  = dot_product(dx(:), dx(:))
               irij3 = 1.0_DP / (rji2 * sqrt(rji2))
               faci = Gmpl(i) * irij3
               facj = Gmpl(j) * irij3
               ah3(:, i) = ah3(:, i) + facj * dx(:)
               ah3(:, j) = ah3(:, j) - faci * dx(:)
            end do
         end do
         do i = 1, NDIM
            pl%ah(i, 1:npl) = pl%ah(i, 1:npl) + ah3(i, 1:npl)
         end do
         deallocate(ah3)
      end associate
   
      return
   end subroutine whm_getacch_ah3

   pure subroutine whm_getacch_ah3_tp(system, xh) 
      !! author: David A. Minton
      !!
      !! Compute direct cross (third) term heliocentric accelerations of test particles
      !!
      !! Adapted from Hal Levison's Swift routine getacch_ah3_tp.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_getacch_ah3.f90
      implicit none
      ! Arguments
      class(whm_nbody_system)                      :: system !! WHM nbody system object
      real(DP), dimension(:,:), intent(in)         :: xh  !! Position vector of massive bodies at required point in step
      ! Internals
      integer(I4B)                                 :: i, j
      real(DP)                                     :: rji2, irij3, fac
      real(DP), dimension(NDIM)                    :: dx, acc

      associate(ntp => system%tp%nbody, npl => system%pl%nbody, msun => system%cb%Gmass,  GMpl => system%pl%Gmass, xht => system%tp%xh, aht => system%tp%ah)
         if (ntp == 0) return
         do i = 1, ntp
            acc(:) = 0.0_DP
            do j = 1, npl
               dx(:) = xht(:, i) - xh(:, j)
               rji2 = dot_product(dx(:), dx(:))
               irij3 = 1.0_DP / (rji2 * sqrt(rji2))
               fac = GMpl(j) * irij3
               acc(:) = acc(:) - fac * dx(:)
            end do
            aht(:, i) = aht(:, i) + acc(:)
         end do
      end associate
      return
   end subroutine whm_getacch_ah3_tp
end submodule s_whm_getacch

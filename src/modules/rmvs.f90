module rmvs
   use swiftest_globals
   use swiftest_data_structures
   implicit none
   interface

      module subroutine rmvs_chk_ind(xr, vr, dt, r2crit, iflag)
         implicit none
         real(DP), intent(in)      :: dt, r2crit
         real(DP), dimension(ndim), intent(in) :: xr, vr
         integer(I4B), intent(out)      :: iflag
      end subroutine rmvs_chk_ind

   end interface
end module rmvs

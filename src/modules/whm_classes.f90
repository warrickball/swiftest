module whm_classes
   !! author: David A. Minton
   !!
   !! Definition of classes and methods specific to the Democratic Heliocentric Method
   !! Partially adapted from David E. Kaufmann's Swifter module: module_whm.f90
   use swiftest_globals
   use swiftest_classes
   implicit none
   private
   public :: whm_setup_pl, whm_setup_tp, whm_setup_system, whm_step_system, whm_discard_spill

   !********************************************************************************************************************************
   ! whm_cb class definitions and method interfaces
   !*******************************************************************************************************************************
   !> WHM central body particle class
   type, public, extends(swiftest_cb) :: whm_cb
      real(DP), dimension(NDIM) :: xj      ! Jacobi position
      real(DP), dimension(NDIM) :: vj      ! Jacobi velocity
   contains
   end type whm_cb

   !********************************************************************************************************************************
   !                                    whm_pl class definitions and method interfaces
   !*******************************************************************************************************************************

   !> WHM massive body particle class
   type, public, extends(swiftest_pl) :: whm_pl
      real(DP), dimension(:),   allocatable :: eta    !! Jacobi mass
      real(DP), dimension(:,:), allocatable :: xj     !! Jacobi position
      real(DP), dimension(:,:), allocatable :: vj     !! Jacobi velocity
      real(DP), dimension(:),   allocatable :: muj    !! Jacobi mu: GMcb * eta(i) / eta(i - 1) 
      real(DP), dimension(:),   allocatable :: ir3j    !! Third term of heliocentric acceleration
      !! Note to developers: If you add componenets to this class, be sure to update methods and subroutines that traverse the
      !!    component list, such as whm_setup_pl and whm_discard_spill_pl
      logical                               :: lfirst = .true.
   contains
      procedure, public :: h2j          => whm_coord_h2j_pl        !! Convert position and velcoity vectors from heliocentric to Jacobi coordinates 
      procedure, public :: j2h          => whm_coord_j2h_pl        !! Convert position and velcoity vectors from Jacobi to helliocentric coordinates 
      procedure, public :: vh2vj        => whm_coord_vh2vj_pl      !! Convert velocity vectors from heliocentric to Jacobi coordinates 
      procedure, public :: setup        => whm_setup_pl            !! Constructor method - Allocates space for number of particles
      procedure, public :: getacch      => whm_getacch_pl          !! Compute heliocentric accelerations of massive bodies
      procedure, public :: gr_getacch   => whm_gr_getacch_pl       !! Acceleration term arising from the post-Newtonian correction
      procedure, public :: gr_p4        => whm_gr_p4_pl            !! Position kick due to p**4 term in the post-Newtonian correction
      procedure, public :: gr_vh2pv     => whm_gr_vh2pv_pl         !! Converts from heliocentric velocity to psudeovelocity for GR calculations
      procedure, public :: gr_pv2vh     => whm_gr_pv2vh_pl         !! Converts from psudeovelocity to heliocentric velocity for GR calculations
      procedure, public :: set_mu       => whm_setup_set_mu_eta_pl !! Sets the Jacobi mass value for all massive bodies.
      procedure, public :: set_ir3      => whm_setup_set_ir3j     !! Sets both the heliocentric and jacobi inverse radius terms (1/rj**3 and 1/rh**3)
      procedure, public :: step         => whm_step_pl             !! Steps the body forward one stepsize
      procedure, public :: user_getacch => whm_user_getacch_pl     !! User-defined acceleration
      procedure, public :: drift        => whm_drift_pl            !! Loop through massive bodies and call Danby drift routine
   end type whm_pl

   interface
      !> WHM massive body constructor method
      module subroutine whm_setup_pl(self,n)
         implicit none
         class(whm_pl), intent(inout)    :: self !! Swiftest test particle object
         integer(I4B),  intent(in)       :: n    !! Number of test particles to allocate
      end subroutine whm_setup_pl

      module subroutine whm_setup_set_mu_eta_pl(self, cb)
         implicit none
         class(whm_pl),                intent(inout) :: self    !! Swiftest system object
         class(swiftest_cb),           intent(inout) :: cb     !! WHM central body particle data structure
      end subroutine whm_setup_set_mu_eta_pl

      module subroutine whm_setup_set_ir3j(self)
         implicit none
         class(whm_pl),                intent(inout) :: self    !! WHM massive body object
      end subroutine whm_setup_set_ir3j

      module subroutine whm_step_pl(self, cb, config, t, dt)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structure
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t      !! Current time
         real(DP),                      intent(in)    :: dt     !! Stepsize
      end subroutine whm_step_pl

      !> Get heliocentric accelration of massive bodies
      module subroutine whm_getacch_pl(self, cb, config, t)
         implicit none
         class(whm_pl),                 intent(inout) :: self     !! WHM massive body particle data structure
         class(whm_cb),                 intent(inout) :: cb       !! WHM central body particle data structure
         class(swiftest_configuration), intent(in)    :: config   !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t        !! Current time
      end subroutine whm_getacch_pl

      module subroutine whm_drift_pl(self, cb, config, dt)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(swiftest_cb),            intent(inout) :: cb     !! WHM central body particle data structur
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: dt     !! Stepsize
      end subroutine whm_drift_pl

      module subroutine whm_getacch_int_pl(self, cb)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),       intent(inout) :: cb     !! WHM central body particle data structure
      end subroutine whm_getacch_int_pl

      module subroutine whm_user_getacch_pl(self, cb, config, t)
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structuree
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t      !! Current time
      end subroutine whm_user_getacch_pl

      module subroutine whm_coord_h2j_pl(self, cb)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structuree
      end subroutine whm_coord_h2j_pl

      module subroutine whm_coord_j2h_pl(self, cb)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structuree
      end subroutine whm_coord_j2h_pl

      module subroutine whm_coord_vh2vj_pl(self, cb)
         implicit none
         class(whm_pl),       intent(inout) :: self   !! WHM massive body particle data structure
         class(whm_cb),       intent(inout) :: cb     !! WHM central body particle data structuree
      end subroutine whm_coord_vh2vj_pl

      module subroutine whm_gr_getacch_pl(self, cb, config)
         implicit none
         class(whm_pl),       intent(inout) :: self   !! WHM massive body particle data structure
         class(swiftest_cb),  intent(inout) :: cb     !! WHM central body particle data structuree
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
      end subroutine whm_gr_getacch_pl

      module pure subroutine whm_gr_p4_pl(self, config, dt)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
         real(DP),                      intent(in)    :: dt     !! Step size
      end subroutine whm_gr_p4_pl

      module pure subroutine whm_gr_vh2pv_pl(self, config)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
      end subroutine whm_gr_vh2pv_pl

      module pure subroutine whm_gr_pv2vh_pl(self, config)
         implicit none
         class(whm_pl),                 intent(inout) :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
      end subroutine whm_gr_pv2vh_pl
   end interface

   !********************************************************************************************************************************
   !  whm_tp class definitions and method interfaces
   !*******************************************************************************************************************************

   !! WHM test particle class
   type, public, extends(swiftest_tp) :: whm_tp
      !! Note to developers: If you add componenets to this class, be sure to update methods and subroutines that traverse the
      !!    component list, such as whm_setup_tp and whm_discard_spill_tp
      real(DP), dimension(:,:), allocatable :: xbeg, xend
      logical                               :: lfirst = .true.
   contains
      private
      procedure, public :: setup        => whm_setup_tp        !! Allocates new components of the whm class and recursively calls parent allocations
      procedure, public :: getacch      => whm_getacch_tp      !! Compute heliocentric accelerations of test particles
      procedure, public :: gr_getacch   => whm_gr_getacch_tp   !! Acceleration term arising from the post-Newtonian correction
      procedure, public :: gr_p4        => whm_gr_p4_tp        !! Position kick due to p**4 term in the post-Newtonian correction
      procedure, public :: gr_vh2pv     => whm_gr_vh2pv_tp     !! Converts from heliocentric velocity to psudeovelocity for GR calculations
      procedure, public :: gr_pv2vh     => whm_gr_pv2vh_tp     !! Converts from psudeovelocity to heliocentric velocity for GR calculations
      procedure, public :: step         => whm_step_tp         !! Steps the particle forward one stepsize
      procedure, public :: user_getacch => whm_user_getacch_tp !! User-defined acceleration
      procedure, public :: drift        => whm_drift_tp        !! Loop through test particles and call Danby drift routine

   end type whm_tp

   interface
      !> WHM test particle constructor 
      module subroutine whm_setup_tp(self,n)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM test particle data structure
         integer,                       intent(in)    :: n      !! Number of test particles to allocate
      end subroutine whm_setup_tp

      module subroutine whm_drift_tp(self, cb, config, dt)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM test particle data structure
         class(swiftest_cb),            intent(inout) :: cb     !! WHM central body particle data structuree
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: dt     !! Stepsize
      end subroutine whm_drift_tp

      !> Get heliocentric accelration of the test particle
      module subroutine whm_getacch_tp(self, cb, pl, config, t, xh)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM test particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structuree 
         class(whm_pl),                 intent(inout) :: pl     !! WHM massive body particle data structure. 
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t         !! Current time
         real(DP), dimension(:,:),      intent(in)    :: xh
      end subroutine whm_getacch_tp

      module subroutine whm_step_tp(self, cb, pl, config, t, dt)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM test particle data structure
         class(whm_cb),                 intent(inout) :: cb     !! WHM central body particle data structure
         class(whm_pl),                 intent(inout) :: pl     !! WHM massive body data structure
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t      !! Current time
         real(DP),                      intent(in)    :: dt     !! Stepsize
      end subroutine whm_step_tp
      module subroutine whm_user_getacch_tp(self, cb, config, t)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM test particle data structure
         class(whm_cb),       intent(inout) :: cb     !! WHM central body particle data structuree
         class(swiftest_configuration), intent(in)    :: config    !! Input collection of user-defined parameter
         real(DP),                      intent(in)    :: t         !! Current time
      end subroutine whm_user_getacch_tp

      module subroutine whm_gr_getacch_tp(self, cb, config)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! WHM massive body particle data structure
         class(swiftest_cb),            intent(inout) :: cb     !! WHM central body particle data structuree
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined parameter
      end subroutine whm_gr_getacch_tp

      module pure subroutine whm_gr_p4_tp(self, config, dt)
         implicit none
         class(whm_tp),                 intent(inout) :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
         real(DP),                      intent(in)    :: dt     !! Step size
      end subroutine whm_gr_p4_tp

      module pure subroutine whm_gr_vh2pv_tp(self, config)
         implicit none
         class(whm_tp),                 intent(inout)    :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
      end subroutine whm_gr_vh2pv_tp

      module pure subroutine whm_gr_pv2vh_tp(self, config)
         implicit none
         class(whm_tp),                 intent(inout)    :: self   !! Swiftest particle object
         class(swiftest_configuration), intent(in)    :: config !! Input collection of user-defined configuration parameters 
      end subroutine whm_gr_pv2vh_tp
   end interface

   !********************************************************************************************************************************
   !  whm_nbody_system class definitions and method interfaces
   !********************************************************************************************************************************
   !> An abstract class for the WHM integrator nbody system 
   type, public, extends(swiftest_nbody_system) :: whm_nbody_system
      !> In the WHM integrator, only test particles are discarded
      class(swiftest_tp), allocatable :: tp_discards
   contains
      private
      !> Replace the abstract procedures with concrete ones
      procedure, public :: initialize    => whm_setup_system  !! Performs WHM-specific initilization steps, like calculating the Jacobi masses
      
   end type whm_nbody_system

   interface
      module subroutine whm_setup_system(self, config)
         implicit none
         class(whm_nbody_system),       intent(inout) :: self    !! Swiftest system object
         class(swiftest_configuration), intent(inout) :: config  !! Input collection of user-defined configuration parameters 
      end subroutine whm_setup_system

   end interface

   !> Interfaces for all non-type bound whm methods that are implemented in separate submodules 
   interface
      !> Move spilled (discarded) Swiftest basic body components from active list to discard list
      module subroutine whm_discard_spill(keeps, discards, lspill_list)
         implicit none
         class(swiftest_body),  intent(inout) :: keeps       !! WHM test particle object
         class(swiftest_body),  intent(inout) :: discards    !! Discarded object 
         logical, dimension(:), intent(in)    :: lspill_list !! Logical array of bodies to spill into the discards
      end subroutine whm_discard_spill

      !> Steps the Swiftest nbody system forward in time one stepsize
      module subroutine whm_step_system(cb, pl, tp, config)
         implicit none
         class(whm_cb),            intent(inout) :: cb      !! WHM central body object  
         class(whm_pl),            intent(inout) :: pl      !! WHM central body object  
         class(whm_tp),            intent(inout) :: tp      !! WHM central body object  
         class(swiftest_configuration), intent(in)    :: config  !! Input collection of user-defined configuration parameters 
      end subroutine whm_step_system
   end interface

end module whm_classes

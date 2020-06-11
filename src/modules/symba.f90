module symba
   !! author: The Purdue Swiftest Team -  David A. Minton, Carlisle A. Wishard, Jennifer L.L. Pouplin, and Jacob R. Elliott
   !!
   !! Definition of classes and methods specific to the Symplectic Massive Body Algorithm
   !!
   !! Adapted from David E. Kaufmann's Swifter modules: module_symba.f90
   use helio
   implicit none

   integer(I4B), public, parameter :: NENMAX = 32767
   integer(I4B), public, parameter :: NTENC = 3
   real(DP), public, parameter     :: RHSCALE = 6.5_DP
   real(DP), public, parameter     :: RSHELL = 0.48075_DP

   !! SyMBA test particle class
   type, public, extends(helio_tp) :: symba_tp
      integer(I4B), dimension(:),     allocatable :: nplenc  !! number of encounters with planets this time step
      integer(I4B), dimension(:),     allocatable :: levelg  !! level at which this particle should be moved
      integer(I4B), dimension(:),     allocatable :: levelm  !! deepest encounter level achieved this time step
   contains
      procedure :: alloc => symba_tp_allocate
      final :: symba_tp_deallocate
   end type symba_tp

   !! SyMBA massive body particle class
   type, public, extends(helio_pl) :: symba_pl
      logical, dimension(:),     allocatable :: lmerged      !! flag indicating whether body has merged with another this time step
      integer(I4B), dimension(:),     allocatable :: nplenc  !! number of encounters with other planets this time step
      integer(I4B), dimension(:),     allocatable :: ntpenc  !! number of encounters with test particles this time step
      integer(I4B), dimension(:),     allocatable :: levelg  !! level at which this body should be moved
      integer(I4B), dimension(:),     allocatable :: levelm  !! deepest encounter level achieved this time step
      integer(I4B), dimension(:),     allocatable :: nchild  !! number of children in merger list
      integer(I4B), dimension(:),     allocatable :: index_parent  !! position of the parent of id
      integer(I4B), dimension(:,:),   allocatable :: index_child   !! position of the children of id
   contains
      procedure :: alloc => symba_pl_allocate
      final :: symba_pl_deallocate
   end type symba_pl

   !! Generic abstract class structure for a SyMBA encounter class
   type, private, extends(swiftest_particle) :: symba_encounter
      logical     , dimension(:),     allocatable :: lvdotr !! relative vdotr flag
      integer(I4B), dimension(:),     allocatable :: level  !! encounter recursion level
   contains
      procedure :: alloc => symba_encounter_allocate
      final :: symba_encounter_dealloc
   end type symba_encounter

   !! Class structure for a planet-planet encounter
   type, public, extends(symba_encounter) :: symba_plplenc
      integer(I4B), dimension(:), allocatable :: index1       !! position of the first planet in encounter
      integer(I4B), dimension(:), allocatable :: index2       !! position of the second planet in encounter
      integer(I4B), dimension(:), allocatable :: enc_child    !! the child of the encounter
      integer(I4B), dimension(:), allocatable :: enc_parent   !! the child of the encounter
   contains
      procedure :: alloc => symba_plplenc_allocate
      final :: symba_plplenc_deallocate
   end type symba_plplenc

   !! Class structure for a planet-test particle encounter
   type, public, extends(symba_encounter) :: symba_pltpenc
      integer(I4B), dimension(:), allocatable :: indexpl    !! Index position within the main symba structure for the first planet in an encounter
      integer(I4B), dimension(:), allocatable :: indextp    !! Index position within the main symba structure for the second planet in an encounter
   contains
      procedure :: alloc => symba_pltpenc_allocate
      final :: symba_pltpenc_deallocate
   end type symba_pltpenc

   !! Class that 
   type, public, extends(swiftest_pl) :: symba_merger
      integer(I4B), dimension(:), allocatable :: index_ps   ! Index position within the main symba structure for the body being merged
   contains
      procedure :: alloc => symba_merger_allocate
      final :: symba_merger_deallocate
   end type symba_merger 

!> Only the constructor and destructor method implementations are listed here. All other methods are implemented in the symba submodules.
!interface
!! Interfaces for all helio particle methods that are implemented in separate submodules 
!end interface
contains
   !! SyMBA constructor and desctructor methods
   subroutine symba_tp_allocate(self,n)
      !! SyMBA test particle constructor method
      implicit none

      class(symba_tp), intent(inout) :: self !! Symba test particle object
      integer, intent(in)            :: n    !! Number of test particles to allocate

      call self%helio_tp%alloc(n)

      if (self%is_allocated) then
         write(*,*) 'Symba test particle structure already alllocated'
         return
      end if
      write(*,*) 'Allocating the Swiftest test particle structure'
      
      if (n <= 0) return
      allocate(self%nplenc(n))
      allocate(self%levelg(n))
      allocate(self%levelm(n))

      self%nplenc(:) = 0
      self%levelg(:) = 0
      self%levelm(:) = 0
      return
   end subroutine symba_tp_allocate

   subroutine symba_tp_deallocate(self)
      !! SyMBA test particle destructor/finalizer
      implicit none

      type(symba_tp), intent(inout)    :: self

      if (self%is_allocated) then
         deallocate(self%nplenc(n))
         deallocate(self%levelg(n))
         deallocate(self%levelm(n))
      end if
      return
   end subroutine symba_tp_deallocate

   subroutine symba_pl_allocate(self,n)
      !! SyMBA massive body constructor method
      implicit none

      class(symba_pl), intent(inout) :: self !! SyMBA massive body particle object
      integer, intent(in)            :: n    !! Number of massive body particles to allocate

      call self%helio_pl%alloc(n)

      if (self%is_allocated) then
         write(*,*) 'Symba planet structure already alllocated'
         return
      end if
      if (n <= 0) return
      allocate(self%lmerged(n))
      allocate(self%nplenc(n))
      allocate(self%ntpenc(n))
      allocate(self%levelg(n))
      allocate(self%levelm(n))
      allocate(self%nchild(n))
      allocate(self%index_parent(n))
      allocate(self%index_child(n,n))

      self%lmerged(:) = .false.
      self%nplenc(:) = 0
      self%ntpenc(:) = 0
      self%levelg(:) = 0
      self%levelm(:) = 0
      self%nchild(:) = 0
      self%index_parent(:) = 1
      self%index_child(:) = 1

      return
   end subroutine symba_pl_allocate

   subroutine symba_pl_deallocate(self)
      !! SyMBA massive body destructor/finalizer
      implicit none

      type(symba_pl), intent(inout)    :: self
      if (self%is_allocated) then
         deallocate(self%lmerged)
         deallocate(self%nplenc)
         deallocate(self%ntpenc)
         deallocate(self%levelg)
         deallocate(self%levelm)
         deallocate(self%nchild)
         deallocate(self%index_parent)
         deallocate(self%index_child)
      end if
      return
   end subroutine symba_pl_deallocate

   subroutine symba_encounter_allocate
      !! Basic Symba encounter structure constructor method
      implicit none

      class(symba_encounter), intent(inout) :: self !! SyMBA encounter super class
      integer, intent(in)                   :: n    !! Number of test particles to allocate
     
      call self%superalloc(n)
      if (n <= 0) return

      if (self%is_allocated) then
         write(*,*) 'SyMBA encounter structure already alllocated'
         return
      end if
      write(*,*) 'Allocating the Symba encounter superclass'

      allocate(self%lvdotr(n)))
      allocate(self%level(n))

      self%lvdotr(:) = .false.
      self%level(:) = 0

      return
   end subroutine symba_encounter_allocate
   
   subroutine symba_encounter_dealloc
   end subroutine symba_encounter_dealloc

   subroutine symba_pltpenc_allocate
      !! SyMBA planet-test particle encounter structure constructor method
      implicit none

      class(symba_pltpenc), intent(inout) :: self !! SyMBA encounter super class
      integer, intent(in)                   :: n    !! Number of test particles to allocate

      allocate(self%index1(n))
      allocate(self%index2(n))
      allocate(self%enc_child(n))
      allocate(self%enc_parent(n)) 
   end subroutine symba_pltpenc_allocate

   subroutine symba_pltpenc_deallocate
   end subroutine symba_pltpenc_deallocate

   subroutine symba_plplenc_allocate
   end subroutine symba_plplenc_allocate

   subroutine symba_plplenc_deallocate
   end subroutine symba_plplenc_deallocate

   subroutine symba_merger_allocate
   end subroutine symba_merger_allocate

   subroutine symba_merger_deallocate
   end subroutine symba_merger_deallocate

end module symba

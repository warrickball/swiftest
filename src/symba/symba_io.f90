!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 

submodule (symba_classes) s_symba_io
   use swiftest
contains

   module subroutine symba_io_encounter_dump(self, param)
      !! author: David A. Minton
      !!
      !! Dumps the time history of an encounter to file.
      implicit none
      ! Arguments
      class(symba_encounter_storage(*)),  intent(inout)        :: self   !! Encounter storage object
      class(swiftest_parameters),   intent(inout)        :: param  !! Current run configuration parameters 
      ! Internals
      integer(I4B) :: i

      ! Most of this is just temporary test code just to get something working. Eventually this should get cleaned up.
      call self%nciu%initialize(param)
      do i = 1, self%nframes
         if (allocated(self%frame(i)%item)) then
            select type(snapshot => self%frame(i)%item)
            class is (symba_encounter_snapshot)
               self%nciu%ienc_frame = i
               call snapshot%write_frame(self%nciu,param)
            end select
         end if
      end do
      call self%nciu%close()


      return
   end subroutine symba_io_encounter_dump


   module subroutine symba_io_encounter_initialize_output(self, param)
      !! author: David A. Minton
      !!
      !! Initialize a NetCDF encounter file system. This is a simplified version of the main simulation output NetCDF file, but with fewer variables.
      use, intrinsic :: ieee_arithmetic
      use netcdf
      implicit none
      ! Arguments
      class(symba_io_encounter_parameters), intent(inout) :: self    !! Parameters used to identify a particular NetCDF dataset
      class(swiftest_parameters),           intent(in)    :: param   !! Current run configuration parameters
      ! Internals
      integer(I4B) :: nvar, varid, vartype
      real(DP) :: dfill
      real(SP) :: sfill
      logical :: fileExists
      character(len=STRMAX) :: errmsg
      integer(I4B) :: ndims


      associate(nciu => self)
         dfill = ieee_value(dfill, IEEE_QUIET_NAN)
         sfill = ieee_value(sfill, IEEE_QUIET_NAN)

         select case (param%out_type)
         case("NETCDF_FLOAT")
            self%out_type = NF90_FLOAT
         case("NETCDF_DOUBLE")
            self%out_type = NF90_DOUBLE
         end select


         ! Check if the file exists, and if it does, delete it
         inquire(file=nciu%enc_file, exist=fileExists)
         if (fileExists) then
            open(unit=LUN, file=nciu%enc_file, status="old", err=667, iomsg=errmsg)
            close(unit=LUN, status="delete")
         end if

         call check( nf90_create(nciu%enc_file, NF90_NETCDF4, nciu%id), "symba_io_encounter_initialize_output nf90_create" )

         ! Dimensions
         call check( nf90_def_dim(nciu%id, nciu%time_dimname, NF90_UNLIMITED, nciu%time_dimid), "symba_io_encounter_initialize_output nf90_def_dim time_dimid" ) ! Simulation time dimension
         call check( nf90_def_dim(nciu%id, nciu%space_dimname, NDIM, nciu%space_dimid), "symba_io_encounter_initialize_output nf90_def_dim space_dimid" )           ! 3D space dimension
         call check( nf90_def_dim(nciu%id, nciu%id_dimname, NF90_UNLIMITED, nciu%id_dimid), "symba_io_encounter_initialize_output nf90_def_dim id_dimid" )       ! dimension to store particle id numbers
         call check( nf90_def_dim(nciu%id, nciu%str_dimname, NAMELEN, nciu%str_dimid), "symba_io_encounter_initialize_output nf90_def_dim str_dimid"  )          ! Dimension for string variables (aka character arrays)

         ! Dimension coordinates
         call check( nf90_def_var(nciu%id, nciu%time_dimname, nciu%out_type, nciu%time_dimid, nciu%time_varid), "symba_io_encounter_initialize_output nf90_def_var time_varid"  )
         call check( nf90_def_var(nciu%id, nciu%space_dimname, NF90_CHAR, nciu%space_dimid, nciu%space_varid), "symba_io_encounter_initialize_output nf90_def_var space_varid"  )
         call check( nf90_def_var(nciu%id, nciu%id_dimname, NF90_INT, nciu%id_dimid, nciu%id_varid), "symba_io_encounter_initialize_output nf90_def_var id_varid"  )
      
         ! Variables
         call check( nf90_def_var(nciu%id, nciu%name_varname, NF90_CHAR, [nciu%str_dimid, nciu%id_dimid], nciu%name_varid), "symba_io_encounter_initialize_output nf90_def_var name_varid"  )
         call check( nf90_def_var(nciu%id, nciu%ptype_varname, NF90_CHAR, [nciu%str_dimid, nciu%id_dimid], nciu%ptype_varid), "symba_io_encounter_initialize_output nf90_def_var ptype_varid"  )
         call check( nf90_def_var(nciu%id, nciu%rh_varname,  nciu%out_type, [nciu%space_dimid, nciu%id_dimid, nciu%time_dimid], nciu%rh_varid), "symba_io_encounter_initialize_output nf90_def_var rh_varid"  )
         call check( nf90_def_var(nciu%id, nciu%vh_varname,  nciu%out_type, [nciu%space_dimid, nciu%id_dimid, nciu%time_dimid], nciu%vh_varid), "symba_io_encounter_initialize_output nf90_def_var vh_varid"  )
         call check( nf90_def_var(nciu%id, nciu%gmass_varname, nciu%out_type, [nciu%id_dimid, nciu%time_dimid], nciu%Gmass_varid), "symba_io_encounter_initialize_output nf90_def_var Gmass_varid"  )
         if (param%lclose) then
            call check( nf90_def_var(nciu%id, nciu%radius_varname, nciu%out_type, [nciu%id_dimid, nciu%time_dimid], nciu%radius_varid), "symba_io_encounter_initialize_output nf90_def_var radius_varid"  )
         end if
         if (param%lrotation) then
            call check( nf90_def_var(nciu%id, nciu%Ip_varname, nciu%out_type, [nciu%space_dimid, nciu%id_dimid, nciu%time_dimid], nciu%Ip_varid), "symba_io_encounter_initialize_output nf90_def_var Ip_varid"  )
            call check( nf90_def_var(nciu%id, nciu%rot_varname, nciu%out_type, [nciu%space_dimid, nciu%id_dimid, nciu%time_dimid], nciu%rot_varid), "symba_io_encounter_initialize_output nf90_def_var rot_varid"  )
         end if

         call check( nf90_inquire(nciu%id, nVariables=nvar), "symba_io_encounter_initialize_output nf90_inquire nVariables"  )
         do varid = 1, nvar
            call check( nf90_inquire_variable(nciu%id, varid, xtype=vartype, ndims=ndims), "symba_io_encounter_initialize_output nf90_inquire_variable"  )
            select case(vartype)
            case(NF90_INT)
               call check( nf90_def_var_fill(nciu%id, varid, 0, NF90_FILL_INT), "symba_io_encounter_initialize_output nf90_def_var_fill NF90_INT"  )
            case(NF90_FLOAT)
               call check( nf90_def_var_fill(nciu%id, varid, 0, sfill), "symba_io_encounter_initialize_output nf90_def_var_fill NF90_FLOAT"  )
            case(NF90_DOUBLE)
               call check( nf90_def_var_fill(nciu%id, varid, 0, dfill), "symba_io_encounter_initialize_output nf90_def_var_fill NF90_DOUBLE"  )
            case(NF90_CHAR)
               call check( nf90_def_var_fill(nciu%id, varid, 0, 0), "symba_io_encounter_initialize_output nf90_def_var_fill NF90_CHAR"  )
            end select
         end do

         ! Take the file out of define mode
         call check( nf90_enddef(nciu%id), "symba_io_encounter_initialize_output nf90_enddef"  )

         ! Add in the space dimension coordinates
         call check( nf90_put_var(nciu%id, nciu%space_varid, nciu%space_coords, start=[1], count=[NDIM]), "symba_io_encounter_initialize_output nf90_put_var space"  )
      end associate

      return

      667 continue
      write(*,*) "Error creating encounter output file. " // trim(adjustl(errmsg))
      call util_exit(FAILURE)
   end subroutine symba_io_encounter_initialize_output


   module subroutine symba_io_encounter_write_frame(self, nciu, param)
      !! author: David A. Minton
      !!
      !! Write a frame of output of an encounter list structure.
      use netcdf
      implicit none
      ! Arguments
      class(symba_encounter_snapshot),      intent(in)    :: self   !! Swiftest encounter structure
      class(symba_io_encounter_parameters), intent(inout) :: nciu   !! Parameters used to identify a particular encounter io NetCDF dataset
      class(swiftest_parameters),           intent(inout) :: param  !! Current run configuration parameters
      ! Internals
      integer(I4B)                             :: i,  tslot, idslot, old_mode, n
      character(len=NAMELEN)                   :: charstring

      tslot = nciu%ienc_frame
      select type(pl => self%pl)
      class is (symba_pl)
         n = size(pl%id(:))
         do i = 1, n
            idslot = pl%id(i)
            call check( nf90_set_fill(nciu%id, nf90_nofill, old_mode), "symba_io_encounter_write_frame_base nf90_set_fill"  )
            call check( nf90_put_var(nciu%id, nciu%time_varid, self%t, start=[tslot]), "symba_io_encounter_write_frame nf90_put_var time_varid"  )
            call check( nf90_put_var(nciu%id, nciu%id_varid, pl%id(i), start=[idslot]), "symba_io_encounter_write_frame_base nf90_put_var id_varid"  )
            call check( nf90_put_var(nciu%id, nciu%rh_varid, pl%rh(:,i), start=[1,idslot,tslot], count=[NDIM,1,1]), "symba_io_encounter_write_frame_base nf90_put_var rh_varid"  )
            call check( nf90_put_var(nciu%id, nciu%vh_varid, pl%vh(:,i), start=[1,idslot,tslot], count=[NDIM,1,1]), "symba_io_encounter_write_frame_base nf90_put_var vh_varid"  )
            call check( nf90_put_var(nciu%id, nciu%Gmass_varid, pl%Gmass(i), start=[idslot, tslot]), "symba_io_encounter_write_frame_base nf90_put_var body Gmass_varid"  )
            if (param%lclose) call check( nf90_put_var(nciu%id, nciu%radius_varid, pl%radius(i), start=[idslot, tslot]), "symba_io_encounter_write_frame_base nf90_put_var body radius_varid"  )
            if (param%lrotation) then
               call check( nf90_put_var(nciu%id, nciu%Ip_varid, pl%Ip(:,i), start=[1, idslot, tslot], count=[NDIM,1,1]), "symba_io_encounter_write_frame_base nf90_put_var body Ip_varid"  )
               call check( nf90_put_var(nciu%id, nciu%rot_varid, pl%rot(:,i), start=[1,idslot, tslot], count=[NDIM,1,1]), "symba_io_encounter_write_frame_base nf90_put_var body rotx_varid"  )
            end if
            charstring = trim(adjustl(pl%info(i)%name))
            call check( nf90_put_var(nciu%id, nciu%ptype_varid, charstring, start=[1, idslot], count=[NAMELEN, 1]), "symba_io_encounter_write_frame nf90_put_var particle_type_varid"  )
            charstring = trim(adjustl(pl%info(i)%particle_type))
            call check( nf90_put_var(nciu%id, nciu%name_varid, charstring, start=[1, idslot], count=[NAMELEN, 1]), "symba_io_encounter_write_frame nf90_put_var name_varid"  )
         end do
      end select

      call check( nf90_set_fill(nciu%id, old_mode, old_mode) )

      return
   end subroutine symba_io_encounter_write_frame


   module subroutine symba_io_param_reader(self, unit, iotype, v_list, iostat, iomsg) 
      !! author: The Purdue Swiftest Team - David A. Minton, Carlisle A. Wishard, Jennifer L.L. Pouplin, and Jacob R. Elliott
      !!
      !! Read in parameters specific to the SyMBA integrator, then calls the base io_param_reader.
      !!
      !! Adapted from David E. Kaufmann's Swifter routine io_init_param.f90
      !! Adapted from Martin Duncan's Swift routine io_init_param.f
      implicit none
      ! Arguments
      class(symba_parameters), intent(inout) :: self       !! Collection of parameters
      integer,                 intent(in)    :: unit       !! File unit number
      character(len=*),        intent(in)    :: iotype     !! Dummy argument passed to the  input/output procedure contains the text from the char-literal-constant, prefixed with DT. 
                                                           !!    If you do not include a char-literal-constant, the iotype argument contains only DT.
      character(len=*),        intent(in)    :: v_list(:)  !! The first element passes the integrator code to the reader
      integer,                 intent(out)   :: iostat     !! IO status code
      character(len=*),        intent(inout) :: iomsg      !! Message to pass if iostat /= 0
      ! internals
      integer(I4B)                   :: ilength, ifirst, ilast  !! Variables used to parse input file
      character(STRMAX)              :: line                    !! Line of the input file
      character (len=:), allocatable :: line_trim,param_name, param_value !! Strings used to parse the param file
      integer(I4B)                   :: nseeds, nseeds_from_file, i
      logical                        :: seed_set = .false.      !! Is the random seed set in the input file?
      character(len=*),parameter     :: linefmt = '(A)'

      associate(param => self)
         open(unit = unit, file = param%param_file_name, status = 'old', err = 667, iomsg = iomsg)
         call random_seed(size = nseeds)
         if (allocated(param%seed)) deallocate(param%seed)
         allocate(param%seed(nseeds))
         do
            read(unit = unit, fmt = linefmt, iostat = iostat, end = 1, err = 667, iomsg = iomsg) line
            line_trim = trim(adjustl(line))
            ilength = len(line_trim)
            if ((ilength /= 0)) then 
               ifirst = 1
               ! Read the pair of tokens. The first one is the parameter name, the second is the value.
               param_name = io_get_token(line_trim, ifirst, ilast, iostat)
               if (param_name == '') cycle ! No parameter name (usually because this line is commented out)
               call io_toupper(param_name)
               ifirst = ilast + 1
               param_value = io_get_token(line_trim, ifirst, ilast, iostat)
               select case (param_name)
               case ("OUT_STAT") ! We need to duplicate this from the standard io_param_reader in order to make sure that the restart flag gets set properly in SyMBA
                  call io_toupper(param_value)
                  param%out_stat = param_value 
               case ("FRAGMENTATION")
                  call io_toupper(param_value)
                  if (param_value == "YES" .or. param_value == "T") self%lfragmentation = .true.
               case ("GMTINY")
                  read(param_value, *) param%GMTINY
               case ("MIN_GMFRAG")
                  read(param_value, *) param%min_GMfrag
               case ("ENCOUNTER_SAVE")
                  call io_toupper(param_value)
                  read(param_value, *) param%encounter_save
               case("SEED")
                  read(param_value, *) nseeds_from_file
                  ! Because the number of seeds can vary between compilers/systems, we need to make sure we can handle cases in which the input file has a different
                  ! number of seeds than the current system. If the number of seeds in the file is smaller than required, we will use them as a source to fill in the missing elements.
                  ! If the number of seeds in the file is larger than required, we will truncate the seed array.
                  if (nseeds_from_file > nseeds) then
                     nseeds = nseeds_from_file
                     deallocate(param%seed)
                     allocate(param%seed(nseeds))
                     do i = 1, nseeds
                        ifirst = ilast + 2
                        param_value = io_get_token(line, ifirst, ilast, iostat) 
                        read(param_value, *) param%seed(i)
                     end do
                  else ! Seed array in file is too small
                     do i = 1, nseeds_from_file
                        ifirst = ilast + 2
                        param_value = io_get_token(line, ifirst, ilast, iostat) 
                        read(param_value, *) param%seed(i)
                     end do
                     param%seed(nseeds_from_file+1:nseeds) = [(param%seed(1) - param%seed(nseeds_from_file) + i, &
                                                               i=nseeds_from_file+1, nseeds)]
                  end if
                  seed_set = .true.
               end select
            end if
         end do
         1 continue
         close(unit)

         param%lrestart = (param%out_stat == "APPEND")

         if (self%GMTINY < 0.0_DP) then
            write(iomsg,*) "GMTINY invalid or not set: ", self%GMTINY
            iostat = -1
            return
         end if

         if (param%lfragmentation) then
            if (seed_set) then
               call random_seed(put = param%seed)
            else
               call random_seed(get = param%seed)
            end if
            if (param%min_GMfrag < 0.0_DP) param%min_GMfrag = param%GMTINY
         end if

         ! All reporting of collision information in SyMBA (including mergers) is now recorded in the Fraggle logfile
         call io_log_start(param, FRAGGLE_LOG_OUT, "Fraggle logfile")

         if ((param%encounter_save /= "NONE") .and. (param%encounter_save /= "ALL") .and. (param%encounter_save /= "FRAGMENTATION")) then
            write(iomsg,*) 'Invalid encounter_save parameter: ',trim(adjustl(param%out_type))
            write(iomsg,*) 'Valid options are NONE, ALL, or FRAGMENTATION'
            iostat = -1
            return
         end if

         ! Call the base method (which also prints the contents to screen)
         call io_param_reader(param, unit, iotype, v_list, iostat, iomsg) 
      end associate

      iostat = 0

      return
      667 continue
      write(*,*) "Error reading SyMBA parameters in param file: ", trim(adjustl(iomsg))
   end subroutine symba_io_param_reader


   module subroutine symba_io_param_writer(self, unit, iotype, v_list, iostat, iomsg) 
      !! author: David A. Minton
      !!
      !! Dump integration parameters specific to SyMBA to file and then call the base io_param_writer method.
      !!
      !! Adapted from David E. Kaufmann's Swifter routine io_dump_param.f90
      !! Adapted from Martin Duncan's Swift routine io_dump_param.f
      implicit none
      ! Arguments
      class(symba_parameters),intent(in)    :: self      !! Collection of SyMBA parameters
      integer,                intent(in)    :: unit      !! File unit number
      character(len=*),       intent(in)    :: iotype    !! Dummy argument passed to the  input/output procedure contains the text from the char-literal-constant, prefixed with DT. 
                                                         !!    If you do not include a char-literal-constant, the iotype argument contains only DT.
      integer,                intent(in)    :: v_list(:) !! Not used in this procedure
      integer,                intent(out)   :: iostat    !! IO status code
      character(len=*),       intent(inout) :: iomsg     !! Message to pass if iostat /= 0
      ! Internals
      integer(I4B) :: nseeds

      associate(param => self)
         call io_param_writer(param, unit, iotype, v_list, iostat, iomsg) 

         ! Special handling is required for writing the random number seed array as its size is not known until runtime
         ! For the "SEED" parameter line, the first value will be the size of the seed array and the rest will be the seed array elements
         call io_param_writer_one("GMTINY",param%GMTINY, unit)
         call io_param_writer_one("MIN_GMFRAG",param%min_GMfrag, unit)
         call io_param_writer_one("FRAGMENTATION",param%lfragmentation, unit)
         if (param%lfragmentation) then
            nseeds = size(param%seed)
            call io_param_writer_one("SEED", [nseeds, param%seed(:)], unit)
         end if

         iostat = 0
      end associate

      return
      667 continue
      write(*,*) "Error writing parameter file for SyMBA: " // trim(adjustl(iomsg))
   end subroutine symba_io_param_writer


   module subroutine symba_io_write_discard(self, param)
      !! author: David A. Minton
      !!
      !! Write the metadata of the discarded body to the output file 
      implicit none
      class(symba_nbody_system),  intent(inout) :: self  !! SyMBA nbody system object
      class(swiftest_parameters), intent(inout) :: param !! Current run configuration parameters 
      ! Internals

      associate(pl => self%pl, npl => self%pl%nbody, pl_adds => self%pl_adds)

         if (self%tp_discards%nbody > 0) call self%tp_discards%write_info(param%nciu, param)
         select type(pl_discards => self%pl_discards)
         class is (symba_merger)
            if (pl_discards%nbody == 0) return

            call pl_discards%write_info(param%nciu, param)
         end select
      end associate

      return

   end subroutine symba_io_write_discard

end submodule s_symba_io


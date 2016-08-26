subroutine allocConvArrays(nIterTot)
  !
  !       allocConvArrays allocates the memory for the convergence       
  !       arrays. The number of iterations allocated, nIterTot, is       
  !       enough to store the maximum number of iterations specified     
  !       plus possible earlier iterations read from the restart file.   
  !       This routine MAY be called with data already inside of         
  !       convArray and this will be saved.                              
  !
  use constants
  use inputTimeSpectral, only : nTimeIntervalsSpectral
  use inputIO, only : storeConvInnerIter
  use monitor, only : convArray, nMon
  implicit none
  !
  !      Subroutine argument.
  !
  integer(kind=intType) :: nIterTot
  !
  !      Local variables.
  !
  integer :: ierr

  ! Return immediately if the convergence history (of the inner
  ! iterations) does not need to be stored. This logical can
  ! only be .false. for an unsteady computation.
  if(.not. storeConvInnerIter) return 

  if (allocated(convArray)) then
     deallocate(convArray)
  end if

  allocate(convArray(0:nIterTot, nTimeIntervalsSpectral, nMon))
  
  ! Zero Array:
  convArray = zero

end subroutine allocConvArrays


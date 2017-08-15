!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module aleutils_b
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------

contains
!
!      ******************************************************************
!      *                                                                *
!      * file:          slipvelocities.f90                              *
!      * author:        edwin van der weide                             *
!      * starting date: 02-12-2004                                      *
!      * last modified: 06-28-2005                                      *
!      *                                                                *
!      ******************************************************************
!
  subroutine slipvelocitiesfinelevelale_block(useoldcoor, t, sps)
!
!      ******************************************************************
!      *                                                                *
!      * slipvelocitiesfinelevel computes the slip velocities for       *
!      * viscous subfaces on all viscous boundaries on groundlevel for  *
!      * the given spectral solution. if useoldcoor is .true. the       *
!      * velocities are determined using the unsteady time integrator;  *
!      * otherwise the analytic form is used.                           *
!      *                                                                *
!      * calculates the surface normal and normal velocity on bc using  *
!      * first order bdf.                                               *
!      *                                                                *
!      ******************************************************************
!
    use constants
    use inputtimespectral
    use blockpointers
    use cgnsgrid
    use flowvarrefstate
    use inputmotion
    use inputunsteady
    use iteration
    use inputphysics
    use inputtsstabderiv
    use monitor
    use communication
    use utils_b, only : setcoeftimeintegrator
    implicit none
!
!      subroutine arguments.
!
    integer(kind=inttype), intent(in) :: sps
    logical, intent(in) :: useoldcoor
    real(kind=realtype), dimension(*), intent(in) :: t
!
!      local variables.
!
    integer(kind=inttype) :: nn, mm, i, j, level
    real(kind=realtype) :: oneover4dt
    real(kind=realtype) :: velxgrid, velygrid, velzgrid, ainf
    real(kind=realtype) :: velxgrid0, velygrid0, velzgrid0
    real(kind=realtype), dimension(3) :: xc, xxc
    real(kind=realtype), dimension(3) :: rotcenter, rotrate
    real(kind=realtype), dimension(3) :: rotationpoint
    real(kind=realtype), dimension(3, 3) :: rotationmatrix, &
&   derivrotationmatrix
    real(kind=realtype) :: tnew, told
    real(kind=realtype), dimension(:, :, :), pointer :: uslip
    real(kind=realtype), dimension(:, :, :), pointer :: xface
    real(kind=realtype), dimension(:, :, :, :), pointer :: xfaceold
    real(kind=realtype) :: intervalmach, alphats, alphaincrement, betats&
&   , betaincrement
    real(kind=realtype), dimension(3) :: veldir
    real(kind=realtype), dimension(3) :: refdirection
!function definitions
    real(kind=realtype) :: tsalpha, tsbeta, tsmach
!
!      ******************************************************************
!      *                                                                *
!      * begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! determine the situation we are having here.
! *******************************
! removed the rigid body rotation part for simplicity
! *******************************
! the velocities must be determined via a finite difference
! formula using the coordinates of the old levels.
! set the coefficients for the time integrator and store the
! inverse of the physical nondimensional time step, divided
! by 4, a bit easier.
    call setcoeftimeintegrator()
    oneover4dt = fourth*timeref/deltat
! loop over the number of viscous subfaces.
bocoloop1:do mm=1,nviscbocos
! set the pointer for uslip to make the code more
! readable.
      uslip => bcdata(mm)%uslip
! determine the grid face on which the subface is located
! and set some variables accordingly.
      select case  (bcfaceid(mm))
      case (imin)
        xface => x(1, :, :, :)
        xfaceold => xold(:, 1, :, :, :)
      case (imax)
        xface => x(il, :, :, :)
        xfaceold => xold(:, il, :, :, :)
      case (jmin)
        xface => x(:, 1, :, :)
        xfaceold => xold(:, :, 1, :, :)
      case (jmax)
        xface => x(:, jl, :, :)
        xfaceold => xold(:, :, jl, :, :)
      case (kmin)
        xface => x(:, :, 1, :)
        xfaceold => xold(:, :, :, 1, :)
      case (kmax)
        xface => x(:, :, kl, :)
        xfaceold => xold(:, :, :, kl, :)
      end select
! some boundary faces have a different rotation speed than
! the corresponding block. this happens e.g. in the tip gap
! region of turbomachinary problems where the casing does
! not rotate. as the coordinate difference corresponds to
! the rotation rate of the block, a correction must be
! computed. therefore compute the difference in rotation
! rate and store the rotation center a bit easier. note that
! the rotation center of subface is taken, because if there
! is a difference in rotation rate this info for the subface
! must always be specified.
      j = nbkglobal
      i = cgnssubface(mm)
! loop over the quadrilateral faces of the viscous subface.
! note that due to the usage of the pointers xface and
! xfaceold an offset of +1 must be used in the coordinate
! arrays, because x and xold originally start at 0 for the
! i, j and k indices.
      do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
        do i=bcdata(mm)%icbeg,bcdata(mm)%icend
! determine the coordinates of the centroid of the
! face, multiplied by 4.
          uslip(i, j, 1) = xface(i+1, j+1, 1) + xface(i+1, j, 1) + xface&
&           (i, j+1, 1) + xface(i, j, 1)
          uslip(i, j, 2) = xface(i+1, j+1, 2) + xface(i+1, j, 2) + xface&
&           (i, j+1, 2) + xface(i, j, 2)
          uslip(i, j, 3) = xface(i+1, j+1, 3) + xface(i+1, j, 3) + xface&
&           (i, j+1, 3) + xface(i, j, 3)
! loop over the older time levels and take their
! contribution into account.
! there was a loop over all old levels
          level = 1
          uslip(i, j, 1) = uslip(i, j, 1) + (xfaceold(level, i+1, j+1, 1&
&           )+xfaceold(level, i+1, j, 1)+xfaceold(level, i, j+1, 1)+&
&           xfaceold(level, i, j, 1))*(-1.0_realtype)
          uslip(i, j, 2) = uslip(i, j, 2) + (xfaceold(level, i+1, j+1, 2&
&           )+xfaceold(level, i+1, j, 2)+xfaceold(level, i, j+1, 2)+&
&           xfaceold(level, i, j, 2))*(-1.0_realtype)
          uslip(i, j, 3) = uslip(i, j, 3) + (xfaceold(level, i+1, j+1, 3&
&           )+xfaceold(level, i+1, j, 3)+xfaceold(level, i, j+1, 3)+&
&           xfaceold(level, i, j, 3))*(-1.0_realtype)
! divide by 4 times the time step to obtain the
! correct velocity.
          uslip(i, j, 1) = uslip(i, j, 1)*oneover4dt
          uslip(i, j, 2) = uslip(i, j, 2)*oneover4dt
          uslip(i, j, 3) = uslip(i, j, 3)*oneover4dt
        end do
      end do
    end do bocoloop1
  end subroutine slipvelocitiesfinelevelale_block
! ===========================================================
  subroutine interplevelale_block()
!
!      ******************************************************************
!      *                                                                *
!      * interplevelale_block interpolates geometric data over the      *
!      * latest time step.                                              *
!      *                                                                *
!      ******************************************************************
!
    use blockpointers
    use iteration
    use inputunsteady
    use inputphysics
    implicit none
!
!      local variables.
!
    integer(kind=inttype) :: i, j, k, l, nn, mm, kk
    if ((.not.useale) .or. equationmode .ne. unsteady) then
      return
    else
! --------------------------------
! first store then clear current data
! --------------------------------
cleari:do k=1,ke
        do j=1,je
          do i=0,ie
            sfaceiale(0, i, j, k) = sfacei(i, j, k)
            siale(0, i, j, k, 1) = si(i, j, k, 1)
            siale(0, i, j, k, 2) = si(i, j, k, 2)
            siale(0, i, j, k, 3) = si(i, j, k, 3)
            sfacei(i, j, k) = zero
            si(i, j, k, 1) = zero
            si(i, j, k, 2) = zero
            si(i, j, k, 3) = zero
          end do
        end do
      end do cleari
clearj:do k=1,ke
        do j=0,je
          do i=1,ie
            sfacejale(0, i, j, k) = sfacej(i, j, k)
            sjale(0, i, j, k, 1) = sj(i, j, k, 1)
            sjale(0, i, j, k, 2) = sj(i, j, k, 2)
            sjale(0, i, j, k, 3) = sj(i, j, k, 3)
            sfacej(i, j, k) = zero
            sj(i, j, k, 1) = zero
            sj(i, j, k, 2) = zero
            sj(i, j, k, 3) = zero
          end do
        end do
      end do clearj
cleark:do k=0,ke
        do j=1,je
          do i=1,ie
            sfacekale(0, i, j, k) = sfacek(i, j, k)
            skale(0, i, j, k, 1) = sk(i, j, k, 1)
            skale(0, i, j, k, 2) = sk(i, j, k, 2)
            skale(0, i, j, k, 3) = sk(i, j, k, 3)
            sfacek(i, j, k) = zero
            sk(i, j, k, 1) = zero
            sk(i, j, k, 2) = zero
            sk(i, j, k, 3) = zero
          end do
        end do
      end do cleark
aleloop:do l=1,nalesteps
! --------------------------------
! then average surface normal and normal velocity from array of old variables
! this eq. 10a and 10b, found paper by c.farhat http://dx.doi.org/10.1016/s0021-9991(03)00311-5
! --------------------------------
updatei:do k=1,ke
          do j=1,je
            do i=0,ie
              sfacei(i, j, k) = sfacei(i, j, k) + coeftimeale(l)*&
&               sfaceiale(l, i, j, k)
              si(i, j, k, 1) = si(i, j, k, 1) + coeftimeale(l)*siale(l, &
&               i, j, k, 1)
              si(i, j, k, 2) = si(i, j, k, 2) + coeftimeale(l)*siale(l, &
&               i, j, k, 2)
              si(i, j, k, 3) = si(i, j, k, 3) + coeftimeale(l)*siale(l, &
&               i, j, k, 3)
            end do
          end do
        end do updatei
updatej:do k=1,ke
          do j=0,je
            do i=1,ie
              sfacej(i, j, k) = sfacej(i, j, k) + coeftimeale(l)*&
&               sfacejale(l, i, j, k)
              sj(i, j, k, 1) = sj(i, j, k, 1) + coeftimeale(l)*sjale(l, &
&               i, j, k, 1)
              sj(i, j, k, 2) = sj(i, j, k, 2) + coeftimeale(l)*sjale(l, &
&               i, j, k, 2)
              sj(i, j, k, 3) = sj(i, j, k, 3) + coeftimeale(l)*sjale(l, &
&               i, j, k, 3)
            end do
          end do
        end do updatej
updatek:do k=0,ke
          do j=1,je
            do i=1,ie
              sfacek(i, j, k) = sfacek(i, j, k) + coeftimeale(l)*&
&               sfacekale(l, i, j, k)
              sk(i, j, k, 1) = sk(i, j, k, 1) + coeftimeale(l)*skale(l, &
&               i, j, k, 1)
              sk(i, j, k, 2) = sk(i, j, k, 2) + coeftimeale(l)*skale(l, &
&               i, j, k, 2)
              sk(i, j, k, 3) = sk(i, j, k, 3) + coeftimeale(l)*skale(l, &
&               i, j, k, 3)
            end do
          end do
        end do updatek
      end do aleloop
    end if
  end subroutine interplevelale_block
! ===========================================================
  subroutine recoverlevelale_block()
!
!      ******************************************************************
!      *                                                                *
!      * recoverlevelale_block recovers current geometric data from     *
!      * temporary interpolation                                        *
!      *                                                                *
!      ******************************************************************
!
    use blockpointers
    use inputunsteady
    use inputphysics
    implicit none
!
!      local variables.
!
    integer(kind=inttype) :: i, j, k, nn, mm, kk
    if ((.not.useale) .or. equationmode .ne. unsteady) then
      return
    else
recoveri:do k=1,ke
        do j=1,je
          do i=0,ie
            sfacei(i, j, k) = sfaceiale(0, i, j, k)
            si(i, j, k, 1) = siale(0, i, j, k, 1)
            si(i, j, k, 2) = siale(0, i, j, k, 2)
            si(i, j, k, 3) = siale(0, i, j, k, 3)
          end do
        end do
      end do recoveri
recoverj:do k=1,ke
        do j=0,je
          do i=1,ie
            sfacej(i, j, k) = sfacejale(0, i, j, k)
            sj(i, j, k, 1) = sjale(0, i, j, k, 1)
            sj(i, j, k, 2) = sjale(0, i, j, k, 2)
            sj(i, j, k, 3) = sjale(0, i, j, k, 3)
          end do
        end do
      end do recoverj
recoverk:do k=0,ke
        do j=1,je
          do i=1,ie
            sfacek(i, j, k) = sfacekale(0, i, j, k)
            sk(i, j, k, 1) = skale(0, i, j, k, 1)
            sk(i, j, k, 2) = skale(0, i, j, k, 2)
            sk(i, j, k, 3) = skale(0, i, j, k, 3)
          end do
        end do
      end do recoverk
    end if
  end subroutine recoverlevelale_block
! ===========================================================
  subroutine interplevelalebc_block()
!
!      ******************************************************************
!      *                                                                *
!      * interplevelalebc_block interpolates geometric data on boundary *
!      * over the latest time step.                                     *
!      *                                                                *
!      ******************************************************************
!
    use blockpointers
    use iteration
    use inputunsteady
    use inputphysics
    implicit none
!
!      local variables.
!
    integer(kind=inttype) :: i, j, k, l, nn, mm, kk
    intrinsic associated
    if ((.not.useale) .or. equationmode .ne. unsteady) then
      return
    else
! --------------------------------
! first store then clear current data
! --------------------------------
clearnm:do mm=1,nbocos
        do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
          do i=bcdata(mm)%icbeg,bcdata(mm)%icend
            bcdata(mm)%normale(0, i, j, 1) = bcdata(mm)%norm(i, j, 1)
            bcdata(mm)%normale(0, i, j, 2) = bcdata(mm)%norm(i, j, 2)
            bcdata(mm)%normale(0, i, j, 3) = bcdata(mm)%norm(i, j, 3)
            bcdata(mm)%norm(i, j, 1) = zero
            bcdata(mm)%norm(i, j, 2) = zero
            bcdata(mm)%norm(i, j, 3) = zero
          end do
        end do
      end do clearnm
clearrf:do mm=1,nbocos
        if (associated(bcdata(mm)%rface)) then
          do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
            do i=bcdata(mm)%icbeg,bcdata(mm)%icend
              bcdata(mm)%rfaceale(0, i, j) = bcdata(mm)%rface(i, j)
              bcdata(mm)%rface(i, j) = zero
            end do
          end do
        end if
      end do clearrf
clearus:do mm=1,nviscbocos
        do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
          do i=bcdata(mm)%icbeg,bcdata(mm)%icend
            bcdata(mm)%uslipale(0, i, j, 1) = bcdata(mm)%uslip(i, j, 1)
            bcdata(mm)%uslipale(0, i, j, 2) = bcdata(mm)%uslip(i, j, 2)
            bcdata(mm)%uslipale(0, i, j, 3) = bcdata(mm)%uslip(i, j, 3)
            bcdata(mm)%uslip(i, j, 1) = zero
            bcdata(mm)%uslip(i, j, 2) = zero
            bcdata(mm)%uslip(i, j, 3) = zero
          end do
        end do
      end do clearus
aleloop:do l=1,nalesteps
! --------------------------------
! then average surface normal and normal velocity from array of old variables
! --------------------------------
updatenm:do mm=1,nbocos
          do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
            do i=bcdata(mm)%icbeg,bcdata(mm)%icend
              bcdata(mm)%norm(i, j, 1) = bcdata(mm)%norm(i, j, 1) + &
&               coeftimeale(l)*bcdata(mm)%normale(l, i, j, 1)
              bcdata(mm)%norm(i, j, 2) = bcdata(mm)%norm(i, j, 2) + &
&               coeftimeale(l)*bcdata(mm)%normale(l, i, j, 2)
              bcdata(mm)%norm(i, j, 3) = bcdata(mm)%norm(i, j, 3) + &
&               coeftimeale(l)*bcdata(mm)%normale(l, i, j, 3)
            end do
          end do
        end do updatenm
updaterf:do mm=1,nbocos
          if (associated(bcdata(mm)%rface)) then
            do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
              do i=bcdata(mm)%icbeg,bcdata(mm)%icend
                bcdata(mm)%rface(i, j) = bcdata(mm)%rface(i, j) + &
&                 coeftimeale(l)*bcdata(mm)%rfaceale(0, i, j)
              end do
            end do
          end if
        end do updaterf
updateus:do mm=1,nviscbocos
          do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
            do i=bcdata(mm)%icbeg,bcdata(mm)%icend
              bcdata(mm)%uslip(i, j, 1) = bcdata(mm)%uslip(i, j, 1) + &
&               coeftimeale(l)*bcdata(mm)%uslipale(l, i, j, 1)
              bcdata(mm)%uslip(i, j, 2) = bcdata(mm)%uslip(i, j, 2) + &
&               coeftimeale(l)*bcdata(mm)%uslipale(l, i, j, 2)
              bcdata(mm)%uslip(i, j, 3) = bcdata(mm)%uslip(i, j, 3) + &
&               coeftimeale(l)*bcdata(mm)%uslipale(l, i, j, 3)
            end do
          end do
        end do updateus
      end do aleloop
    end if
  end subroutine interplevelalebc_block
! ===========================================================
  subroutine recoverlevelalebc_block()
!
!      ******************************************************************
!      *                                                                *
!      * recoverlevelalebc_block recovers current geometric data on     *
!      * boundary from temporary interpolation                          *
!      *                                                                *
!      ******************************************************************
!
    use blockpointers
    use inputunsteady
    use inputphysics
    implicit none
!
!      local variables.
!
    integer(kind=inttype) :: i, j, k, nn, mm, kk
    intrinsic associated
    if ((.not.useale) .or. equationmode .ne. unsteady) then
      return
    else
recovernm:do mm=1,nbocos
        do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
          do i=bcdata(mm)%icbeg,bcdata(mm)%icend
            bcdata(mm)%norm(i, j, 1) = bcdata(mm)%normale(0, i, j, 1)
            bcdata(mm)%norm(i, j, 2) = bcdata(mm)%normale(0, i, j, 2)
            bcdata(mm)%norm(i, j, 3) = bcdata(mm)%normale(0, i, j, 3)
          end do
        end do
      end do recovernm
recoverrf:do mm=1,nbocos
        if (associated(bcdata(mm)%rface)) then
          do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
            do i=bcdata(mm)%icbeg,bcdata(mm)%icend
              bcdata(mm)%rface(i, j) = bcdata(mm)%rfaceale(0, i, j)
            end do
          end do
        end if
      end do recoverrf
recoverus:do mm=1,nviscbocos
        do j=bcdata(mm)%jcbeg,bcdata(mm)%jcend
          do i=bcdata(mm)%icbeg,bcdata(mm)%icend
            bcdata(mm)%uslip(i, j, 1) = bcdata(mm)%uslipale(0, i, j, 1)
            bcdata(mm)%uslip(i, j, 2) = bcdata(mm)%uslipale(0, i, j, 2)
            bcdata(mm)%uslip(i, j, 3) = bcdata(mm)%uslipale(0, i, j, 3)
          end do
        end do
      end do recoverus
    end if
  end subroutine recoverlevelalebc_block
end module aleutils_b

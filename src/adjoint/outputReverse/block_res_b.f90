!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of block_res in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: *xx *rev0 *rev1 *rev2 *rev3
!                *pp0 *pp1 *pp2 *pp3 *rlv0 *rlv1 *rlv2 *rlv3 *ssi
!                *ww0 *ww1 *ww2 *ww3 *(flowdoms.x) *(flowdoms.w)
!                *(flowdoms.dw) *(*bcdata.fv) *(*bcdata.fp) *(*bcdata.area)
!                funcvalues
!   with respect to varying inputs: tinfdim rhoinfdim pinfdim *xx
!                *rev0 *rev1 *rev2 *rev3 *pp0 *pp1 *pp2 *pp3 *rlv0
!                *rlv1 *rlv2 *rlv3 *ssi *ww0 *ww1 *ww2 *ww3 mach
!                machgrid rgasdim lengthref machcoef pointref *(flowdoms.x)
!                *(flowdoms.w) *(flowdoms.dw) *(*bcdata.fv) *(*bcdata.fp)
!                *(*bcdata.area) *xsurf funcvalues alpha beta
!   rw status of diff variables: gammainf:(loc) tinfdim:out pinf:(loc)
!                timeref:(loc) rhoinf:(loc) muref:(loc) rhoinfdim:out
!                tref:(loc) winf:(loc) muinf:(loc) uinf:(loc) pinfcorr:(loc)
!                rgas:(loc) muinfdim:(loc) pinfdim:out pref:(loc)
!                rhoref:(loc) *xx:in-out *rev0:in-out *rev1:in-out
!                *rev2:in-out *rev3:in-out *pp0:in-out *pp1:in-out
!                *pp2:in-out *pp3:in-out *rlv0:in-out *rlv1:in-out
!                *rlv2:in-out *rlv3:in-out *ssi:in-out *ww0:in-out
!                *ww1:in-out *ww2:in-out *ww3:in-out mach:out veldirfreestream:(loc)
!                machgrid:out rgasdim:out lengthref:out machcoef:out
!                dragdirection:(loc) liftdirection:(loc) pointref:out
!                *(flowdoms.x):in-out *(flowdoms.vol):(loc) *(flowdoms.w):in-out
!                *(flowdoms.dw):in-out *rev:(loc) *aa:(loc) *bvtj1:(loc)
!                *bvtj2:(loc) *wx:(loc) *wy:(loc) *wz:(loc) *p:(loc)
!                *rlv:(loc) *qx:(loc) *qy:(loc) *qz:(loc) *scratch:(loc)
!                *bvtk1:(loc) *bvtk2:(loc) *ux:(loc) *uy:(loc)
!                *uz:(loc) *d2wall:(loc) *si:(loc) *sj:(loc) *sk:(loc)
!                *bvti1:(loc) *bvti2:(loc) *vx:(loc) *vy:(loc)
!                *vz:(loc) *fw:(loc) *(*viscsubface.tau):(loc)
!                *(*bcdata.norm):(loc) *(*bcdata.fv):in-out *(*bcdata.fp):in-out
!                *(*bcdata.area):in-out *radi:(loc) *radj:(loc)
!                *radk:(loc) *xsurf:out funcvalues:in-zero alpha:out
!                beta:out
!   plus diff mem management of: xx:in rev0:in rev1:in rev2:in
!                rev3:in pp0:in pp1:in pp2:in pp3:in rlv0:in rlv1:in
!                rlv2:in rlv3:in ssi:in ww0:in ww1:in ww2:in ww3:in
!                flowdoms.x:in flowdoms.vol:in flowdoms.w:in flowdoms.dw:in
!                rev:in aa:in bvtj1:in bvtj2:in wx:in wy:in wz:in
!                p:in rlv:in qx:in qy:in qz:in scratch:in bvtk1:in
!                bvtk2:in ux:in uy:in uz:in d2wall:in si:in sj:in
!                sk:in bvti1:in bvti2:in vx:in vy:in vz:in fw:in
!                viscsubface:in *viscsubface.tau:in bcdata:in *bcdata.norm:in
!                *bcdata.fv:in *bcdata.fp:in *bcdata.area:in radi:in
!                radj:in radk:in xsurf:in
! this is a super-combined function that combines the original
! functionality of: 
! pressure computation
! timestep
! applyallbcs
! initres
! residual 
! the real difference between this and the original modules is that it
! it only operates on a single block at a time and as such the nominal
! block/sps loop is outside the calculation. this routine is suitable
! for forward mode ad with tapenade
subroutine block_res_b(nn, sps, usespatial, alpha, alphad, beta, betad, &
& liftindex, frozenturb)
! note that we import all the pointers from block res that will be
! used in any routine. otherwise, tapenade gives warnings about
! saving a hidden variable. 
  use constants
  use block, only : flowdoms, flowdomsd
  use bcroutines_b
  use bcpointers_b
  use blockpointers, only : w, wd, dw, dwd, x, xd, vol, vold, il, jl, &
& kl, sectionid, wold, volold, bcdata, bcdatad, si, sid, sj, sjd, sk, &
& skd, sfacei, sfacej, sfacek, rlv, rlvd, gamma, p, pd, rev, revd, bmtj1&
& , bmtj2, scratch, scratchd, bmtk2, bmtk1, fw, fwd, aa, aad, d2wall, &
& d2walld, bmti1, bmti2, s
  use flowvarrefstate
  use inputphysics
  use inputiteration
  use inputtimespectral
  use section
  use monitor
  use iteration
  use diffsizes
  use costfunctions
  use initializeflow_b, only : referencestate, referencestate_b
  use walldistance_b, only : updatewalldistancesquickly, &
& updatewalldistancesquickly_b, xsurf, xsurfd
  use inputdiscretization
  use sa_b
  use inputunsteady
  use turbbcroutines_b
  use turbutils_b
  use utils_b, only : terminate
  implicit none
! input arguments:
  integer(kind=inttype), intent(in) :: nn, sps
  logical, intent(in) :: usespatial, frozenturb
  real(kind=realtype), intent(in) :: alpha, beta
  real(kind=realtype) :: alphad, betad
  integer(kind=inttype), intent(in) :: liftindex
! output variables
  real(kind=realtype), dimension(3, ntimeintervalsspectral) :: force, &
& moment
  real(kind=realtype), dimension(3, ntimeintervalsspectral) :: forced, &
& momentd
  real(kind=realtype) :: sepsensor, cavitation, sepsensoravg(3)
  real(kind=realtype) :: sepsensord, cavitationd, sepsensoravgd(3)
! working variables
  real(kind=realtype) :: gm1, v2, fact, tmp
  real(kind=realtype) :: factd, tmpd
  integer(kind=inttype) :: i, j, k, sps2, mm, l, ii, ll, jj, m
  integer(kind=inttype) :: nstate
  real(kind=realtype), dimension(nsections) :: t
  logical :: useoldcoor
  real(kind=realtype), dimension(3) :: cfp, cfv, cmp, cmv
  real(kind=realtype), dimension(3) :: cfpd, cfvd, cmpd, cmvd
  real(kind=realtype) :: yplusmax, scaledim, oneoverdt
  real(kind=realtype) :: scaledimd, oneoverdtd
  integer :: branch
  real(kind=realtype) :: temp3
  real(kind=realtype) :: temp2
  real(kind=realtype) :: temp1
  real(kind=realtype) :: temp0
  real(kind=realtype) :: tempd
  real(kind=realtype) :: tempd6(3)
  real(kind=realtype) :: tempd5
  real(kind=realtype) :: tempd4(3)
  real(kind=realtype) :: tempd3
  real(kind=realtype) :: tempd2
  real(kind=realtype) :: tempd1
  real(kind=realtype) :: tempd0
  integer :: ii3
  integer :: ii2
  integer :: ii1
  real(kind=realtype) :: temp
! setup number of state variable based on turbulence assumption
  if (frozenturb) then
    nstate = nwf
  else
    nstate = nw
  end if
! set pointers to input/output variables
  wd => flowdomsd(nn, currentlevel, sps)%w
  w => flowdoms(nn, currentlevel, sps)%w
  dwd => flowdomsd(nn, 1, sps)%dw
  dw => flowdoms(nn, 1, sps)%dw
  xd => flowdomsd(nn, currentlevel, sps)%x
  x => flowdoms(nn, currentlevel, sps)%x
  vold => flowdomsd(nn, currentlevel, sps)%vol
  vol => flowdoms(nn, currentlevel, sps)%vol
! ------------------------------------------------
!        additional 'extra' components
! ------------------------------------------------ 
  call adjustinflowangle(alpha, beta, liftindex)
  call pushreal8(gammainf)
  call referencestate()
! ------------------------------------------------
!        additional spatial components
! ------------------------------------------------
  if (usespatial) then
    call volume_block()
    call metric_block()
    call boundarynormals()
    if (equations .eq. ransequations .and. useapproxwalldistance) then
      call updatewalldistancesquickly(nn, 1, sps)
      call pushcontrol2b(0)
    else
      call pushcontrol2b(1)
    end if
  else
    call pushcontrol2b(2)
  end if
! ------------------------------------------------
!        normal residual computation
! ------------------------------------------------
! compute the pressures
  call pushreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call computepressuresimple()
! compute laminar/eddy viscosity if required
  call computelamviscosity()
  call computeeddyviscosity()
  call pushreal8array(sk, size(sk, 1)*size(sk, 2)*size(sk, 3)*size(sk, 4&
&               ))
  call pushreal8array(sj, size(sj, 1)*size(sj, 2)*size(sj, 3)*size(sj, 4&
&               ))
  call pushreal8array(si, size(si, 1)*size(si, 2)*size(si, 3)*size(si, 4&
&               ))
  call pushreal8array(rlv, size(rlv, 1)*size(rlv, 2)*size(rlv, 3))
  call pushreal8array(gamma, size(gamma, 1)*size(gamma, 2)*size(gamma, 3&
&               ))
  call pushreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call pushreal8array(rev, size(rev, 1)*size(rev, 2)*size(rev, 3))
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                     , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, &
&                     2)*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%x, size(flowdoms(ii3&
&                     , ii2, ii1)%x, 1)*size(flowdoms(ii3, ii2, ii1)%x, &
&                     2)*size(flowdoms(ii3, ii2, ii1)%x, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%x, 4))
      end do
    end do
  end do
  call pushreal8array(ww3, size(ww3, 1)*size(ww3, 2)*size(ww3, 3))
  call pushreal8array(ww2, size(ww2, 1)*size(ww2, 2)*size(ww2, 3))
  call pushreal8array(ww1, size(ww1, 1)*size(ww1, 2)*size(ww1, 3))
  call pushreal8array(ww0, size(ww0, 1)*size(ww0, 2)*size(ww0, 3))
  call pushreal8array(ssi, size(ssi, 1)*size(ssi, 2)*size(ssi, 3))
  call pushreal8array(rlv3, size(rlv3, 1)*size(rlv3, 2))
  call pushreal8array(rlv2, size(rlv2, 1)*size(rlv2, 2))
  call pushreal8array(rlv1, size(rlv1, 1)*size(rlv1, 2))
  call pushreal8array(rlv0, size(rlv0, 1)*size(rlv0, 2))
  call pushreal8array(pp3, size(pp3, 1)*size(pp3, 2))
  call pushreal8array(pp2, size(pp2, 1)*size(pp2, 2))
  call pushreal8array(pp1, size(pp1, 1)*size(pp1, 2))
  call pushreal8array(pp0, size(pp0, 1)*size(pp0, 2))
  call pushreal8array(rev3, size(rev3, 1)*size(rev3, 2))
  call pushreal8array(rev2, size(rev2, 1)*size(rev2, 2))
  call pushreal8array(rev1, size(rev1, 1)*size(rev1, 2))
  call pushreal8array(rev0, size(rev0, 1)*size(rev0, 2))
  call pushreal8array(xx, size(xx, 1)*size(xx, 2)*size(xx, 3))
  call pushreal8array(gamma3, size(gamma3, 1)*size(gamma3, 2))
  call pushreal8array(gamma2, size(gamma2, 1)*size(gamma2, 2))
  call pushreal8array(gamma1, size(gamma1, 1)*size(gamma1, 2))
  call pushreal8array(gamma0, size(gamma0, 1)*size(gamma0, 2))
  call applyallbc_block(.true.)
  if (equations .eq. ransequations) then
    call bcturbtreatment()
    do ii1=1,ntimeintervalsspectral
      do ii2=1,1
        do ii3=nn,nn
          call pushreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(&
&                       ii3, ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1&
&                       )%w, 2)*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(&
&                       flowdoms(ii3, ii2, ii1)%w, 4))
        end do
      end do
    end do
    call applyallturbbcthisblock(.true.)
    call pushcontrol1b(0)
  else
    call pushcontrol1b(1)
  end if
! compute skin_friction velocity (only for wall functions)
! #ifndef 1
!   call computeutau_block
! #endif
! compute time step and spectral radius
  call timestep_block(.false.)
spectralloop0:do sps2=1,ntimeintervalsspectral
    flowdoms(nn, 1, sps2)%dw(:, :, :, :) = zero
  end do spectralloop0
! -------------------------------
! compute turbulence residual for rans equations
  if (equations .eq. ransequations) then
! ! initialize only the turblent variables
! call unsteadyturbspectral_block(itu1, itu1, nn, sps)
    select case  (turbmodel) 
    case (spalartallmaras) 
      call pushreal8array(bmtj2, size(bmtj2, 1)*size(bmtj2, 2)*size(&
&                   bmtj2, 3)*size(bmtj2, 4))
      call pushreal8array(bmtj1, size(bmtj1, 1)*size(bmtj1, 2)*size(&
&                   bmtj1, 3)*size(bmtj1, 4))
      call pushreal8array(bmti2, size(bmti2, 1)*size(bmti2, 2)*size(&
&                   bmti2, 3)*size(bmti2, 4))
      call pushreal8array(bmti1, size(bmti1, 1)*size(bmti1, 2)*size(&
&                   bmti1, 3)*size(bmti1, 4))
      call pushreal8array(scratch, size(scratch, 1)*size(scratch, 2)*&
&                   size(scratch, 3)*size(scratch, 4))
      call pushreal8array(bmtk2, size(bmtk2, 1)*size(bmtk2, 2)*size(&
&                   bmtk2, 3)*size(bmtk2, 4))
      call pushreal8array(bmtk1, size(bmtk1, 1)*size(bmtk1, 2)*size(&
&                   bmtk1, 3)*size(bmtk1, 4))
      do ii1=1,ntimeintervalsspectral
        do ii2=1,1
          do ii3=nn,nn
            call pushreal8array(flowdoms(ii3, ii2, ii1)%dw, size(&
&                         flowdoms(ii3, ii2, ii1)%dw, 1)*size(flowdoms(&
&                         ii3, ii2, ii1)%dw, 2)*size(flowdoms(ii3, ii2, &
&                         ii1)%dw, 3)*size(flowdoms(ii3, ii2, ii1)%dw, 4&
&                         ))
          end do
        end do
      end do
      call sa_block(.true.)
      call pushcontrol2b(0)
    case default
      call pushcontrol2b(1)
    end select
  else
    call pushcontrol2b(2)
  end if
! -------------------------------  
! next initialize residual for flow variables. the is the only place
! where there is an n^2 dependance. there are issues with
! initres. so only the necesary timespectral code has been copied
! here. see initres for more information and comments.
!call initres_block(1, nwf, nn, sps)
  if (equationmode .eq. steady) then
    dw(:, :, :, 1:nwf) = zero
    call pushcontrol2b(0)
  else if (equationmode .eq. timespectral) then
! zero dw on all spectral instances
spectralloop1:do sps2=1,ntimeintervalsspectral
      flowdoms(nn, 1, sps2)%dw(:, :, :, 1:nwf) = zero
    end do spectralloop1
spectralloop2:do sps2=1,ntimeintervalsspectral
      call pushinteger4(jj)
      jj = sectionid
timeloopfine:do mm=1,ntimeintervalsspectral
        call pushinteger4(ii)
        ii = 3*(mm-1)
varloopfine:do l=1,nwf
          if ((l .eq. ivx .or. l .eq. ivy) .or. l .eq. ivz) then
            if (l .eq. ivx) then
              call pushinteger4(ll)
              ll = 3*sps2 - 2
              call pushcontrol1b(0)
            else
              call pushcontrol1b(1)
            end if
            if (l .eq. ivy) then
              call pushinteger4(ll)
              ll = 3*sps2 - 1
              call pushcontrol1b(0)
            else
              call pushcontrol1b(1)
            end if
            if (l .eq. ivz) then
              call pushinteger4(ll)
              ll = 3*sps2
              call pushcontrol1b(1)
            else
              call pushcontrol1b(0)
            end if
            do k=2,kl
              do j=2,jl
                do i=2,il
                  call pushreal8(tmp)
                  tmp = dvector(jj, ll, ii+1)*flowdoms(nn, 1, mm)%w(i, j&
&                   , k, ivx) + dvector(jj, ll, ii+2)*flowdoms(nn, 1, mm&
&                   )%w(i, j, k, ivy) + dvector(jj, ll, ii+3)*flowdoms(&
&                   nn, 1, mm)%w(i, j, k, ivz)
                  flowdoms(nn, 1, sps2)%dw(i, j, k, l) = flowdoms(nn, 1&
&                   , sps2)%dw(i, j, k, l) + tmp*flowdoms(nn, 1, mm)%vol&
&                   (i, j, k)*flowdoms(nn, 1, mm)%w(i, j, k, irho)
                end do
              end do
            end do
            call pushcontrol1b(1)
          else
            do k=2,kl
              do j=2,jl
                do i=2,il
! this is: dw = dw + dscalar*vol*w
                  flowdoms(nn, 1, sps2)%dw(i, j, k, l) = flowdoms(nn, 1&
&                   , sps2)%dw(i, j, k, l) + dscalar(jj, sps2, mm)*&
&                   flowdoms(nn, 1, mm)%vol(i, j, k)*flowdoms(nn, 1, mm)&
&                   %w(i, j, k, l)
                end do
              end do
            end do
            call pushcontrol1b(0)
          end if
        end do varloopfine
      end do timeloopfine
    end do spectralloop2
    call pushcontrol2b(1)
  else if (equationmode .eq. unsteady) then
! assume only md or bdf types
! store the inverse of the physical nondimensional
! time step a bit easier.
    oneoverdt = timeref/deltat
! ground level of the multigrid cycle. initialize the
! owned cells to the unsteady source term. first the
! term for the current time level. note that in w the
! velocities are stored and not the momentum variables.
! therefore the if-statement is present to correct this.
    do l=1,nw
      if ((l .eq. ivx .or. l .eq. ivy) .or. l .eq. ivz) then
! momentum variables.
        do k=2,kl
          do j=2,jl
            do i=2,il
              flowdoms(nn, 1, sps)%dw(i, j, k, l) = coeftime(0)*vol(i, j&
&               , k)*w(i, j, k, l)*w(i, j, k, irho)
            end do
          end do
        end do
        call pushcontrol1b(1)
      else
! non-momentum variables, for which the variable
! to be solved is stored; for the flow equations this
! is the conservative variable, for the turbulent
! equations the primitive variable.
        do k=2,kl
          do j=2,jl
            do i=2,il
              flowdoms(nn, 1, sps)%dw(i, j, k, l) = coeftime(0)*vol(i, j&
&               , k)*w(i, j, k, l)
            end do
          end do
        end do
        call pushcontrol1b(0)
      end if
    end do
! the terms from the older time levels. here the
! conservative variables are stored. in case of a
! deforming mesh, also the old volumes must be taken.
    if (deforming_grid) then
      call pushcontrol1b(1)
! mesh is deforming and thus the volumes can change.
! use the old volumes as well.
      do m=1,noldlevels
        do l=1,nw
          do k=2,kl
            do j=2,jl
              do i=2,il
                flowdoms(nn, 1, sps)%dw(i, j, k, l) = flowdoms(nn, 1, &
&                 sps)%dw(i, j, k, l) + coeftime(m)*volold(m, i, j, k)*&
&                 wold(m, i, j, k, l)
              end do
            end do
          end do
        end do
      end do
    else
! rigid mesh. the volumes remain constant.
      do m=1,noldlevels
        do l=1,nw
          do k=2,kl
            do j=2,jl
              do i=2,il
                flowdoms(nn, 1, sps)%dw(i, j, k, l) = flowdoms(nn, 1, &
&                 sps)%dw(i, j, k, l) + coeftime(m)*vol(i, j, k)*wold(m&
&                 , i, j, k, l)
              end do
            end do
          end do
        end do
      end do
      call pushcontrol1b(0)
    end if
! multiply the time derivative by the inverse of the
! time step to obtain the true time derivative.
! this is done after the summation has been done, because
! otherwise you run into finite accuracy problems for
! very small time steps.
    do l=1,nw
      do k=2,kl
        do j=2,jl
          do i=2,il
            call pushreal8(flowdoms(nn, 1, sps)%dw(i, j, k, l))
            flowdoms(nn, 1, sps)%dw(i, j, k, l) = oneoverdt*flowdoms(nn&
&             , 1, sps)%dw(i, j, k, l)
          end do
        end do
      end do
    end do
    call pushcontrol2b(2)
  else
    call pushcontrol2b(3)
  end if
!  actual residual calc
  call pushreal8array(fw, size(fw, 1)*size(fw, 2)*size(fw, 3)*size(fw, 4&
&               ))
  call pushreal8array(aa, size(aa, 1)*size(aa, 2)*size(aa, 3))
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%dw, size(flowdoms(&
&                     ii3, ii2, ii1)%dw, 1)*size(flowdoms(ii3, ii2, ii1)&
&                     %dw, 2)*size(flowdoms(ii3, ii2, ii1)%dw, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%dw, 4))
      end do
    end do
  end do
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                     , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, &
&                     2)*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  call residual_block()
  call pushreal8array(sk, size(sk, 1)*size(sk, 2)*size(sk, 3)*size(sk, 4&
&               ))
  call pushreal8array(sj, size(sj, 1)*size(sj, 2)*size(sj, 3)*size(sj, 4&
&               ))
  call pushreal8array(si, size(si, 1)*size(si, 2)*size(si, 3)*size(si, 4&
&               ))
  call pushreal8array(rlv, size(rlv, 1)*size(rlv, 2)*size(rlv, 3))
  call pushreal8array(gamma, size(gamma, 1)*size(gamma, 2)*size(gamma, 3&
&               ))
  call pushreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call pushreal8array(rev, size(rev, 1)*size(rev, 2)*size(rev, 3))
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                     , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, &
&                     2)*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  do ii1=1,ntimeintervalsspectral
    do ii2=1,1
      do ii3=nn,nn
        call pushreal8array(flowdoms(ii3, ii2, ii1)%x, size(flowdoms(ii3&
&                     , ii2, ii1)%x, 1)*size(flowdoms(ii3, ii2, ii1)%x, &
&                     2)*size(flowdoms(ii3, ii2, ii1)%x, 3)*size(&
&                     flowdoms(ii3, ii2, ii1)%x, 4))
      end do
    end do
  end do
  call pushreal8array(ww3, size(ww3, 1)*size(ww3, 2)*size(ww3, 3))
  call pushreal8array(ww2, size(ww2, 1)*size(ww2, 2)*size(ww2, 3))
  call pushreal8array(ww1, size(ww1, 1)*size(ww1, 2)*size(ww1, 3))
  call pushreal8array(ww0, size(ww0, 1)*size(ww0, 2)*size(ww0, 3))
  call pushreal8array(ssi, size(ssi, 1)*size(ssi, 2)*size(ssi, 3))
  call pushreal8array(rlv3, size(rlv3, 1)*size(rlv3, 2))
  call pushreal8array(rlv2, size(rlv2, 1)*size(rlv2, 2))
  call pushreal8array(rlv1, size(rlv1, 1)*size(rlv1, 2))
  call pushreal8array(rlv0, size(rlv0, 1)*size(rlv0, 2))
  call pushreal8array(pp3, size(pp3, 1)*size(pp3, 2))
  call pushreal8array(pp2, size(pp2, 1)*size(pp2, 2))
  call pushreal8array(pp1, size(pp1, 1)*size(pp1, 2))
  call pushreal8array(pp0, size(pp0, 1)*size(pp0, 2))
  call pushreal8array(rev3, size(rev3, 1)*size(rev3, 2))
  call pushreal8array(rev2, size(rev2, 1)*size(rev2, 2))
  call pushreal8array(rev1, size(rev1, 1)*size(rev1, 2))
  call pushreal8array(rev0, size(rev0, 1)*size(rev0, 2))
  call pushreal8array(xx, size(xx, 1)*size(xx, 2)*size(xx, 3))
  call pushreal8array(gamma3, size(gamma3, 1)*size(gamma3, 2))
  call pushreal8array(gamma2, size(gamma2, 1)*size(gamma2, 2))
  call pushreal8array(gamma1, size(gamma1, 1)*size(gamma1, 2))
  call pushreal8array(gamma0, size(gamma0, 1)*size(gamma0, 2))
  call pushreal8array(cmv, 3)
  call pushreal8array(cmp, 3)
  call pushreal8array(cfv, 3)
  call pushreal8array(cfp, 3)
  call forcesandmoments(cfp, cfv, cmp, cmv, yplusmax, sepsensor, &
&                    sepsensoravg, cavitation)
! convert back to actual forces. note that even though we use
! machcoef, lref, and surfaceref here, they are not differented,
! since f doesn't actually depend on them. ideally we would just get
! the raw forces and moment form forcesandmoments. 
  force = zero
  moment = zero
  scaledim = pref/pinf
  fact = two/(gammainf*pinf*machcoef*machcoef*surfaceref*lref*lref*&
&   scaledim)
  do sps2=1,ntimeintervalsspectral
    force(:, sps2) = (cfp+cfv)/fact
  end do
  call pushreal8(fact)
  fact = fact/(lengthref*lref)
  do sps2=1,ntimeintervalsspectral
    moment(:, sps2) = (cmp+cmv)/fact
  end do
  call getcostfunction2_b(force, forced, moment, momentd, sepsensor, &
&                   sepsensord, sepsensoravg, sepsensoravgd, cavitation&
&                   , cavitationd, alpha, beta, liftindex)
  cmpd = 0.0_8
  cmvd = 0.0_8
  factd = 0.0_8
  do sps2=ntimeintervalsspectral,1,-1
    tempd6 = momentd(:, sps2)/fact
    cmpd = cmpd + tempd6
    cmvd = cmvd + tempd6
    factd = factd + sum(-((cmp+cmv)*tempd6/fact))
    momentd(:, sps2) = 0.0_8
  end do
  call popreal8(fact)
  tempd5 = factd/(lref*lengthref)
  lengthrefd = lengthrefd - fact*tempd5/lengthref
  factd = tempd5
  cfpd = 0.0_8
  cfvd = 0.0_8
  do sps2=ntimeintervalsspectral,1,-1
    tempd4 = forced(:, sps2)/fact
    cfpd = cfpd + tempd4
    cfvd = cfvd + tempd4
    factd = factd + sum(-((cfp+cfv)*tempd4/fact))
    forced(:, sps2) = 0.0_8
  end do
  temp3 = machcoef**2*scaledim
  temp2 = surfaceref*lref**2
  temp1 = temp2*gammainf*pinf
  tempd2 = -(two*factd/(temp1**2*temp3**2))
  tempd3 = temp3*temp2*tempd2
  gammainfd = gammainfd + pinf*tempd3
  machcoefd = machcoefd + scaledim*temp1*2*machcoef*tempd2
  scaledimd = temp1*machcoef**2*tempd2
  pinfd = pinfd + gammainf*tempd3 - pref*scaledimd/pinf**2
  prefd = prefd + scaledimd/pinf
  call popreal8array(cfp, 3)
  call popreal8array(cfv, 3)
  call popreal8array(cmp, 3)
  call popreal8array(cmv, 3)
  call popreal8array(gamma0, size(gamma0, 1)*size(gamma0, 2))
  call popreal8array(gamma1, size(gamma1, 1)*size(gamma1, 2))
  call popreal8array(gamma2, size(gamma2, 1)*size(gamma2, 2))
  call popreal8array(gamma3, size(gamma3, 1)*size(gamma3, 2))
  call popreal8array(xx, size(xx, 1)*size(xx, 2)*size(xx, 3))
  call popreal8array(rev0, size(rev0, 1)*size(rev0, 2))
  call popreal8array(rev1, size(rev1, 1)*size(rev1, 2))
  call popreal8array(rev2, size(rev2, 1)*size(rev2, 2))
  call popreal8array(rev3, size(rev3, 1)*size(rev3, 2))
  call popreal8array(pp0, size(pp0, 1)*size(pp0, 2))
  call popreal8array(pp1, size(pp1, 1)*size(pp1, 2))
  call popreal8array(pp2, size(pp2, 1)*size(pp2, 2))
  call popreal8array(pp3, size(pp3, 1)*size(pp3, 2))
  call popreal8array(rlv0, size(rlv0, 1)*size(rlv0, 2))
  call popreal8array(rlv1, size(rlv1, 1)*size(rlv1, 2))
  call popreal8array(rlv2, size(rlv2, 1)*size(rlv2, 2))
  call popreal8array(rlv3, size(rlv3, 1)*size(rlv3, 2))
  call popreal8array(ssi, size(ssi, 1)*size(ssi, 2)*size(ssi, 3))
  call popreal8array(ww0, size(ww0, 1)*size(ww0, 2)*size(ww0, 3))
  call popreal8array(ww1, size(ww1, 1)*size(ww1, 2)*size(ww1, 3))
  call popreal8array(ww2, size(ww2, 1)*size(ww2, 2)*size(ww2, 3))
  call popreal8array(ww3, size(ww3, 1)*size(ww3, 2)*size(ww3, 3))
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%x, size(flowdoms(ii3&
&                    , ii2, ii1)%x, 1)*size(flowdoms(ii3, ii2, ii1)%x, 2&
&                    )*size(flowdoms(ii3, ii2, ii1)%x, 3)*size(flowdoms(&
&                    ii3, ii2, ii1)%x, 4))
      end do
    end do
  end do
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                    , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, 2&
&                    )*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(flowdoms(&
&                    ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  call popreal8array(rev, size(rev, 1)*size(rev, 2)*size(rev, 3))
  call popreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call popreal8array(gamma, size(gamma, 1)*size(gamma, 2)*size(gamma, 3)&
&             )
  call popreal8array(rlv, size(rlv, 1)*size(rlv, 2)*size(rlv, 3))
  call popreal8array(si, size(si, 1)*size(si, 2)*size(si, 3)*size(si, 4)&
&             )
  call popreal8array(sj, size(sj, 1)*size(sj, 2)*size(sj, 3)*size(sj, 4)&
&             )
  call popreal8array(sk, size(sk, 1)*size(sk, 2)*size(sk, 3)*size(sk, 4)&
&             )
  call forcesandmoments_b(cfp, cfpd, cfv, cfvd, cmp, cmpd, cmv, cmvd, &
&                   yplusmax, sepsensor, sepsensord, sepsensoravg, &
&                   sepsensoravgd, cavitation, cavitationd)
  do sps2=ntimeintervalsspectral,1,-1
    do l=nstate,nt1,-1
      do k=kl,2,-1
        do j=jl,2,-1
          do i=il,2,-1
            flowdomsd(nn, 1, sps2)%dw(i, j, k, l) = turbresscale(l-nt1+1&
&             )*flowdomsd(nn, 1, sps2)%dw(i, j, k, l)/flowdoms(nn, &
&             currentlevel, sps2)%volref(i, j, k)
          end do
        end do
      end do
    end do
    do l=nwf,1,-1
      do k=kl,2,-1
        do j=jl,2,-1
          do i=il,2,-1
            flowdomsd(nn, 1, sps2)%dw(i, j, k, l) = flowdomsd(nn, 1, &
&             sps2)%dw(i, j, k, l)/flowdoms(nn, currentlevel, sps2)%&
&             volref(i, j, k)
          end do
        end do
      end do
    end do
  end do
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                    , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, 2&
&                    )*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(flowdoms(&
&                    ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%dw, size(flowdoms(ii3&
&                    , ii2, ii1)%dw, 1)*size(flowdoms(ii3, ii2, ii1)%dw&
&                    , 2)*size(flowdoms(ii3, ii2, ii1)%dw, 3)*size(&
&                    flowdoms(ii3, ii2, ii1)%dw, 4))
      end do
    end do
  end do
  call popreal8array(aa, size(aa, 1)*size(aa, 2)*size(aa, 3))
  call popreal8array(fw, size(fw, 1)*size(fw, 2)*size(fw, 3)*size(fw, 4)&
&             )
  call residual_block_b()
  call popcontrol2b(branch)
  if (branch .lt. 2) then
    if (branch .eq. 0) then
      dwd(:, :, :, 1:nwf) = 0.0_8
    else
      do sps2=ntimeintervalsspectral,1,-1
        do mm=ntimeintervalsspectral,1,-1
          do l=nwf,1,-1
            call popcontrol1b(branch)
            if (branch .eq. 0) then
              do k=kl,2,-1
                do j=jl,2,-1
                  do i=il,2,-1
                    tempd0 = dscalar(jj, sps2, mm)*flowdomsd(nn, 1, sps2&
&                     )%dw(i, j, k, l)
                    flowdomsd(nn, 1, mm)%vol(i, j, k) = flowdomsd(nn, 1&
&                     , mm)%vol(i, j, k) + flowdoms(nn, 1, mm)%w(i, j, k&
&                     , l)*tempd0
                    flowdomsd(nn, 1, mm)%w(i, j, k, l) = flowdomsd(nn, 1&
&                     , mm)%w(i, j, k, l) + flowdoms(nn, 1, mm)%vol(i, j&
&                     , k)*tempd0
                  end do
                end do
              end do
            else
              do k=kl,2,-1
                do j=jl,2,-1
                  do i=il,2,-1
                    tempd = flowdoms(nn, 1, mm)%w(i, j, k, irho)*&
&                     flowdomsd(nn, 1, sps2)%dw(i, j, k, l)
                    temp = flowdoms(nn, 1, mm)%vol(i, j, k)
                    tmpd = temp*tempd
                    flowdomsd(nn, 1, mm)%vol(i, j, k) = flowdomsd(nn, 1&
&                     , mm)%vol(i, j, k) + tmp*tempd
                    flowdomsd(nn, 1, mm)%w(i, j, k, irho) = flowdomsd(nn&
&                     , 1, mm)%w(i, j, k, irho) + tmp*temp*flowdomsd(nn&
&                     , 1, sps2)%dw(i, j, k, l)
                    call popreal8(tmp)
                    flowdomsd(nn, 1, mm)%w(i, j, k, ivx) = flowdomsd(nn&
&                     , 1, mm)%w(i, j, k, ivx) + dvector(jj, ll, ii+1)*&
&                     tmpd
                    flowdomsd(nn, 1, mm)%w(i, j, k, ivy) = flowdomsd(nn&
&                     , 1, mm)%w(i, j, k, ivy) + dvector(jj, ll, ii+2)*&
&                     tmpd
                    flowdomsd(nn, 1, mm)%w(i, j, k, ivz) = flowdomsd(nn&
&                     , 1, mm)%w(i, j, k, ivz) + dvector(jj, ll, ii+3)*&
&                     tmpd
                  end do
                end do
              end do
              call popcontrol1b(branch)
              if (branch .ne. 0) call popinteger4(ll)
              call popcontrol1b(branch)
              if (branch .eq. 0) call popinteger4(ll)
              call popcontrol1b(branch)
              if (branch .eq. 0) call popinteger4(ll)
            end if
          end do
          call popinteger4(ii)
        end do
        call popinteger4(jj)
      end do
      do sps2=ntimeintervalsspectral,1,-1
        flowdomsd(nn, 1, sps2)%dw(:, :, :, 1:nwf) = 0.0_8
      end do
    end if
  else if (branch .eq. 2) then
    oneoverdtd = 0.0_8
    do l=nw,1,-1
      do k=kl,2,-1
        do j=jl,2,-1
          do i=il,2,-1
            call popreal8(flowdoms(nn, 1, sps)%dw(i, j, k, l))
            oneoverdtd = oneoverdtd + flowdoms(nn, 1, sps)%dw(i, j, k, l&
&             )*flowdomsd(nn, 1, sps)%dw(i, j, k, l)
            flowdomsd(nn, 1, sps)%dw(i, j, k, l) = oneoverdt*flowdomsd(&
&             nn, 1, sps)%dw(i, j, k, l)
          end do
        end do
      end do
    end do
    call popcontrol1b(branch)
    if (branch .eq. 0) then
      do m=noldlevels,1,-1
        do l=nw,1,-1
          do k=kl,2,-1
            do j=jl,2,-1
              do i=il,2,-1
                vold(i, j, k) = vold(i, j, k) + wold(m, i, j, k, l)*&
&                 coeftime(m)*flowdomsd(nn, 1, sps)%dw(i, j, k, l)
              end do
            end do
          end do
        end do
      end do
    end if
    do l=nw,1,-1
      call popcontrol1b(branch)
      if (branch .eq. 0) then
        do k=kl,2,-1
          do j=jl,2,-1
            do i=il,2,-1
              vold(i, j, k) = vold(i, j, k) + coeftime(0)*w(i, j, k, l)*&
&               flowdomsd(nn, 1, sps)%dw(i, j, k, l)
              wd(i, j, k, l) = wd(i, j, k, l) + coeftime(0)*vol(i, j, k)&
&               *flowdomsd(nn, 1, sps)%dw(i, j, k, l)
              flowdomsd(nn, 1, sps)%dw(i, j, k, l) = 0.0_8
            end do
          end do
        end do
      else
        do k=kl,2,-1
          do j=jl,2,-1
            do i=il,2,-1
              temp0 = w(i, j, k, l)
              tempd1 = coeftime(0)*w(i, j, k, irho)*flowdomsd(nn, 1, sps&
&               )%dw(i, j, k, l)
              vold(i, j, k) = vold(i, j, k) + temp0*tempd1
              wd(i, j, k, l) = wd(i, j, k, l) + vol(i, j, k)*tempd1
              wd(i, j, k, irho) = wd(i, j, k, irho) + coeftime(0)*vol(i&
&               , j, k)*temp0*flowdomsd(nn, 1, sps)%dw(i, j, k, l)
              flowdomsd(nn, 1, sps)%dw(i, j, k, l) = 0.0_8
            end do
          end do
        end do
      end if
    end do
    timerefd = timerefd + oneoverdtd/deltat
  end if
  call popcontrol2b(branch)
  if (branch .eq. 0) then
    do ii1=ntimeintervalsspectral,1,-1
      do ii2=1,1,-1
        do ii3=nn,nn,-1
          call popreal8array(flowdoms(ii3, ii2, ii1)%dw, size(flowdoms(&
&                      ii3, ii2, ii1)%dw, 1)*size(flowdoms(ii3, ii2, ii1&
&                      )%dw, 2)*size(flowdoms(ii3, ii2, ii1)%dw, 3)*size&
&                      (flowdoms(ii3, ii2, ii1)%dw, 4))
        end do
      end do
    end do
    call popreal8array(bmtk1, size(bmtk1, 1)*size(bmtk1, 2)*size(bmtk1, &
&                3)*size(bmtk1, 4))
    call popreal8array(bmtk2, size(bmtk2, 1)*size(bmtk2, 2)*size(bmtk2, &
&                3)*size(bmtk2, 4))
    call popreal8array(scratch, size(scratch, 1)*size(scratch, 2)*size(&
&                scratch, 3)*size(scratch, 4))
    call popreal8array(bmti1, size(bmti1, 1)*size(bmti1, 2)*size(bmti1, &
&                3)*size(bmti1, 4))
    call popreal8array(bmti2, size(bmti2, 1)*size(bmti2, 2)*size(bmti2, &
&                3)*size(bmti2, 4))
    call popreal8array(bmtj1, size(bmtj1, 1)*size(bmtj1, 2)*size(bmtj1, &
&                3)*size(bmtj1, 4))
    call popreal8array(bmtj2, size(bmtj2, 1)*size(bmtj2, 2)*size(bmtj2, &
&                3)*size(bmtj2, 4))
    call sa_block_b(.true.)
  else if (branch .eq. 1) then
    d2walld = 0.0_8
  else
    d2walld = 0.0_8
  end if
  do sps2=ntimeintervalsspectral,1,-1
    flowdomsd(nn, 1, sps2)%dw = 0.0_8
  end do
  call timestep_block_b(.false.)
  call popcontrol1b(branch)
  if (branch .eq. 0) then
    do ii1=ntimeintervalsspectral,1,-1
      do ii2=1,1,-1
        do ii3=nn,nn,-1
          call popreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(&
&                      ii3, ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)&
&                      %w, 2)*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(&
&                      flowdoms(ii3, ii2, ii1)%w, 4))
        end do
      end do
    end do
    call applyallturbbcthisblock_b(.true.)
    call bcturbtreatment_b()
  end if
  call popreal8array(gamma0, size(gamma0, 1)*size(gamma0, 2))
  call popreal8array(gamma1, size(gamma1, 1)*size(gamma1, 2))
  call popreal8array(gamma2, size(gamma2, 1)*size(gamma2, 2))
  call popreal8array(gamma3, size(gamma3, 1)*size(gamma3, 2))
  call popreal8array(xx, size(xx, 1)*size(xx, 2)*size(xx, 3))
  call popreal8array(rev0, size(rev0, 1)*size(rev0, 2))
  call popreal8array(rev1, size(rev1, 1)*size(rev1, 2))
  call popreal8array(rev2, size(rev2, 1)*size(rev2, 2))
  call popreal8array(rev3, size(rev3, 1)*size(rev3, 2))
  call popreal8array(pp0, size(pp0, 1)*size(pp0, 2))
  call popreal8array(pp1, size(pp1, 1)*size(pp1, 2))
  call popreal8array(pp2, size(pp2, 1)*size(pp2, 2))
  call popreal8array(pp3, size(pp3, 1)*size(pp3, 2))
  call popreal8array(rlv0, size(rlv0, 1)*size(rlv0, 2))
  call popreal8array(rlv1, size(rlv1, 1)*size(rlv1, 2))
  call popreal8array(rlv2, size(rlv2, 1)*size(rlv2, 2))
  call popreal8array(rlv3, size(rlv3, 1)*size(rlv3, 2))
  call popreal8array(ssi, size(ssi, 1)*size(ssi, 2)*size(ssi, 3))
  call popreal8array(ww0, size(ww0, 1)*size(ww0, 2)*size(ww0, 3))
  call popreal8array(ww1, size(ww1, 1)*size(ww1, 2)*size(ww1, 3))
  call popreal8array(ww2, size(ww2, 1)*size(ww2, 2)*size(ww2, 3))
  call popreal8array(ww3, size(ww3, 1)*size(ww3, 2)*size(ww3, 3))
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%x, size(flowdoms(ii3&
&                    , ii2, ii1)%x, 1)*size(flowdoms(ii3, ii2, ii1)%x, 2&
&                    )*size(flowdoms(ii3, ii2, ii1)%x, 3)*size(flowdoms(&
&                    ii3, ii2, ii1)%x, 4))
      end do
    end do
  end do
  do ii1=ntimeintervalsspectral,1,-1
    do ii2=1,1,-1
      do ii3=nn,nn,-1
        call popreal8array(flowdoms(ii3, ii2, ii1)%w, size(flowdoms(ii3&
&                    , ii2, ii1)%w, 1)*size(flowdoms(ii3, ii2, ii1)%w, 2&
&                    )*size(flowdoms(ii3, ii2, ii1)%w, 3)*size(flowdoms(&
&                    ii3, ii2, ii1)%w, 4))
      end do
    end do
  end do
  call popreal8array(rev, size(rev, 1)*size(rev, 2)*size(rev, 3))
  call popreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call popreal8array(gamma, size(gamma, 1)*size(gamma, 2)*size(gamma, 3)&
&             )
  call popreal8array(rlv, size(rlv, 1)*size(rlv, 2)*size(rlv, 3))
  call popreal8array(si, size(si, 1)*size(si, 2)*size(si, 3)*size(si, 4)&
&             )
  call popreal8array(sj, size(sj, 1)*size(sj, 2)*size(sj, 3)*size(sj, 4)&
&             )
  call popreal8array(sk, size(sk, 1)*size(sk, 2)*size(sk, 3)*size(sk, 4)&
&             )
  call applyallbc_block_b(.true.)
  call computeeddyviscosity_b()
  call computelamviscosity_b()
  call popreal8array(p, size(p, 1)*size(p, 2)*size(p, 3))
  call computepressuresimple_b()
  call popcontrol2b(branch)
  if (branch .eq. 0) then
    call updatewalldistancesquickly_b(nn, 1, sps)
  else if (branch .eq. 1) then
    xsurfd = 0.0_8
  else
    xsurfd = 0.0_8
    goto 100
  end if
  call boundarynormals_b()
  call metric_block_b()
  call volume_block_b()
 100 call popreal8(gammainf)
  call referencestate_b()
  call adjustinflowangle_b(alpha, alphad, beta, betad, liftindex)
  funcvaluesd = 0.0_8
end subroutine block_res_b

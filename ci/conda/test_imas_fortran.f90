! Consumer test for the imas-fortran conda package: compiled and linked
! against the installed modules and libraries, as a user program would be.
!  * put/get round trip of an IDS with the in-memory backend (no files);
!  * error status propagation from the lowlevel C API;
!  * lookup in an identifier module (al-identifiers-fortran library).
program test_imas_fortran
  use ids_routines
  use al_coordinate_identifier, only: get_index
  implicit none

  integer, parameter :: n = 5
  type(ids_magnetics) :: put_ids, get_ids
  integer :: idx, i, status
  character(:), allocatable :: message

  ! Round trip through the memory backend
  call imas_open('imas:memory?path=/test_imas_fortran', FORCE_CREATE_PULSE, idx, status)
  call check(status == 0, 'imas_open (memory backend)')

  put_ids%ids_properties%homogeneous_time = IDS_TIME_MODE_HOMOGENEOUS
  allocate(put_ids%time(n))
  allocate(put_ids%flux_loop(2))
  do i = 1, n
     put_ids%time(i) = 0.1_ids_real * i
  end do
  allocate(put_ids%flux_loop(2)%flux%data(n))
  put_ids%flux_loop(2)%flux%data = 100.0_ids_real + put_ids%time

  call ids_put(idx, 'magnetics', put_ids)
  call ids_get(idx, 'magnetics', get_ids)
  call check(associated(get_ids%time), 'time associated after get')
  call check(size(get_ids%time) == n, 'time size after get')
  call check(all(get_ids%time == put_ids%time), 'time values after get')
  call check(size(get_ids%flux_loop) == 2, 'flux_loop size after get')
  call check(all(get_ids%flux_loop(2)%flux%data == put_ids%flux_loop(2)%flux%data), &
       'flux_loop(2)%flux%data values after get')
  call imas_close(idx)

  ! Errors from the C API must come back with a negative code and a message
  call al_close_pulse(-42, 0, status, message)
  call check(status < 0, 'error status code from invalid context')
  call check(len_trim(message) > 0, 'error message from invalid context')

  ! Identifier library
  call check(get_index('rho_tor_norm') == 12, 'coordinate identifier rho_tor_norm')

  print '(a)', 'All imas-fortran package tests passed'

contains

  subroutine check(condition, description)
    logical, intent(in) :: condition
    character(*), intent(in) :: description
    if (.not. condition) then
       print '(2a)', 'FAILED: ', description
       error stop 1
    end if
    print '(2a)', 'ok: ', description
  end subroutine check

end program test_imas_fortran

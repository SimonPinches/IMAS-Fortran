# Consumer test for the imas-fortran conda package: build test_imas_fortran.f90
# with the installed CMake package (find_package( al-fortran ))
cmake_minimum_required( VERSION 3.16 )
# CXX is only needed while the al-core CMake package of libimas-core calls
# find_dependency( Boost ): Boost's package configuration requires a C++
# compiler. Drop it (and libboost-devel from the test requirements) once
# libimas-core is built from an IMAS-Core release without that dependency.
project( test_imas_fortran LANGUAGES CXX Fortran )

find_package( al-fortran REQUIRED )
message( STATUS "Found al-fortran ${al-fortran_VERSION} (DD ${al-fortran_DD_VERSION})" )

add_executable( test_imas_fortran test_imas_fortran.f90 )
# The identifiers library brings in al-fortran and IMAS-Core transitively
target_link_libraries( test_imas_fortran PRIVATE al-fortran::al-identifiers-fortran )

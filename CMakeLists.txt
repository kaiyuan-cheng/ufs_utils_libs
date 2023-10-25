cmake_minimum_required(VERSION 3.12)

project(ufs_utils-libraries LANGUAGES C CXX Fortran)

include(ExternalProject)

set(MPI_DETERMINE_LIBRARY_VERSION true)
find_package(MPI REQUIRED C CXX Fortran)

set(install_prefix ${CMAKE_INSTALL_PREFIX})

if(${CMAKE_Fortran_COMPILER_ID} MATCHES "^(GNU)$")
  if(${CMAKE_Fortran_COMPILER_VERSION} VERSION_GREATER_EQUAL 10)
    set(FCFLAGS_esmf "${FCFLAGS_esmf} -fallow-argument-mismatch -fallow-invalid-boz")
  endif()
endif()

##
## zlib
##
ExternalProject_Add(zlib
    URL https://github.com/madler/zlib/archive/refs/tags/v1.2.11.tar.gz
    URL_HASH MD5=0095d2d2d1f3442ce1318336637b695f
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ./configure --prefix=${install_prefix}
                                  --libdir=${install_prefix}/lib
                                  --static
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## jpeg
##
ExternalProject_Add(jpeg
    URL https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/2.1.4.tar.gz
    URL_HASH MD5=357dc26a802c34387512a42697846d16
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
               -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib
               -DENABLE_STATIC=ON
               -DENABLE_SHARED=OFF
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)

##
## jasper
##
ExternalProject_Add(jasper
    URL https://github.com/jasper-software/jasper/archive/refs/tags/version-2.0.25.tar.gz
    URL_HASH MD5=afbdd817fcdd0dcfbd6bec79825b944a
    BUILD_IN_SOURCE OFF
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
               -DCMAKE_INSTALL_LIBDIR=lib
               -DCMAKE_BUILD_TYPE=Release
               -DJAS_ENABLE_DOC=OFF
               -DJAS_ENABLE_SHARED=OFF
               -DJAS_ENABLE_AUTOMATIC_DEPENDENCIES=OFF
               -DJAS_ENABLE_PROGRAMS=OFF
               -DJAS_ENABLE_OPENGL=OFF
               -DJAS_ENABLE_LIBJPEG=OFF
               -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=ON
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(jasper build jpeg)

##
## libpng
##
ExternalProject_Add(libpng
    URL https://github.com/glennrp/libpng/archive/refs/tags/v1.6.37.tar.gz
    URL_HASH MD5=564aa9f6c678dbb016b07ecfae8b7245
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CPPFLAGS=-I${install_prefix}/include"
                      env "LDFLAGS=-L${install_prefix}/lib"
                      ./configure --prefix=${install_prefix}
                                  --libdir=${install_prefix}/lib
                                  --disable-shared
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(libpng build zlib)

##
## hdf5
##
ExternalProject_Add(hdf5
    URL https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_10_6.tar.gz
    URL_HASH MD5=abbf353b2d8a1d5a062bdbba1c365171
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "CFLAGS=-pthread"
                      ./configure --prefix=${install_prefix}
                                  --libdir=${install_prefix}/lib
                                  --disable-shared
                                  --enable-static
                                  --enable-parallel
                                  --enable-unsupported
                                  --enable-tests=no
                                  --with-zlib=${install_prefix}

    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(hdf5 build zlib)

##
## netcdf
##
ExternalProject_Add(netcdf
    URL https://github.com/Unidata/netcdf-c/archive/v4.7.4.tar.gz
    URL_HASH MD5=33979e8f0cf4ee31323fc0934282111b
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "CPPFLAGS=-I${install_prefix}/include"
                      env "LDFLAGS=-L${install_prefix}/lib -L${install_prefix}/lib"
                      env "LIBS=-lhdf5_hl -lhdf5 -lz -ldl -lm"
                      ./configure --prefix=${install_prefix}
                                  --libdir=${install_prefix}/lib
                                  --enable-cdf5
                                  --disable-dap
                                  --enable-netcdf-4
                                  --disable-doxygen
                                  --disable-shared
                                  --enable-static
                                  --disable-large-file-tests
                                  --enable-parallel-tests
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(netcdf build hdf5)

##
## netcdf_fortran
##
ExternalProject_Add(netcdf_fortran
    URL https://github.com/Unidata/netcdf-fortran/archive/v4.5.3.tar.gz
    URL_HASH MD5=47bf6eed50bd50b23b7e391dc1f8b5c4
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND env "CC=${MPI_C_COMPILER}"
                      env "FC=${MPI_Fortran_COMPILER}"
                      env "CPPFLAGS=-I${install_prefix}/include"
                      env "LDFLAGS=-L${install_prefix}/lib -L${install_prefix}/lib -L${install_prefix}/lib"
                      env "LIBS=-lnetcdf -lhdf5_hl -lhdf5 -lz -ldl -lm"
                      ./configure --prefix=${install_prefix}
                                  --libdir=${install_prefix}/lib
                                  --enable-static
                                  --disable-shared
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(netcdf_fortran build netcdf)


##
## ESMF
##
list(APPEND esmf_env ESMF_DIR=${CMAKE_CURRENT_BINARY_DIR}/esmf-prefix/src/esmf)

if(${CMAKE_C_COMPILER_ID} STREQUAL "Intel")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "IntelLLVM")
  list(APPEND esmf_env ESMF_COMPILER=intel)
elseif(${CMAKE_C_COMPILER_ID} MATCHES "^(GNU|Clang|AppleClang)$")
  list(APPEND esmf_env ESMF_COMPILER=gfortran)
else()
  message(FATAL_ERROR "Unsupported compiler ${CMAKE_C_COMPILER_ID}")
endif()

if(NOT MPITYPE)
  if(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*CRAY MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*MPICH.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpich3")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Open MPI.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "openmpi")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*HPE MPT.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "mpt")
  elseif(MPI_C_LIBRARY_VERSION_STRING MATCHES ".*Intel.*" AND MPI_C_VERSION_MAJOR MATCHES "3")
    set(MPITYPE "intelmpi")
  else()
    message(FATAL_ERROR "Cannot detect MPI type for ESMF, check that it is supported and set it via -DMPITYPE=... ; valid options are: intelmpi, openmpi, mpich3, mpt, openmpi")
  endif()
endif()
message(STATUS "Set ESMF_COMM to ${MPITYPE}")

list(APPEND esmf_env ESMF_COMM=${MPITYPE})
list(APPEND esmf_env ESMF_BOPT=O)
# list(APPEND esmf_env ESMF_OPTLEVEL=2)
list(APPEND esmf_env ESMF_F90COMPILEOPTS=${FCFLAGS_esmf})
list(APPEND esmf_env ESMF_CXXCOMPILEOPTS=${CXXFLAGS_esmf})
list(APPEND esmf_env ESMF_MPIRUN=mpiexec)
list(APPEND esmf_env ESMF_NETCDF_INCLUDE=${install_prefix}/include)
list(APPEND esmf_env ESMF_NETCDF_LIBPATH=${install_prefix}/lib)
list(APPEND esmf_env ESMF_NETCDF=split)
list(APPEND esmf_env  "ESMF_NETCDF_LIBS=-lnetcdff -lnetcdf -L${install_prefix}/lib -lhdf5_hl -lhdf5 -L${install_prefix}/lib -lz -ldl -lm -Wl,--as-needed,-lmpifort_intel,--no-as-needed -Wl,--as-needed,-lmpi_intel,--no-as-needed -Wl,--as-needed,-limf,--no-as-needed -Wl,--as-needed,-lm,--no-as-needed -Wl,--as-needed,-lpthread,--no-as-needed ")
#list(APPEND esmf_env ESMF_PIO=external)
#list(APPEND esmf_env ESMF_PIO_INCLUDE=${install_prefix}/pio/include)
list(APPEND esmf_env ESMF_SHARED_LIB_BUILD=OFF)
list(APPEND esmf_env ESMF_INSTALL_PREFIX=${install_prefix})
list(APPEND esmf_env ESMF_INSTALL_HEADERDIR=include)
list(APPEND esmf_env ESMF_INSTALL_MODDIR=mod)
list(APPEND esmf_env ESMF_INSTALL_LIBDIR=lib)
list(APPEND esmf_env ESMF_INSTALL_BINDIR=bin)

ExternalProject_Add(esmf
    URL https://github.com/esmf-org/esmf/archive/refs/tags/v8.4.1.tar.gz
    URL_HASH MD5=5b9ea69c3be25ca14173ef9e16d06f2b
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ""
    BUILD_COMMAND   env ${esmf_env} make -j 8
    INSTALL_COMMAND env ${esmf_env} make install
    LOG_DOWNLOAD ON
    LOG_CONFIGURE ON
    LOG_BUILD ON
    LOG_INSTALL ON
)
ExternalProject_Add_StepDependencies(esmf build netcdf_fortran )

##
## NCEPLIBS
##
set(EMC_crtm_tag        v2.3.0)
set(NCEPLIBS-bacio_tag  v2.4.1)
set(NCEPLIBS-g2_tag     v3.4.5)
set(NCEPLIBS-ip_tag     v3.3.3)
set(NCEPLIBS-nemsio_tag v2.5.4)
set(NCEPLIBS-sp_tag     v2.3.3)
set(NCEPLIBS-w3emc_tag  v2.9.2)
set(NCEPLIBS-w3nco_tag  v2.4.1)
set(NCEPLIBS-gfsio_tag  v1.4.1)
set(NCEPLIBS-sfcio_tag  v1.4.1)
set(NCEPLIBS-sigio_tag  v2.3.2)
set(NCEPLIBS-nemsiogfs_tag v2.5.3)
set(NCEPLIBS-landsfcutil_tag v2.4.1)
set(NCEPLIBS-wgrib2_tag v2.0.8-cmake-v6)



foreach(lib_name
    #                 EMC_crtm
                 NCEPLIBS-bacio
                 NCEPLIBS-g2
                 NCEPLIBS-ip
                 NCEPLIBS-nemsio
                 NCEPLIBS-sp
                 NCEPLIBS-w3emc
                 NCEPLIBS-w3nco
                 NCEPLIBS-gfsio
                 NCEPLIBS-sfcio
                 NCEPLIBS-sigio
                 NCEPLIBS-nemsiogfs
                 NCEPLIBS-landsfcutil
                 NCEPLIBS-wgrib2
                 )

    ExternalProject_Add(${lib_name}
        GIT_REPOSITORY https://github.com/NOAA-EMC/${lib_name}
        GIT_TAG ${${lib_name}_tag}
        GIT_SUBMODULES_RECURSE ON
        BUILD_IN_SOURCE OFF
        LIST_SEPARATOR ,
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${install_prefix}
                   -DCMAKE_INSTALL_LIBDIR=lib
                   -DCMAKE_PREFIX_PATH=${install_prefix}
        LOG_DOWNLOAD ON
        LOG_CONFIGURE ON
        LOG_BUILD ON
        LOG_INSTALL ON
    )

endforeach()

ExternalProject_Add_StepDependencies(NCEPLIBS-g2     build jasper libpng)
ExternalProject_Add_StepDependencies(NCEPLIBS-ip     build NCEPLIBS-sp)
ExternalProject_Add_StepDependencies(NCEPLIBS-nemsio build NCEPLIBS-bacio NCEPLIBS-w3emc)
ExternalProject_Add_StepDependencies(NCEPLIBS-w3emc  build NCEPLIBS-bacio)
ExternalProject_Add_StepDependencies(NCEPLIBS-nemsiogfs build NCEPLIBS-sp NCEPLIBS-bacio NCEPLIBS-w3nco NCEPLIBS-sigio NCEPLIBS-nemsio NCEPLIBS-ip)
ExternalProject_Add_StepDependencies(NCEPLIBS-wgrib2 build jasper libpng netcdf_fortran)

FROM debian:stable-slim as build

# kick everything off
RUN apt-get update && apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl git wget gpg-agent software-properties-common build-essential gnupg pkg-config libaec-dev && \
  rm -rf /var/lib/apt/lists/*

# Get CMAKE and install it
RUN mkdir -p cmake/build && \
   cd cmake/build && \
   curl -LO https://github.com/Kitware/CMake/releases/download/v3.26.2/cmake-3.26.2-linux-x86_64.sh && \
   /bin/bash cmake-3.26.2-linux-x86_64.sh --prefix=/usr/local --skip-license

# Get the Intel compilers
# download the key to system keyring
RUN wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
| gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
# add signed entry to apt sources and configure the APT client to use Intel repository:
RUN echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | tee /etc/apt/sources.list.d/oneAPI.list
RUN apt-get -y update && apt-get upgrade -y
RUN apt-get install -y intel-hpckit
RUN . /opt/intel/oneapi/setvars.sh

# Build the NetCDF libraries
RUN mkdir -p /opt/build && mkdir -p /opt/dist
ENV INDIR="/opt/dist//usr/local"
ENV INTEL_DIR="/opt/intel/oneapi"
ENV CC="${INTEL_DIR}/compiler/latest/linux/bin/icx-cc"
ENV FC="${INTEL_DIR}/compiler/latest/linux/bin/ifx"

RUN apt-get update && apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  libhdf5-dev hdf5-tools zlib1g zlib1g-dev libxml2-dev libcurl4-gnutls-dev m4 && \
  rm -rf /var/lib/apt/lists/*


#NetCDF-c library
RUN git clone https://github.com/Unidata/netcdf-c.git
RUN cd netcdf-c && mkdir build && cd build && \
   cmake ..  -DCMAKE_PREFIX_PATH="${LD_LIBRARY_PATH}" -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_INSTALL_PREFIX="${INDIR}"  && \
   make && make install

#NetCDF-Fortran library
RUN git clone https://github.com/Unidata/netcdf-fortran.git
RUN cd netcdf-fortran && mkdir build && cd build && \
   cmake .. -DCMAKE_INSTALL_PREFIX="${INDIR}"  && \
   make && make install

# #Swiftest
# RUN git clone -b debug https://github.com/carlislewishard/swiftest.git
# RUN cd swiftest && cmake -P distclean.cmake && mkdir build && cd build && \
#    cmake .. -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX="${INDIR}" && \ 
#    make && make install

# #Production container
# FROM debian:stable-slim
# COPY --from=build /opt/dist /

# # Get the Intel runtime libraries
# RUN curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2023.PUB | apt-key add -
# RUN deb [trusted=yes] https://apt.repos.intel.com/oneapi all main " > /etc/apt/sources.list.d/oneAPI.list
# RUN apt-get -y update && apt-get upgrade -y
# RUN apt-get install -y intel-oneapi-runtime-openmp intel-oneapi-runtime-mkl intel-oneapi-runtime-mpi intel-oneapi-runtime-fortran 
# RUN . /opt/intel/oneapi/setvars.sh

# ENTRYPOINT ["/usr/bin/swiftest_driver"]
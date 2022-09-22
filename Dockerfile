FROM public.ecr.aws/lambda/python:3.8 as protobuf-builder
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 CMAKE_MAKE_PROGRAM=/usr/bin/make
RUN yum install -y which tar gzip "Development Tools" make gcc gcc-c++ boost-devel rsync openmpi openmpi-devel zlib-devel
ARG CMAKE_VER=3.21.3
ARG PROTOBUF_VER=3.12.3
RUN curl -sSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz -o /cmake.tar.gz
RUN curl -sSL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VER}/protobuf-cpp-${PROTOBUF_VER}.tar.gz -o /protobuf.tar.gz
RUN mkdir -p /opt/cmake && tar -xf /cmake.tar.gz -C /opt/cmake --strip-components 1
RUN mkdir -p /opt/protobuf && tar -xf /protobuf.tar.gz -C /opt/protobuf --strip-components 1
RUN cd /opt/protobuf && \
    ./configure --prefix /usr && \
    make -j4
RUN cd /opt/protobuf/cmake && \
    /opt/cmake/bin/cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr . && \
    make -j4

FROM public.ecr.aws/lambda/python:3.8 as isal-builder
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 CMAKE_MAKE_PROGRAM=/usr/bin/make
RUN yum install -y which tar gzip "Development Tools" make gcc nasm automake autoconf libtool
ARG ISAL_VER=refs/tags/v2.30.0
RUN curl -sSL https://github.com/intel/isa-l/archive/${ISAL_VER}.tar.gz -o /isal.tar.gz
RUN mkdir -p /opt/isal && tar -xf /isal.tar.gz -C /opt/isal --strip-components 1
WORKDIR /opt/isal
RUN ./autogen.sh
RUN ./configure --prefix /usr
RUN make -j4

FROM public.ecr.aws/lambda/python:3.8 as usher-builder
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 CMAKE_MAKE_PROGRAM=/usr/bin/make
RUN yum install -y which tar gzip "Development Tools" make gcc gcc-c++ boost-devel rsync openmpi openmpi-devel zlib-devel
COPY --from=isal-builder /opt/isal /opt/isal
COPY --from=protobuf-builder /opt/cmake /opt/cmake
COPY --from=protobuf-builder /opt/protobuf /opt/protobuf
ARG USHER_VER=refs/tags/v0.5.6
ARG TBB_VER=2019_U9
RUN curl -sSL https://github.com/yatisht/usher/archive/${USHER_VER}.tar.gz -o /usher.tar.gz
RUN curl -sSL https://github.com/oneapi-src/oneTBB/archive/${TBB_VER}.tar.gz -o /TBB.tar.gz
RUN mkdir -p /opt/usher && tar -xf /usher.tar.gz -C /opt/usher --strip-components 1
RUN mkdir -p /opt/tbb && tar -xf /TBB.tar.gz -C /opt/tbb --strip-components 1
RUN cd /opt/isal && make install
RUN cd /opt/protobuf && make install 
RUN cd /opt/protobuf/cmake && make install
WORKDIR /opt/usher
RUN PATH="$PATH:/usr/lib64/openmpi/bin" /opt/cmake/bin/cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DTBB_DIR=/opt/tbb -DCMAKE_PREFIX_PATH=/opt/tbb/cmake . && \
    make -j4 && make install
RUN install /opt/usher/tbb_cmake_build/tbb_cmake_build_subdir_release/* /usr/lib64

FROM public.ecr.aws/lambda/python:3.8 as installer
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ARG MINIMAP2_VER=2.24
RUN yum install -y which tar bzip2 git && \
    mkdir -p /opt/minimap2 && \
    curl -sSL https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_VER}/minimap2-${MINIMAP2_VER}_x64-linux.tar.bz2 -o minimap2.tar.bz2 && \
    tar -xf minimap2.tar.bz2 -C /opt/minimap2 --strip-components 1 && \
    rm -f minimap2.tar.bz2 && \
    ln -s /opt/minimap2/minimap2 /usr/bin
ARG GOFASTA_VER=0.03
RUN curl -sSL https://github.com/cov-ert/gofasta/releases/download/v0.0.3/gofasta-linux-amd64 -o /usr/bin/gofasta && \
    chmod +x /usr/bin/gofasta
RUN curl -sSL http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/faToVcf -o /usr/bin/faToVcf && \
    chmod +x /usr/bin/faToVcf
RUN pip install gitpython
ARG PANGOLIN_VER=refs/tags/v4.1.2
ARG SNAKEMAKE_VER=5.13.0
ARG PANGOLIN_DATA_VER=refs/tags/v1.14
ARG SCORPIO_VER=refs/tags/v0.3.17
ARG CONSTELLATIONS_VER=refs/tags/v0.1.10
RUN pip install --target /python-packages \
        snakemake==${SNAKEMAKE_VER} \
        https://github.com/cov-lineages/pangolin/archive/${PANGOLIN_VER}.tar.gz \
        https://github.com/cov-lineages/pangolin-data/archive/${PANGOLIN_DATA_VER}.tar.gz \
        https://github.com/cov-lineages/scorpio/archive/${SCORPIO_VER}.tar.gz \
        https://github.com/cov-lineages/constellations/archive/${CONSTELLATIONS_VER}.tar.gz
ARG GITLFS_VER=3.2.0
RUN mkdir -p /opt/git-lfs && \
    curl -sSL https://github.com/git-lfs/git-lfs/releases/download/v${GITLFS_VER}/git-lfs-linux-amd64-v${GITLFS_VER}.tar.gz -o git-lfs.tar.gz && \
    tar -xf git-lfs.tar.gz -C /opt/git-lfs --strip-components 1 && \
    rm -f git-lfs.tar.gz && \
    /opt/git-lfs/install.sh
ARG PANGOLIN_ASSIGN_VER=v1.13
RUN git clone https://github.com/cov-lineages/pangolin-assignment --branch ${PANGOLIN_ASSIGN_VER} --depth 1 && \
    pushd pangolin-assignment/ && \
    git lfs install && git lfs pull && \
    pip install --target /python-packages .
RUN mv /python-packages/bin /python-scripts

FROM public.ecr.aws/lambda/python:3.8
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

COPY --from=installer /usr/bin/which /usr/bin/which
COPY --from=installer /opt/minimap2 /opt/minimap2
COPY --from=installer /usr/bin/minimap2 /usr/bin/gofasta /usr/bin/faToVcf /usr/bin/
COPY --from=installer /python-scripts/ /var/lang/bin/
COPY --from=installer /python-packages/ /var/lang/lib/python3.8/site-packages/
COPY --from=usher-builder \
    /usr/bin/usher \
    /usr/bin/matUtils \
    /usr/bin/matOptimize \
    /usr/bin/ripples \
    /usr/bin/
COPY --from=usher-builder \
    /opt/usher/tbb_cmake_build/tbb_cmake_build_subdir_release/*.so \
    /opt/usher/tbb_cmake_build/tbb_cmake_build_subdir_release/*.so.2 \
    /usr/lib64/libstdc++.so.6 \
    /usr/lib64/libboost_* \
    /usr/lib64/libpthread.so.0 \
    /usr/lib64/libz.so.1 \
    /usr/lib64/libbz2.so.1 \
    /usr/lib64/
RUN pangolin -v > /pangolin_version.txt
COPY app.py ./
CMD ["app.main"]

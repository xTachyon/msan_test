FROM ubuntu:24.04 AS clone_llvm

RUN apt-get update && apt-get -y install git

RUN mkdir llvm \
    && cd llvm \
    && git init \
    && git remote add origin https://github.com/llvm/llvm-project.git \
    && git fetch --depth 1 origin 2078da43e25a4623cab2d0d60decddf709aaea28 \
    && git checkout FETCH_HEAD

# -----------------------------------------------------------------------------

FROM ubuntu:24.04 AS build_libcxx

RUN apt-get update \
    && apt-get -y install cmake ninja-build \
    curl lsb-release software-properties-common gnupg

RUN curl -O https://apt.llvm.org/llvm.sh \
    && bash ./llvm.sh 21 all

ENV CMAKE_GENERATOR=Ninja
ENV CC=clang-21
ENV CXX=clang++-21

ENV fsanitize_flag="-fsanitize=memory -fsanitize-memory-track-origins"

COPY --from=clone_llvm /llvm /llvm

RUN mkdir llvm/build \
    && cd llvm/build \
    && cmake ../runtimes \
        -D LIBCXXABI_USE_LLVM_UNWINDER=OFF \
        -D CMAKE_BUILD_TYPE=Release \
        -D LLVM_ENABLE_ASSERTIONS=ON \
        -D LLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
        -D LIBCXX_TEST_PARAMS="long_tests=False" \
        -D LIBCXX_INCLUDE_BENCHMARKS=OFF \
        -D LLVM_USE_SANITIZER=Memory \
        -D CMAKE_C_FLAGS="${fsanitize_flag}" \
        -D CMAKE_CXX_FLAGS="${fsanitize_flag}" \
    && ninja

RUN cd llvm/build && cmake -DCMAKE_INSTALL_PREFIX=/llvm/install -P cmake_install.cmake

# -----------------------------------------------------------------------------

FROM scratch AS export_libcxx
COPY --from=build_libcxx /llvm/install /llvm

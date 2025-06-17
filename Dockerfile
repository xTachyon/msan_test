FROM ubuntu:24.04

RUN apt-get update \
        && apt-get -y install git

RUN mkdir llvm \
    && cd llvm \
    && git init \
    && git remote add origin https://github.com/llvm/llvm-project.git \
    && git fetch --depth 1 origin 12611a7fc71376e88aa01e3f0bbc74517f1a1703 \
    && git checkout FETCH_HEAD

RUN apt-get update \
    && apt-get -y install cmake make ninja-build \
        wget lsb-release software-properties-common gnupg curl

RUN wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 20 all

ENV llvm_use_sanitizer="Memory"
ENV fsanitize_flag="-fsanitize=memory -fsanitize-memory-track-origins"
ENV cmake_options="-DLIBCXXABI_USE_LLVM_UNWINDER=OFF"
ENV CMAKE_GENERATOR Ninja
ENV CC=clang-20
ENV CXX=clang++-20

RUN mkdir llvm/build \
    && cd llvm/build \
    && cmake ../runtimes \
        ${cmake_options} \
        -D CMAKE_BUILD_TYPE=Debug \
        -D LLVM_CCACHE_BUILD=ON \
        -D LLVM_ENABLE_ASSERTIONS=ON \
        -D LLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
        -D LIBCXX_TEST_PARAMS='long_tests=False' \
        -D LIBCXX_INCLUDE_BENCHMARKS=OFF \
        -D LLVM_USE_SANITIZER=${llvm_use_sanitizer} \
        -D CMAKE_C_FLAGS="${fsanitize_flag} ${cmake_libcxx_cflags} ${fno_sanitize_flag}" \
        -D CMAKE_CXX_FLAGS="${fsanitize_flag} ${cmake_libcxx_cflags} ${fno_sanitize_flag}" \
    && ninja

COPY CMakeLists.txt main.cpp .
RUN $CXX -fsanitize=memory -stdlib=libc++ -Lllvm/build/lib -lc++abi -Illvm/build/include -Illvm/build/include/c++/v1 main.cpp && ./a.out
# RUN mkdir build \
#     && cd build \
#     &&  \
#     cmake .. \
#         -D CMAKE_BUILD_TYPE=Debug \
#         -D CMAKE_C_FLAGS="-fsanitize=memory -stdlib=libc++ -L../../llvm/build/lib -lc++abi -I../../llvm/build/include -I../../llvm/build/include/c++/v1" \
#         -D CMAKE_CXX_FLAGS="-fsanitize=memory -stdlib=libc++ -L../../llvm/build/lib -lc++abi -I../../llvm/build/include -I../../llvm/build/include/c++/v1" \
#     && ninja -v

# RUN build/msan_test

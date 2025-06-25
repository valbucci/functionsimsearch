FROM ubuntu:jammy AS dependencies

# Install system dependencies
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y git wget cmake sudo gcc g++ python3-pip zlib1g-dev googletest \
    libgtest-dev libgflags-dev libz-dev libelf-dev libboost-all-dev \
    libdwarf-dev libiberty-dev libtbb-dev libssl-dev libdw-dev libcapstone-dev
RUN pip3 install numpy absl-py

# Build the C++ libraries.
RUN cd /usr/src/gtest && \
    cmake ./CMakeLists.txt && \
    make && \
    find . -name "*.a" -exec cp {} /usr/lib \;


FROM dependencies AS third-party-build
RUN chmod 777 /tmp
RUN mkdir /code
WORKDIR /code

# Clone and build third-party dependencies
RUN mkdir -p /code/functionsimsearch/third_party
WORKDIR /code/functionsimsearch/third_party

# Dyninst
RUN wget https://github.com/dyninst/dyninst/archive/v13.0.0.tar.gz && \
    tar xvf ./v13.0.0.tar.gz && \
    cd dyninst-13.0.0 && \
    cmake ./CMakeLists.txt && \
    make -j 4 && \
    make install

# spii
RUN if [ ! -d "spii" ]; then git clone https://github.com/PetterS/spii.git; fi && \
    cd spii && \
    cmake ./CMakeLists.txt && \
    make -j && \
    make install

# pe-parse (with submodules)
RUN if [ ! -d "pe-parse" ]; then git clone https://github.com/trailofbits/pe-parse.git; fi && \
    cd pe-parse && \
    git submodule update --init --recursive && \
    sed -i -e 's/-Wno-strict-overflow/-Wno-strict-overflow -Wno-ignored-qualifiers/g' ./cmake/compilation_flags.cmake && \
    mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j && \
    make install

# PicoSHA2
RUN if [ ! -d "PicoSHA2" ]; then git clone https://github.com/okdshin/PicoSHA2.git; fi

# nlohmann/json
RUN mkdir -p json/src && \
    cd json/src && \
    wget https://github.com/nlohmann/json/releases/download/v3.1.2/json.hpp


# Update linker cache
RUN ldconfig

FROM third-party-build AS main-build
# Build the main project
COPY . /code/functionsimsearch
WORKDIR /code/functionsimsearch
RUN make -j 16
RUN ldconfig

FROM main-build AS runtime
# Entrypoint and volume
VOLUME /pwd
WORKDIR /code/functionsimsearch
RUN chmod +x /code/functionsimsearch/entrypoint.sh
ENTRYPOINT ["/code/functionsimsearch/entrypoint.sh"]
# ENTRYPOINT ["/bin/bash"]

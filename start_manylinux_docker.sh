#!/bin/bash

#docker run -it --name manylinux_fss_build \
#  -v "$PWD":/io -w /io \
#  quay.io/pypa/manylinux_2_28_x86_64 /bin/bash
docker start -ai manylinux_fss_build

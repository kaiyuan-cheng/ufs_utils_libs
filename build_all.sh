#! /usr/bin/env bash
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=../install"

rm -fr ./build ./install
mkdir ./build && cd ./build

cmake .. ${CMAKE_FLAGS}

make -j 32 VERBOSE=1

exit

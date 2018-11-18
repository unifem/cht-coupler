#!/bin/sh

# Fix dlopen issue in OpenMPI v2.0
# got from https://github.com/open-mpi/ompi/issues/3705

prefix="/usr/lib/x86_64-linux-gnu/openmpi"
for filename in $(ls $prefix/lib/openmpi/*.so); do
    patchelf --add-needed libmpi.so.20 $filename
    patchelf --set-rpath "\$ORIGIN/.." $filename
done

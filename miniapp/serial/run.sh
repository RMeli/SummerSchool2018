#!/bin/bash

mkdir -p data

srun -Cgpu --reservation=course ./main 128 128 100 0.01 > data/miniapp_128_100.dat
srun -Cgpu --reservation=course ./main 256 256 200 0.01 > data/miniapp_256_200.dat
srun -Cgpu --reservation=course ./main 512 512 200 0.01 > data/miniapp_512_200.dat
srun -Cgpu --reservation=course ./main 1024 1024 400 0.01 > data/miniapp_1024_400.dat

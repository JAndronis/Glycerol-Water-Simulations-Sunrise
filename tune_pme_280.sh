#!/bin/bash

gmx tune_pme -np 128 \
    -s /cfs/home/iaan1799/data/tip4p_glycerol_3p2percent_100A/water_280K_1bar_benchmark/md.tpr \
    -ntpr 1 \
    -resetstep 2500 \
    -mdrun "gmx_mpi mdrun -ntomp 1 -deffnm /cfs/home/iaan1799/data/tip4p_glycerol_3p2percent_100A/water_280K_1bar_benchmark/md"
#!/bin/bash

srun gmx_mpi tune_pme -np 96 \
    -s mdf/water_280K_1bar_25-04-2023_15\:15/md.tpr \
    -resetstep 2500 \
    -mdrun "gmx_mpi mdrun -ntomp 1 -deffnm mdf/water_280K_1bar_25-04-2023_15\:15/md"

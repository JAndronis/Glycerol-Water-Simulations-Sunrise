#!/bin/bash

#SBATCH --partition=fermi
#SBATCH --job-name=iaan1799_cleanup
#SBATCH --ntasks=1

mkdir $2/em
mv $1/em.* $2/em

mkdir $2/npt
mv $1/npt.* $2/npt

mkdir $2/nvt
mv $1/nvt.* $2/nvt

mkdir $2/md
mv $1/md_0_1.* $2/md

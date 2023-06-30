#!/bin/bash

#SBATCH --job-name=Production_Run_Gromacs
#SBATCH --partition=cops
#SBATCH --ntasks=64
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=3-00:00:00

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -o)
            WORK_DIR=$2
            shift
            shift
            ;;
        -f)
            MDP=$2
            shift
            shift
            ;;
        -p)
            TOPOL=$2
            shift
            shift
            ;;
        -g)
            CHECKPOINT=$2
            shift
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "SLURM_CPUS_PER_TASK = ${SLURM_CPUS_PER_TASK}"
echo "SLURM_NTASKS        = ${SLURM_NTASKS}"
echo "SLURM_NNODES        = ${SLURM_NNODES}"


if [ -n "$SLURM_CPUS_PER_TASK" ]; then
    ntomp="$SLURM_CPUS_PER_TASK"
else
    ntomp=1
fi

if [ -n "$CHECKPOINT" ]; then
    cpi="-cpi md"
    tpr="$WORK_DIR/md_next.tpr"
else
    cpi=""
    tpr="$WORK_DIR/md.tpr"
    gmx grompp -f $MDP -c $WORK_DIR/npt.gro -r $WORK_DIR/npt.gro -p $TOPOL -o $tpr
fi

# set environment variable
export OMP_NUM_THREADS=$ntomp

# run npt

if [[ "${SLURM_NNODES}" -gt "1" ]]; then
    NP="-np $SLURM_NTASKS"
    export MPIRUN="$HOME/openmpi-4.1.5/build/bin/mpirun --mca opal_warn_on_missing_libcuda 0"
    gmx tune_pme \
      $NP -s $tpr -steps 9000 -resetstep 6000 -p $WORK_DIR/perf.out \
      -mdrun "gmx_mpi mdrun -ntomp $ntomp" -deffnm $WORK_DIR/md -launch
else
    echo $SLURM_NNODES
    NTMPI="-ntmpi $SLURM_NTASKS"
    gmx tune_pme \
      $NTMPI -s $tpr -steps 9000 -resetstep 6000 -p $WORK_DIR/perf.out \
      -mdrun "gmx mdrun -ntomp $ntomp" -deffnm $WORK_DIR/md -launch
fi
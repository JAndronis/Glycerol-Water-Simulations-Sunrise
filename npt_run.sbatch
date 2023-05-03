#!/bin/bash

#SBATCH --job-name=NPT_Equilibration
#SBATCH --ntasks=96
#SBATCH --time=7-00:00:00
#SBATCH --mem=32G

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

echo "OUTPUT PATH     = ${WORK_DIR}"
echo "MDP FILE        = ${MDP}"
echo "BOX             = ${BOX}"
echo "TOPOLOGY FILE   = ${TOPOL}"
echo -e "Submitting job...\n"

if [ $SLURM_JOB_NUM_NODES -gt 1 ]; then
    GMX="gmx_mpi"
    MPIRUN="mpirun -np $SLURM_NTASKS"
    ntmpi=""
else
    GMX="gmx_mpi"
    MPIRUN="srun -n $SLURM_NTASKS"
    ntmpi="-ntmpi $SLURM_NTASKS"
fi

if [ -n "$SLURM_CPUS_PER_TASK" ]; then
    threads="$SLURM_CPUS_PER_TASK"
else
    threads=1
fi


if [ -n "$CHECKPOINT" ]; then
    cpi="-cpi $WORK_DIR/npt"
    tpr="-s $WORK_DIR/npt.tpr"
else
    cpi=""
    tpr=""
    srun -n 1 gmx_mpi grompp -f $MDP -c $WORK_DIR/nvt.gro -r $WORK_DIR/nvt.gro -p $TOPOL -o $WORK_DIR/npt.tpr
fi

# set OpenMP
ntomp="-ntomp ${threads}"

# set environment variable
export OMP_NUM_THREADS=$threads

# run npt
echo "Run command: $MPIRUN $GMX mdrun $ntmpi -ntomp $ntomp $cpi $tpr -deffnm $WORK_DIR/npt"
$MPIRUN $GMX mdrun $ntmpi $ntomp $cpi $tpr -deffnm $WORK_DIR/npt 


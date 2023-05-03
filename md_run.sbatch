#!/bin/bash

#SBATCH --job-name=Production_Run_Gromacs
#SBATCH --ntasks=96
#SBATCH --time=4-00:00:00
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

# echo "Running production run..."
# echo "OUTPUT PATH     = ${WORK_DIR}"
# echo "MDP FILE        = ${MDP}"
# echo "TOPOLOGY FILE   = ${TOPOL}"
# echo -e "Submitting job...\n"

echo "SLURM_CPUS_PER_TASK = ${SLURM_CPUS_PER_TASK}"
echo "SLURM_NTASKS        = ${SLURM_NTASKS}"

if [ $SLURM_JOB_NUM_NODES -gt 1 ]; 
then
    GMX="gmx_mpi"
    MPIRUN="mpirun -np $SLURM_NTASKS"
    ntmpi=""
else
    GMX="gmx_mpi"
    MPIRUN="srun -n $SLURM_NTASKS"
    ntmpi="-ntmpi $SLURM_NTASKS"
fi

if [ -n "$SLURM_CPUS_PER_TASK" ]; 
then
    threads=$SLURM_CPUS_PER_TASK
else
    threads=1
fi


if [ -n "$CHECKPOINT" ]; 
then
    cpi="-cpi $WORK_DIR/md"
    tpr="-s $WORK_DIR/md.tpr"
else
    cpi=""
    tpr=""
    srun -n 1 gmx_mpi grompp -f $MDP -c $WORK_DIR/npt.gro -t $WORK_DIR/npt.cpt -p $TOPOL -o $WORK_DIR/md.tpr
fi

# set OpenMP
ntomp="-ntomp ${threads}"

# set environment variable
export OMP_NUM_THREADS=$threads

# run md
echo "Run command: $MPIRUN $GMX mdrun $ntmpi $ntomp -deffnm $WORK_DIR/md"
$MPIRUN $GMX mdrun $ntmpi $ntomp $tpr $cpi -deffnm $WORK_DIR/md -npme 24


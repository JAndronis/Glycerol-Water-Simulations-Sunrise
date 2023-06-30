#!/bin/bash

#SBATCH --job-name=NVT_equilibration
#SBATCH --partition=ampere
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=16G
#SBATCH --time=5-00:00:00

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

export GMX_ENABLE_DIRECT_GPU_COMM=1

if [ -n "$SLURM_CPUS_PER_TASK" ]; then
    ntomp="$SLURM_CPUS_PER_TASK"
else
    ntomp="1"
fi

if [ -n "$CHECKPOINT" ]; then
    cpi="-cpi $WORK_DIR/nvt"
    tpr="$WORK_DIR/nvt_next.tpr"
else
    cpi=""
    tpr="$WORK_DIR/nvt.tpr"
    gmx grompp -f $MDP -c $WORK_DIR/em.gro -r $WORK_DIR/em.gro -p $TOPOL -o $tpr
fi

export OMP_NUM_THREADS=$ntomp

# gmx_mpi grompp -f $MDP -c $WORK_DIR/em.gro -r $WORK_DIR/em.gro -p $TOPOL -o $WORK_DIR/nvt.tpr
# mpirun -np $SLURM_NTASKS gmx_mpi mdrun -ntomp $ntomp -v -deffnm $WORK_DIR/nvt -pin on -npme 1

export OMP_NUM_THREADS=$ntomp

$HOME/sw/gromacs-thread/2023.1/bin/gmx mdrun \
    -s $tpr -pme gpu -pmefft gpu -nb gpu -bonded gpu -pin on -pinstride 1 \
    -ntmpi $SLURM_NTASKS -ntomp $SLURM_CPUS_PER_TASK -deffnm $WORK_DIR/nvt $cpi

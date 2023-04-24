#!/bin/bash

#SBATCH --job-name=NPT_Equilibration
#SBATCH --ntasks=128
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

echo "OUTPUT PATH     = ${WORK_DIR}"
echo "MDP FILE        = ${MDP}"
echo "BOX             = ${BOX}"
echo "TOPOLOGY FILE   = ${TOPOL}"
echo -e "Submitting job...\n"

if [ $SLURM_JOB_NUM_NODES -gt 1 ]; then
    GMX="gmx_mpi"
    MPIRUN="mpirun"
    ntmpi=""
else
    GMX="gmx"
    MPIRUN=""
    ntmpi="-ntmpi $SLURM_NTASKS"
fi

if [ -n "$SLURM_CPUS_PER_TASK" ]; then
    ntomp="$SLURM_CPUS_PER_TASK"
else
    ntomp="1"
fi

if [ -n $CHECKPOINT ]; then
    cpi="-cpi ${WORK_DIR}/npt"
else
    cpi=""
    $GMX grompp -f $MDP -c $WORK_DIR/nvt.gro -r $WORK_DIR/nvt.gro -t $WORK_DIR/nvt.cpt -p $TOPOL -o $WORK_DIR/npt.tpr
fi

export OMP_NUM_THREADS=$ntomp

# run npt
$MPIRUN $GMX mdrun $ntmpi -ntomp $ntomp -deffnm $WORK_DIR/npt $cpi

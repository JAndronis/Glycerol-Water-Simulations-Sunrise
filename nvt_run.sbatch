#!/bin/bash

#SBATCH --job-name=NVT_equilibration
#SBATCH --ntasks=96
#SBATCH --time=2-00:00:00

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

if [ -n "$SLURM_CPUS_PER_TASK" ]; then
    ntomp="$SLURM_CPUS_PER_TASK"
else
    ntomp="1"
fi

export OMP_NUM_THREADS=$ntomp

srun -n 1 gmx_mpi grompp -f $MDP -c $WORK_DIR/em.gro -r $WORK_DIR/em.gro -p $TOPOL -o $WORK_DIR/nvt.tpr
mpirun -n $SLURM_NTASKS gmx_mpi mdrun -ntomp $ntomp -deffnm $WORK_DIR/nvt

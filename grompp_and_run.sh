#! /bin/bash

# Argument parse
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-path)
            WORK_DIR=$2
            shift
            shift
            ;;
        -f|--mdp-directory)
            MDP=$2
            shift
            shift
            ;;
        -t|--topology)
            TOPOL=$2
            shift
            shift
            ;;
        -b|--box)
            BOX=$2
            shift
            shift
            ;;
        --temp)
            TEMP=$2
            shift
            shift
            ;;
        -p|--partition)
            PARTITION=$2
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

# print run args
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "OUTPUT PATH     = ${WORK_DIR}"
echo "MDP PATH        = ${MDP}"
echo "BOX FILE        = ${BOX}"
echo "TOPOLOGY FILE   = ${TOPOL}"
echo -e "Submitting job...\n"

# directory management
DT=$(date "+%d-%m-%Y_%H:%M")
OUT_DIR_NAME="${WORK_DIR}/water_${TEMP}K_sim_${DT}"
mkdir $OUT_DIR_NAME

# log file
LOG="water_${TEMP}K_sim_job.log"
touch $OUT_DIR_NAME/$LOG

# MDP files
# Make temp copies
TEMP_MDP_DIR="mdp_30A_${TEMP}K_temp"
if [ -d "${TEMP_MDP_DIR}" ]; then
	rm -rf $TEMP_MDP_DIR
fi
cp -r $MDP $TEMP_MDP_DIR
EM_MDP="${TEMP_MDP_DIR}/em.mdp"
NVT_MDP="${TEMP_MDP_DIR}/nvt.mdp"
NPT_MDP="${TEMP_MDP_DIR}/npt.mdp"
MD_MDP="${TEMP_MDP_DIR}/md.mdp"

# change temp
sed -i "s/^ref_t\s*=.*/ref_t = ${TEMP}/" "${NPT_MDP}"
sed -i "s/^ref_t\s*=.*/ref_t = ${TEMP}/" "${MD_MDP}"

# Run Jobs
jid_em_run=$(sbatch -p $PARTITION --output=$OUT_DIR_NAME/$LOG --open-mode=append --parsable em_run.sbatch -o $OUT_DIR_NAME -f $EM_MDP -p $TOPOL -c $BOX)

jid_nvt_run=$(sbatch -p $PARTITION -c 2 --output=$OUT_DIR_NAME/$LOG --open-mode=append --parsable --dependency=afterok:$jid_em_run nvt_run.sbatch -o $OUT_DIR_NAME -f $NVT_MDP -p $TOPOL)

jid_npt_run=$(sbatch -p $PARTITION -c 2 --output=$OUT_DIR_NAME/$LOG --open-mode=append --parsable --dependency=afterok:$jid_nvt_run npt_run.sbatch -o $OUT_DIR_NAME -f $NPT_MDP -p $TOPOL)

jid_md_run=$(sbatch -p $PARTITION -c 2 --output=$OUT_DIR_NAME/$LOG --open-mode=append --parsable --dependency=afterok:$jid_npt_run md_run.sbatch -o $OUT_DIR_NAME -f $MD_MDP -p $TOPOL)


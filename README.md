
# Glycerol - Water MD Simulations on the Sunrise Cluster @ Fysikum

This is a directory contains code and instructions for running MD simulations of glycerol in water on the Sunrise cluster at Fysikum. The shell scripts will run simulations utilizing the [GROMACS](https://manual.gromacs.org/2023/) suite.

## Setup

To generate the required topology and structure files, we first have to activate the nix-shell interactive environment. To do so, we have to either be logged in the sol-nix login node, or use `module activate nix`. To activate the shell we run:

```shell
nix-shell -p qchem-unstable.gromacs
```

Ignore any "implausibly old time stamp" warnings. Now we have access to the `gmx` command.

> If the simulation we are planning to run requires more than 1 node it is suggested to activate nix shell with the package `qchem-unstable.gromacsMpi` to gain access to the command `gmx_mpi`, that will utilize OpenMP rather than Thread MPI. In addition the `gmx` program that is used in this scenario is compiled with SSE4.1 SIMD instructions, which will not utilize the full potential of most Sunrise CPUs.

The next step is to create the glycerol solution:

```shell
mkdir mdf
touch mdf/glycerol.top
```

Paste in the topology file:

```text
#include "../charmm36-jul2022.ff/forcefield.itp"

; additional params for the molecule

#include "../molecules/glycerol.itp"

#include "../charmm36-jul2022.ff/tip4p.itp"
#ifdef POSRES_WATER
; Position restraint for each water oxygen
[ position_restraints ]
;  i funct		 fcx		fcy		   fcz
   1	1		1000	   1000		  1000
#endif

; Include topology for ions
#include "../charmm36-jul2022.ff/ions.itp"

[ system ]
; Name
glycerol in water

[ molecules ]
; Compound  #mols
glycerol    320
```

Place glycerol in a 100x100x100 Å box:

```shell
gmx insert-molecules -ci molecules/glycerol.pdb -nmol 320 -box 10 10 10 -o mdf/glycerol_box.gro
```

Add water:

```shell
gmx solvate -cp mdf/glycerol_box -cs tip4p -o mdf/glycerol_solv.gro -p mdf/glycerol.top -maxsol 9680
```

## Run the simulation

All the necessary steps have already been hardcoded in the `grompp_and_run.sh` file. To run the simulation, we simply have to run the following command:

```shell
./grompp_and_run.sh -o /cfs/data/your/data/directory -f mdp -t mdf/glycerol.top -b mdf/glycerol_solv.gro -p cops --temp 270 --pressure 1
```

> The flags for the `grompp_and_run.sh` script are as follows:
>
> - `[-o | --output-path]` - output directory where the md simulation data will be stored
> - `[-f | --mdp-directory]` - directory containing the original mdp files. These files will be copied and adjusted according to the provided temperature and then placed in a new directory
> - `[-t | --topology]` - topology file
> - `[-b | --box]` - structure file
> - `[-p | --partition]` - SLURM queue/partition
> - `--temp` - temperature of the simulation (in Kelvin)
> - `--pressure` - pressure of the simulation (in bar)
>

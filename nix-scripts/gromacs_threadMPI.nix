{}:

let
  v = import ./versions.nix;
  nixpkgs = builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/${v.nixpkgs}.tar.gz";
  overlay = builtins.fetchTarball "https://github.com/markuskowa/NixOS-QChem/archive/${v.qchem}.tar.gz";

  pkgs = import nixpkgs {
    config = {
      allowUnfree = true;
      qchem-config = {
       optAVX = true;
      };
    };
    overlays = [
      (import "${overlay}/overlay.nix")
    ];
  };


in pkgs.mkShell {
  buildInputs = with pkgs; [
    # OpenMP only version (no MPI)
    qchem.gromacs
  ];

  shellHook = ''
    if [ -z $SLURM_CPUS_PER_TASK ]; then
      export OMP_NUM_THREADS=1
    else
      export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
    fi

    export GMX=gmx
  '';
}


import matplotlib.pyplot as plt
import pandas as pd
import argparse


if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-f",
        "--energy-file",
        type=str,
        help="Path to Trajectory files (.xtc | .trr | ...).)",
    )
    parser.add_argument(
        "-w",
        "--window",
        default=100,
        type=int,
        help="Rolling average window"
    )
    parser.add_argument(
        "-k1",
        default="density",
        type=str,
        help="Y-axis 1 to plot."
    )
    parser.add_argument(
        "-k2",
        type=str,
        help="Y-axis 2 to plot."
    )
    args = parser.parse_args()
    
    data = []
    scaling = 1e-3 # to ns
    t, energy, temp, pressure, volume, density = [], [], [], [], [], []
    with open(args.energy_file) as f:
        for line in f:
            if line.startswith("#") or line.startswith("@"):
                continue
            cols = line.split()
            t.append(float(cols[0]) * scaling)
            energy.append(float(cols[1]))
            temp.append(float(cols[2]))
            pressure.append(float(cols[3]))
            if len(cols) > 5:
                volume.append(float(cols[4]))
                density.append(float(cols[5]))
            else:
                density.append(float(cols[4]))
    df = pd.DataFrame({"energy": energy,
                       "temperature": temp, 
                       "pressure": pressure,
                       "density": density}, 
                      index=t)
    
    window = args.window
    key1 = args.k1
    key2 = args.k2
    fig, ax1 = plt.subplots()
    x = df.index.to_numpy()
    y1 = df[key1].rolling(window).mean()
    err1 = df[key1].rolling(window).std()
    
    ax1.plot(y1, c='b')
    ax1.fill_between(x, y1-err1, y1+err1, 
                     alpha=0.3, 
                     color='b',
                     edgecolor=None)
    ax1.set_ylabel(r'$\rho (kg/m^3$)', c='b', fontsize=14)
    ax1.set_xlabel(r'$t (ns)$', fontsize=14)
    ax1.set_title(f'T = {df["temperature"].mean():.00f}', fontsize=14)
    ax1.tick_params(labelsize=14)
    
    if key2 is not None:
        ax1.tick_params(c='b')
        y2 = df[key2].rolling(window).mean()
        err2 = df[key2].rolling(window).std()
        ax2 = ax1.twinx()
        ax2.plot(y2, c='red')
        ax2.fill_between(x, y2-err2, y2+err2, 
                         alpha=0.3, 
                         color='red', 
                         edgecolor=None)
        ax2.set_ylabel(r'$U (kJ/mol)$', c='r', fontsize=14)
        ax2.tick_params(labelsize=14, c='r')
    plt.savefig("energy_plots.png", dpi=150)
    plt.close()

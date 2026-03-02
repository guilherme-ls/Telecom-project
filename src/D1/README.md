# D1

## How to run 

The main file for this part is `main.m`. So to run this section of the project,
call `main`.

### Warnings 

This simulation chain uses some heuristics to speed up the simulation and get more precise results 
as the SNR increases. This means you might see a greater CPU and memory usage as the simulations 
get more complex. That is normal, and you always limit the amount of resources used by modifying the 
_global simulation parameters_.

### Configurations

This file automates several steps of simulation, given a lot of control if needed.
These are the configurations that can be tuned to get the desired results.

#### Debug Variables

| Name          | Values        | Description |
| ------------- | ------------- | ----------- |      
| plot\_graphs  | true / false  | Selects if plots should be generated as the simulation progresses. |

#### Script Output Variables

| Name           | Values        | Description |
| -------------  | ------------- | ----------- |      
| output\_folder | string        | Relative path for the folder where the simulation .csv will be stored. |
| force\_generate | true / false | Selects if the simulation should re-run even if the .csv was already generated. |

#### Global Simulation Parameters

| Name           | Values        | Description |
| -------------  | ------------- | ----------- |      
| syndrome\_table\_file\_fmt | string | The file name format the syndrome table files are to be stores and loaded. |
| min\_frame\_number | integer | The minimal amount of frames to be simulated in the same simulation iteration.  |
| max\_simultaneous\_frame\_simulation | integer |The maximal amount of frames to be simulated in the same simulation iteration. |
| min\_error\_bits\_per\_snr | integer | One of the simulations stop conditions, the minimal amount of error bits detected to stop the iterations for a specific SNR. |
| max\_simulation\_iterations | integer | One of the simulations stop conditions, the maximal amount of iterations a specific SNR can have. |

#### Simulated Simulation Parameters

These values are here for documentation, and are to be referenced if you want to create a
new simulation or understand the ones in `main.m`. 

| Name           | Values        | Description |
| -------------  | ------------- | ----------- |      
| frame\_size | integer | The size of a single simulated frame. |
| modulation | 'PSK' / 'QAM' | The modulation type. |
| M | integer | The size of the constellation for the modulation. |
| channel | 0 / 1 / 2 / 3 | The channel to be used for the simulation. |
| equalization | 'none' / 'ZF' / 'DFE' | The equalizer to be used in the simulation. |
| bch\_code\_option | 0 / 1 / 2 | The BCH code to be used, "0" means none. |
| Ts | real |  The time interval of each symbol. |
| normalize\_symbol\_energy | true / false | Selects if Es = 1 or Eb = 1. |
| snr\_bits | interval | The interval of SNR values for the simulation to run on. |

### Output Files 

This script might generate several files, here are the ones that are important to know about:

#### Syndrome Tables

These files are generated when you run a simulation using a BCH code. They store the precalculated
syndrome table, and can be found at the root folder (the one with this README) with 
the extension `.mat`.

If you make any modifications to the BCH code parameters, or change the `bch_mod_g` function, 
delete these, otherwise you will have inconsistent results.

#### The `out` Folder 

When you run `main.m`, you will notice that a folder called `out` is generated, it contains the 
BER vs SNR results simulated in `.csv` for easy addition to the final report. You can change 
this path to whichever you desire by changing the path in `output_folder`.

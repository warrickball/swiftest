import numpy as np
import matplotlib.pyplot as plt
import os
import Init_Cond as ic
from scipy.io import FortranFile

figure = plt.figure(1, figsize=(8,9))
axes = {'a' : figure.add_subplot(321),
        'b' : figure.add_subplot(322),
        'c' : figure.add_subplot(323),
        'd' : figure.add_subplot(324),
        'e' : figure.add_subplot(325),
        'f' : figure.add_subplot(326)}
xmin = 1.0
xmax = 5.0
ymin = 1.0
ymax = 5e4

y2min = 1e13
y2max = 1e26
secaxes = {}

for key in axes:
    axes[key].set_xlim(xmin,xmax)
    axes[key].set_ylim(ymin, ymax)
    axes[key].set_xlabel('Distance to Uranus (RU)')
    axes[key].set_ylabel('$\Sigma$ (g$\cdot$cm$^{-2}$)')
    axes[key].set_yscale('log')
    secaxes[key] = axes[key].twinx()
    secaxes[key].set_yscale('log')
    secaxes[key].set_ylabel('Mass of satellite (g)')
    secaxes[key].set_ylim(y2min, y2max)


ring = {}
seeds = {}

with FortranFile('ring.dat', 'r') as f:
    while True:
        try:
            t = f.read_reals(np.float64)
        except:
            break
        Nbin = f.read_ints(np.int32)
        r = f.read_reals(np.float64)
        Gsigma = f.read_reals(np.float64)
        nu = f.read_reals(np.float64)
        kval = int(t / ic.t_print)
        ring[kval] = [r, Gsigma, nu]
        Nseeds = f.read_ints(np.int32)
        a = f.read_reals(np.float64)
        Gm = f.read_reals(np.float64)
        seeds[kval] = [a, Gm]

ring_cgs = {}
seeds_cgs = {}
with FortranFile('ring_cgs.dat', 'r') as f:
    while True:
        try:
            t = f.read_reals(np.float64)
        except:
            break
        Nbin = f.read_ints(np.int32)
        r = f.read_reals(np.float64)
        Gsigma = f.read_reals(np.float64)
        nu = f.read_reals(np.float64)
        kval = int(t / (1e6 * ic.year))
        ring_cgs[kval] = [r, Gsigma, nu]
        Nseeds = f.read_ints(np.int32)
        a = f.read_reals(np.float64)
        Gm = f.read_reals(np.float64)
        seeds_cgs[kval] = [a, Gm]


#convert the units
for key in ring:
    ring[key][0] /= ic.RP  #convert radius to planet radius
    ring[key][1] *= ic.MU2GM / ic.DU2CM**2 / ic.GU  # convert surface mass density to cgs
    ring[key][2] *= ic.DU2CM**2 / ic.TU2S # convert viscosity to cgs
    seeds[key][0] /= ic.RP
    seeds[key][1] *= ic.MU2GM / ic.GU

for key in ring_cgs:
    ring_cgs[key][0] /= ic.R_Uranus  # convert radius to planet radius
    ring_cgs[key][1] /= ic.G   # convert surface mass density to cgs
    seeds_cgs[key][0] /= ic.R_Uranus
    seeds_cgs[key][1] /= ic.G

# These are the output times to plot

#tout = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0]) * ic.t_print #* ic.year / ic.TU2S
nt = np.array([0,1,10,100,200,720]).astype(int) #np.rint(tout / ic.t_print).astype(int)

tn = {  'a' : nt[0],
        'b' : nt[1],
        'c' : nt[2],
        'd' : nt[3],
        'e' : nt[4],
        'f' : nt[5]}

for key in axes:
    axes[key].plot(ring_cgs[tn[key]][0], ring_cgs[tn[key]][1], '-', color="blue", linewidth=1.0, zorder = 40)
    secaxes[key].scatter(seeds_cgs[tn[key]][0], seeds_cgs[tn[key]][1], marker='o', color="blue", s=1.5, zorder = 40)
    axes[key].plot(ring[tn[key]][0], ring[tn[key]][1], '-', color="black", linewidth=1.0, zorder = 50, label = "SyMBA-RINGMOONS")
    secaxes[key].scatter(seeds[tn[key]][0], seeds[tn[key]][1], marker='o', color="black", s=1, zorder = 50)
    axes[key].title.set_text(f'${tn[key]*ic.t_print*ic.TU2S/ic.year * 1e-6:5.1f}$ My')
#axes['a'].legend(loc='upper left',prop={'size': 8})
figure.tight_layout()
#plt.show()

figname = "Uranus_ring_satellite_evoloution.png"
plt.savefig(figname,dpi=300 )
os.system(f'open {figname}')


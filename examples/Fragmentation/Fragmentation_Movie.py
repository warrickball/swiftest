"""
 Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
 This file is part of Swiftest.
 Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
 of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 You should have received a copy of the GNU General Public License along with Swiftest. 
 If not, see: https://www.gnu.org/licenses. 
"""

#!/usr/bin/env python3
"""
Generates a movie of a fragmentation event from set of Swiftest output files.

Inputs
_______
param.in : ASCII text file
    Swiftest parameter input file.
out.nc   : NetCDF file
    Swiftest output file.

Returns
-------
fragmentation.mp4 : mp4 movie file
    Movie of a fragmentation event.
"""

import swiftest
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from pathlib import Path

# ----------------------------------------------------------------------------------------------------------------------
# Define the names and initial conditions of the various fragmentation simulation types
# ----------------------------------------------------------------------------------------------------------------------
available_movie_styles = ["disruption_headon", "supercatastrophic_off_axis", "hitandrun"]
movie_title_list = ["Head-on Disruption", "Off-axis Supercatastrophic", "Hit and Run"]
movie_titles = dict(zip(available_movie_styles, movie_title_list))

# These initial conditions were generated by trial and error
pos_vectors = {"disruption_headon"         : [np.array([1.0, -2.807993e-05, 0.0]),
                                              np.array([1.0,  2.807993e-05 ,0.0])],
               "supercatastrophic_off_axis": [np.array([1.0, -4.2e-05,      0.0]),
                                              np.array([1.0,  4.2e-05,      0.0])],
               "hitandrun"                 : [np.array([1.0, -2.0e-05,      0.0]),
                                              np.array([0.999999,  2.0e-05,      0.0])]
               }

vel_vectors = {"disruption_headon"         : [np.array([-2.562596e-04,  6.280005, 0.0]),
                                              np.array([-2.562596e-04, -6.280005, 0.0])],
               "supercatastrophic_off_axis": [np.array([0.0,            6.28,     0.0]),
                                              np.array([1.0,           -6.28,     0.0])],
               "hitandrun"                 : [np.array([0.0,            6.28,     0.0]),
                                              np.array([-0.1,          -6.28,     0.0])]
               }

rot_vectors = {"disruption_headon"         : [np.array([0.0, 0.0, 0.0]),
                                              np.array([0.0, 0.0, 0.0])],
               "supercatastrophic_off_axis": [np.array([0.0, 0.0, -6.0e4]),
                                              np.array([0.0, 0.0, 1.0e5])],
               "hitandrun"                 : [np.array([0.0, 0.0, 6.0e4]),
                                              np.array([0.0, 0.0, 1.0e5])]
               }

body_Gmass = {"disruption_headon"        : [1e-7, 1e-10],
             "supercatastrophic_off_axis": [1e-7, 1e-8],
             "hitandrun"                 : [1e-7, 7e-10]
               }

density = 3000 * swiftest.AU2M**3 / swiftest.MSun
GU = swiftest.GMSun * swiftest.YR2S**2 / swiftest.AU2M**3
body_radius = body_Gmass.copy()
for k,v in body_Gmass.items():
    body_radius[k] = [((Gmass/GU)/(4./3.*np.pi*density))**(1./3.) for Gmass in v]


# ----------------------------------------------------------------------------------------------------------------------
# Define the animation class that will generate the movies of the fragmentation outcomes
# ----------------------------------------------------------------------------------------------------------------------
figsize = (4,4)
class AnimatedScatter(object):
    """An animated scatter plot using matplotlib.animations.FuncAnimation."""

    def __init__(self, sim, animfile, title, nskip=1):
        nframes = int(sim.enc['time'].size)
        self.sim = sim
        self.title = title
        self.body_color_list = {'Initial conditions': 'xkcd:windows blue',
                      'Disruption': 'xkcd:baby poop',
                      'Supercatastrophic': 'xkcd:shocking pink',
                      'Hit and run fragment': 'xkcd:blue with a hint of purple',
                      'Central body': 'xkcd:almost black'}

        # Set up the figure and axes...
        self.fig, self.ax = self.setup_plot()

        # Then setup FuncAnimation.
        self.ani = animation.FuncAnimation(self.fig, self.update_plot, interval=1, frames=range(0,nframes,nskip),
                                           blit=True)
        self.ani.save(animfile, fps=60, dpi=300, extra_args=['-vcodec', 'libx264'])
        print(f"Finished writing {animfile}")

    def setup_plot(self):
        fig = plt.figure(figsize=figsize, dpi=300)
        plt.tight_layout(pad=0)


        # Calculate the distance along the y-axis between the colliding bodies at the start of the simulation.
        # This will be used to scale the axis limits on the movie.
        rhy1 = sim.enc['rh'].isel(time=0).sel(name="Body1",space='y').values[()]
        rhy2 = sim.enc['rh'].isel(time=0).sel(name="Body2",space='y').values[()]

        scale_frame =   abs(rhy1) + abs(rhy2)
        ax = plt.Axes(fig, [0.1, 0.1, 0.8, 0.8])
        self.ax_pt_size = figsize[0] * 0.8 *  72 / (2 * scale_frame)
        ax.set_xlim(-scale_frame, scale_frame)
        ax.set_ylim(-scale_frame, scale_frame)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_xlabel("x")
        ax.set_ylabel("y")
        ax.set_title(self.title)
        fig.add_axes(ax)

        self.scatter_artist = ax.scatter([], [], animated=True)
        return fig, ax

    def update_plot(self, frame):
        # Define a function to calculate the center of mass of the system.
        def center(Gmass, x, y):
            x = x[~np.isnan(x)]
            y = y[~np.isnan(y)]
            Gmass = Gmass[~np.isnan(Gmass)]
            x_com = np.sum(Gmass * x) / np.sum(Gmass)
            y_com = np.sum(Gmass * y) / np.sum(Gmass)
            return x_com, y_com

        Gmass, rh, point_rad = next(self.data_stream(frame))
        x_com, y_com = center(Gmass, rh[:,0], rh[:,1])
        self.scatter_artist.set_offsets(np.c_[rh[:,0] - x_com, rh[:,1] - y_com])
        self.scatter_artist.set_sizes(point_rad**2)
        return self.scatter_artist,

    def data_stream(self, frame=0):
        while True:
            ds = self.sim.enc.isel(time=frame)
            ds = ds.where(ds['name'] != "Sun", drop=True)
            radius = ds['radius'].values
            Gmass = ds['Gmass'].values
            rh = ds['rh'].values
            point_rad = 2 * radius * self.ax_pt_size
            yield Gmass, rh, point_rad

if __name__ == "__main__":

   print("Select a fragmentation movie to generate.")
   print("1. Head-on disruption")
   print("2. Off-axis supercatastrophic")
   print("3. Hit and run")
   print("4. All of the above")
   user_selection = int(input("? "))

   if user_selection > 0 and user_selection < 4:
      movie_styles = [available_movie_styles[user_selection-1]]
   else:
      print("Generating all movie styles")
      movie_styles = available_movie_styles.copy()

   for style in movie_styles:
       movie_filename = f"{style}.mp4"

       # Pull in the Swiftest output data from the parameter file and store it as a Xarray dataset.
       sim = swiftest.Simulation(simdir=style, rotation=True, init_cond_format = "XV", compute_conservation_values=True)
       sim.add_solar_system_body("Sun")
       sim.add_body(Gmass=body_Gmass[style], radius=body_radius[style], rh=pos_vectors[style], vh=vel_vectors[style]) #, rot=rot_vectors[style])

       # Set fragmentation parameters
       minimum_fragment_gmass = 0.2 * body_Gmass[style][1] # Make the minimum fragment mass a fraction of the smallest body
       gmtiny = 0.99 * body_Gmass[style][1] # Make GMTINY just smaller than the smallest original body. This will prevent runaway collisional cascades
       sim.set_parameter(fragmentation=True, fragmentation_save="TRAJECTORY", gmtiny=gmtiny, minimum_fragment_gmass=minimum_fragment_gmass, verbose=False)
       sim.run(dt=1e-5, tstop=2.0e-3, istep_out=1, dump_cadence=0)

       anim = AnimatedScatter(sim,movie_filename,movie_titles[style],nskip=1)

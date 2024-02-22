import argparse
import pathlib

import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("steps", help="number of time steps to simulate", type=int)
args = parser.parse_args()
print(args.steps)

#launch Isaac Sim before any other imports
#default first two lines in any standalone application
from omni.isaac.kit import SimulationApp

simulation_app = SimulationApp({"headless": True})

import omni
from omni.isaac.core import World
from omni.isaac.core.objects import DynamicCuboid

world = World()
world.scene.add_default_ground_plane()
fancy_cube =  world.scene.add(
    DynamicCuboid(
        prim_path="/World/random_cube",
        name="fancy_cube",
        position=np.array([0, 0, 1.0]),
        scale=np.array([0.5015, 0.5015, 0.5015]),
        color=np.array([0, 0, 1.0]),
    ))
# Resetting the world needs to be called before querying anything related to an articulation specifically.
# Its recommended to always do a reset after adding your assets, for physics handles to be propagated properly
world.reset()
for i in range(args.steps):
    position, orientation = fancy_cube.get_world_pose()
    linear_velocity = fancy_cube.get_linear_velocity()
    # will be shown on terminal
    print("Cube position is : " + str(position))
    print("Cube's orientation is : " + str(orientation))
    print("Cube's linear velocity is : " + str(linear_velocity))
    # we have control over stepping physics and rendering in this workflow
    # things run in sync
    world.step(render=True) # execute one physics step and one rendering step

output = f"""\
Simulation steps : {args.steps}
Cube position is : {position}
Cube's orientation is : {orientation}
Cube's linear velocity is : {linear_velocity}

"""

# The results could be written to a file or to Nucleus
# (1) Write to output file
pathlib.Path("/results").mkdir(parents=True, exist_ok=True)
with open("/results/isaac-sim-simulation-example.txt", "w") as file:
    file.write(output)

# (2) Write to Nucleus
result = omni.client.write_file("omniverse://localhost/Projects/J3soon/Isaac/2023.1.1/Outputs/isaac-sim-simulation-example.txt", output.encode())
print(result)

simulation_app.close() # close Isaac Sim

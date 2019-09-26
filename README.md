# OBNI 3D | Objet Bruité Non Identifié 3D

## Installation

### Git users

Clone this repository and do submodule init and update in order to get the Unity-Noises submodule.

```git submodule update --init --recursive```

### Non-git users
Download this repository and add it to your Unity project.

Download the [Unity-Noises](url=https://github.com/Theoriz/Unity-Noises) repository and add it inside the OBNI3D/Plugins directory.

## Quick Start

1. Create a new material and assign the OBNI3D shader to it.
2. Add the material to an object in your scene.
3. Create a new gameobject in your scene and add the NoiseVolume.cs script to it.
4. Play !

Note that only vertices of an object with the ONBI3D shader that are inside a NoiseVolume will be affected by noise.

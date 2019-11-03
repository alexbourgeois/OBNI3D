# OBNI 3D - Objet Bruité Non Identifié 3D

## Presentation

This tool allows you to simply deform an object using noise volumes. Those volumes are gameobjects with a NoiseVolume component.
All vertices of an object with the ONBI3D shader that are inside a NoiseVolume will be affected by noise or mask.

<p align="center">
<img src="https://github.com/alexbourgeois/images/blob/master/OBNI/obni3d-fig01.png">
</p>


## Noises
 Two noises are available : Simplex and Voronoi.

Volumes blend themselves when they affect the same vertex according to their own blend operator : addition, soustraction, multiplication, division and modulo.

## Mask

A mask is a volume that cancel any noise in its area of effect allowing you to prevent any displacement in its area.

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



## Demo

The demo project can be found here : https://github.com/alexbourgeois/OBNI3D-demo 


## Renders

You can find renders I made on my instagram : https://www.instagram.com/sioegroub/?hl=fr or on my Art Station : https://www.artstation.com/alexbourgeois

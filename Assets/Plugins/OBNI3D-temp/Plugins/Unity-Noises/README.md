# Unity-Noises

Collection of GPU HLSL noises functions for Unity with :

- 3D Perlin Noise
- 3D Periodic Perlin Noise
- 3D Simplex Noise
- 3D Voronoi Noise

## How to use

The noise functions are all in the .hlsl files in the /Includes/ directory.

Examples of wrapping of these functions for CustomRenderTextures are in the /Examples/ directory for each type of noise. The parameters of each noises are accessible through the corresponding material.

You can use these textures as maps for your material, or write your own material shader using the noise functions directly (recommended for better performance).

### Time control

Unity shader time is unaffected by the game time scale, therefore noises based on shader time will not be synchronized with the rest of the game which can be problematic (when recording for example).

To use the game time instead of shader time in the noises shaders, add the ShaderTimeController.cs script to your scene and set the _IsTimeControlled parameter of the shaders to 1.

## Acknowledgments

Simplex and Perlin noise functions are based on Keijiro Takahashi [NoiseShader](https://github.com/keijiro/NoiseShader/).

Voronoi noise functions are based on Scrawk [GPU-Voronoi-Noise](https://github.com/Scrawk/GPU-Voronoi-Noise).

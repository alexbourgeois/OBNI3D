
#include "../Plugins/Unity-Noises/Includes/SimplexNoise3D.hlsl"
#include "../Plugins/Unity-Noises/Includes/VoronoiNoise3D.hlsl"

int noiseVolumeCount = 0;
float4x4 noiseVolumeTransforms[10]; //Max 10 volumes
float noiseVolumeSettings[180]; //10 * 18 parameters

/*NoiseSettings:
type      scale         offset      speed.x
speed.y   speed.z       octave      octavescale
octaveAt  useCPUClock   clock       jitter
intensity volumeTransformAffectsNoise
*/

float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return length(max(d, 0.0))
		+ min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
}

float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

float4 opTx(in float4 p, in float4x4 t) // transform  = 3*4 matrix
{
	return mul(t, p);
}

float sdGlobal(float type, in float4 p, in float4x4 t) {
	if (type == 1) { //Sphere
		return sdSphere(opTx(p, t).xyz, 1.0);
	}
	if (type == 2) { //Box
		return sdBox(opTx(p, t).xyz, float3(0.5, 0.5, 0.5));
	}

	return 0;
}

float GetNoiseOnPosition(float3 worldPos) {
	float total = 1.0;
	float time = 0.0;

	for (int i = 0; i < noiseVolumeCount * 18; i += 18) {
		time = (noiseVolumeSettings[i + 9] == 1.0f) ? noiseVolumeSettings[i + 10] : _Time.y;
		float currentNoiseValue = 0.0f;
		float3 pos = mul(worldPos, noiseVolumeTransforms[i % 16]) * noiseVolumeSettings[i + 13] + (1 - noiseVolumeSettings[i + 13]) * worldPos;

		//output += PerlinNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
		if (noiseVolumeSettings[i] == 1) {
			//output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * VoronoiNoise_Octaves(pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), noiseVolumeSettings[i + 6], noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], noiseVolumeSettings[i + 11], time + noiseVolumeSettings[i + 17]);

		}
		if (noiseVolumeSettings[i] == 2) {
			//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * SimplexNoise_Octaves(pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), uint(noiseVolumeSettings[i + 6]), noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], time + noiseVolumeSettings[i + 17]);
		}

		if (noiseVolumeSettings[i] == 3) {
			//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
			currentNoiseValue = total;// noiseVolumeSettings[i + 12];// *SimplexNoise_Octaves(pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), uint(noiseVolumeSettings[i + 6]), noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], time + noiseVolumeSettings[i + 17]);
		}
		currentNoiseValue += noiseVolumeSettings[i + 2]; //offset

		float volCoeff = sdGlobal(noiseVolumeSettings[i + 15], float4(worldPos, 1), noiseVolumeTransforms[i % 17]);

		volCoeff = -volCoeff;
		volCoeff = max(volCoeff, 0);

		if (noiseVolumeSettings[i] == 3) {
			currentNoiseValue *= 1 - clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[i + 14] + 0.00001)), 0, 1);
		}
		else {
			currentNoiseValue *= clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[i + 14] + 0.00001)), 0, 1);
		}

		if (volCoeff > 0) {
			if (noiseVolumeSettings[i + 16] == 1) {
				total += currentNoiseValue;
			}
			if (noiseVolumeSettings[i + 16] == 2) {
				total -= currentNoiseValue;
			}
			if (noiseVolumeSettings[i + 16] == 3) {
				total *= currentNoiseValue;
			}
			if (noiseVolumeSettings[i + 16] == 4) {
				total /= currentNoiseValue;
			}
			if (noiseVolumeSettings[i + 16] == 5) {
				total %= currentNoiseValue;
			}
		}
		//noise *= opTx(float4(worldPos, 1), noiseVolumeTransforms[i]) > 0 ? 0 : 1;

		//sum += noise;
	}
	return total;
}
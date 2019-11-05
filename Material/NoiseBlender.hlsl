
#include "../Plugins/Unity-Noises/Includes/SimplexNoise3D.hlsl"
#include "../Plugins/Unity-Noises/Includes/VoronoiNoise3D.hlsl"

int noiseVolumeCount = 0;
float4x4 noiseVolumeTransforms[10]; //Max 10 volumes
float noiseVolumeSettings[200]; //10 * 20 parameters

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

float GetNoiseOnPosition(float4 vertex) {
	float total = 0.0;
	float time = 0.0;

	for (int i = 0; i < noiseVolumeCount * 20; i += 20) {

		if (noiseVolumeSettings[i] == 3) { //mask
			continue;
		}
		//Time
		time = (noiseVolumeSettings[i + 9] == 1.0f) ? noiseVolumeSettings[i + 10] : _Time.y;
		float currentNoiseValue = 0.0f;

		float3 pos = float3(0, 0, 0);
		//Position
		if (noiseVolumeSettings[i + 19] == 1) {//World space
			pos = mul(unity_ObjectToWorld, vertex).xyz;
		}
		if (noiseVolumeSettings[i + 19] == 2) {//Noise space
			pos = mul(vertex.xyz, noiseVolumeTransforms[i % 19]);
		}
		pos = mul(pos, noiseVolumeTransforms[i % 19]) * noiseVolumeSettings[i + 13] + (1 - noiseVolumeSettings[i + 13]) * pos;

		//Noise
		if (noiseVolumeSettings[i] == 1) {
			//output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * VoronoiNoise_Octaves(pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), noiseVolumeSettings[i + 6], noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], noiseVolumeSettings[i + 11], time + noiseVolumeSettings[i + 17]);
		}
		if (noiseVolumeSettings[i] == 2) {
			//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * SimplexNoise_Octaves(pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), uint(noiseVolumeSettings[i + 6]), noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], time + noiseVolumeSettings[i + 17]);
		}

		//Clamp : PositiveAndNegative = 0, PositiveOnly = 1, NegativeOnly = 2, Absolute = 3
		if (noiseVolumeSettings[i + 18] == 0) {
			currentNoiseValue = currentNoiseValue;
		}
		if (noiseVolumeSettings[i + 18] == 1) {
			currentNoiseValue = clamp(currentNoiseValue, 0, 1000000);
		}
		if (noiseVolumeSettings[i + 18] == 2) {
			currentNoiseValue = clamp(currentNoiseValue, -1000000, 0);
		}
		if (noiseVolumeSettings[i + 18] == 3) {
			currentNoiseValue = abs(currentNoiseValue);
		}

		currentNoiseValue += noiseVolumeSettings[i + 2]; //offset

		float volCoeff = sdGlobal(noiseVolumeSettings[i + 15], float4(mul(unity_ObjectToWorld, vertex).xyz , 1), noiseVolumeTransforms[i % 19]);
		volCoeff = -volCoeff;
		volCoeff = max(volCoeff, 0);

		currentNoiseValue *= clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[i + 14] + 0.00001)), 0, 1);

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
	}

	//MASK
	for (int i = 0; i < noiseVolumeCount * 20; i += 20) {
		if (noiseVolumeSettings[i] == 3) { //mask
			float volCoeff = sdGlobal(noiseVolumeSettings[i + 15], float4(mul(unity_ObjectToWorld, vertex).xyz, 1), noiseVolumeTransforms[i % 19]);
			volCoeff = -volCoeff;
			volCoeff = max(volCoeff, 0);
			total = lerp(total, 0, clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[i + 14] + 0.00001)), 0, 1));
		}
	}

	return total;
}
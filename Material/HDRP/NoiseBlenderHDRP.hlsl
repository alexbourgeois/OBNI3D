
#include "../../Plugins/Unity-Noises/Includes/SimplexNoise3D.hlsl"
#include "../../Plugins/Unity-Noises/Includes/VoronoiNoise3D.hlsl"

int noiseVolumeCount = 0;
float4x4 noiseVolumeTransforms[35]; //Max 35 volumes
float noiseVolumeSettings[910]; //40 * 28 parameters || max size = 1023


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

float sdCone(float3 p, float2 c)
{
	// c is the sin/cos of the angle
	float q = length(p.xy);
	return dot(c, float2(q, p.z));
}

float4 opTx(in float4 p, in float4x4 t) // transform  = 3*4 matrix
{
	return mul(t, p);
}


float remapFromTo(float value, float from1, float to1, float from2, float to2) {
	return from2 + (value - from1) * (to2 - from2) / (to1 - from1);
}

float sdGlobal(float type, in float4 p, in float4x4 t) {
	if (type == 1) { //Sphere
		return sdSphere(opTx(p, t).xyz, 1.0);
	}
	if (type == 2) { //Box
		return sdBox(opTx(p, t).xyz, float3(0.5, 0.5, 0.5));
	}
	if (type == 3) { //Box
		return max(sdCone(opTx(p, t).xyz, float2(0.707,0.707)),sdBox(opTx(p, t).xyz, float3(0.5, 0.5, 0.5)));
	}

	return 0;
}

float raymarchToEdge(uint volumeIndex, float3 direction, float3 position) {
	const int maxstep = 64;
	float t = 0; // current distance traveled along ray
	float rmCoeff = 0;
	for (int k = 0; k < maxstep; ++k) {
		rmCoeff = sdGlobal(noiseVolumeSettings[volumeIndex + 15], float4(position + direction * t, 1), noiseVolumeTransforms[(uint)(volumeIndex / 27)]); //inside negative, outside positive

		if (rmCoeff > 0.001) {
			break;
		}
		t += abs(rmCoeff)/2;
	}
	return t;
}

void GetNoiseOnPosition_float(float3 vertex, float3 normal, out float3 total) {
	total = float3(0.0f, 0.0f, 0.0f);
	float time = 0.0;

	for (int i = 0; i < noiseVolumeCount * 28; i += 28) {

		if (noiseVolumeSettings[i] == -1) { //mask
			continue;
		}
		float4x4 currentVolumeTransform = noiseVolumeTransforms[(uint)(i / 27)];

		//Time
		time = (noiseVolumeSettings[i + 9] == 1.0f) ? noiseVolumeSettings[i + 10] : _Time.y;
		float currentNoiseValue = 0.0f;

		float3 pos = vertex.xyz;

		if (noiseVolumeSettings[i + 19] == 2) {//Noise space
			pos = mul(vertex.xyz, currentVolumeTransform);
		}

		float coeff = 0.0f;
		if (noiseVolumeSettings[i + 16] == 5) {
			coeff = 1.0f;
		}

		//Noise
		if (noiseVolumeSettings[i] == 1) {
			//output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * VoronoiNoise_Octaves(total * coeff + pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), noiseVolumeSettings[i + 6], noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], noiseVolumeSettings[i + 11], time + noiseVolumeSettings[i + 17]);
		}
		if (noiseVolumeSettings[i] == 2) {
			//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
			currentNoiseValue = noiseVolumeSettings[i + 12] * SimplexNoise_Octaves(total * coeff + pos, noiseVolumeSettings[i + 1], float3(noiseVolumeSettings[i + 3], noiseVolumeSettings[i + 4], noiseVolumeSettings[i + 5]), uint(noiseVolumeSettings[i + 6]), noiseVolumeSettings[i + 7], noiseVolumeSettings[i + 8], time + noiseVolumeSettings[i + 17]);
		}

		//remap value from to
		currentNoiseValue = remapFromTo(currentNoiseValue, noiseVolumeSettings[i + 24], noiseVolumeSettings[i + 25], noiseVolumeSettings[i + 26], noiseVolumeSettings[i + 27]);

		if (noiseVolumeSettings[i] == 3) {
			currentNoiseValue = noiseVolumeSettings[i + 12];
		}

		//Clamp : PositiveAndNegative = 0, PositiveOnly = 1, NegativeOnly = 2, Absolute = 3, AbsoluteNegative = 4
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
		if (noiseVolumeSettings[i + 18] == 4) {
			currentNoiseValue = -abs(currentNoiseValue);
		}

		currentNoiseValue += noiseVolumeSettings[i + 2]; //offset

		float volCoeff = sdGlobal(noiseVolumeSettings[i + 15], float4(vertex.xyz, 1), currentVolumeTransform); //inside negative, outside positive
		if (volCoeff < 0) {

			float3 axis = float3(noiseVolumeSettings[i + 21], noiseVolumeSettings[i + 22], noiseVolumeSettings[i + 23]);
			float3 direction = axis + normal * noiseVolumeSettings[i + 20];

			volCoeff = -volCoeff;
			volCoeff = max(volCoeff, 0);

			currentNoiseValue *= clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[i + 14] + 0.00001)), 0, 1);

			if (noiseVolumeSettings[i + 13] == 1) { //clamp to volume
				if (sdGlobal(noiseVolumeSettings[i + 15], float4(pos + direction * currentNoiseValue, 1), currentVolumeTransform) > 0) {
					currentNoiseValue = raymarchToEdge(i, direction * sign(currentNoiseValue),pos) * sign(currentNoiseValue);
				}
			}

			if (noiseVolumeSettings[i + 16] == 0) {
				total = currentNoiseValue * direction;
				break;
			}
			if (noiseVolumeSettings[i + 16] == 1) {
				total += currentNoiseValue * direction;
			}
			if (noiseVolumeSettings[i + 16] == 2) {
				total -= currentNoiseValue * direction;
			}
			if (noiseVolumeSettings[i + 16] == 3) {
				total *= currentNoiseValue * direction;
			}
			if (noiseVolumeSettings[i + 16] == 4) {
				total /= currentNoiseValue * direction;
			}
			if (noiseVolumeSettings[i + 16] == 5) {
				total = currentNoiseValue * direction;
			}
		}
	}

	//MASK
	for (int j = 0; j < noiseVolumeCount * 28; j += 28) {
		if (noiseVolumeSettings[j] == -1) { //mask
			float volCoeff = sdGlobal(noiseVolumeSettings[j + 15], float4(vertex.xyz, 1), noiseVolumeTransforms[(uint)(j / 27)]);
			volCoeff = -volCoeff;
			volCoeff = max(volCoeff, 0);
			float intensity = clamp(lerp(0, 1, volCoeff / (noiseVolumeSettings[j + 14] + 0.00001)), 0, 1);
			total = lerp(total, float3(0.0f, 0.0f, 0.0f), intensity);
		}
	}
}
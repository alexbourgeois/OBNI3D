

int noiseVolumeCount = 0;
float4x4 noiseVolumeSettings[50];
float4x4 noiseVolumeTransforms[50];

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

float3 opTx(in float4 p, in float4x4 t) // transform  = 3*4 matrix
{
	float4 tp = mul(t, p);
	float3 p2 = float3(tp.x, tp.y, tp.z);
	return sdBox(p2, float3(1, 1, 1));
}

float sumNoisesOnPosition(float3 worldPos) {
	float sum = 0.0;
	float time = 0.0;

	for (int i = 0; i < noiseVolumeCount; i++) {
		time = noiseVolumeSettings[i][2][1] == 1.0f ? noiseVolumeSettings[i][2][2] : _Time.y;
		float noise = 0.0;
		float3 pos = mul(worldPos, noiseVolumeTransforms[i])*noiseVolumeSettings[i][3][1] + (1 - noiseVolumeSettings[i][3][1])*worldPos;

		//output += PerlinNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
		if (noiseVolumeSettings[i][0][0] == 1) {
			//output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);
			noise += noiseVolumeSettings[i][3][0] * VoronoiNoise_Octaves(pos, noiseVolumeSettings[i][0][1], float3(noiseVolumeSettings[i][0][3], noiseVolumeSettings[i][1][0], noiseVolumeSettings[i][1][1]), uint(noiseVolumeSettings[i][1][2]), noiseVolumeSettings[i][1][3], noiseVolumeSettings[i][2][0], noiseVolumeSettings[i][2][3], time);
		}
		if (noiseVolumeSettings[i][0][0] == 2) {
			//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
			noise += noiseVolumeSettings[i][3][0] * SimplexNoise_Octaves(pos, noiseVolumeSettings[i][0][1], float3(noiseVolumeSettings[i][0][3], noiseVolumeSettings[i][1][0], noiseVolumeSettings[i][1][1]), uint(noiseVolumeSettings[i][1][2]), noiseVolumeSettings[i][1][3], noiseVolumeSettings[i][2][0], time);

		}
		noise += noiseVolumeSettings[i][0][2]; //offset

		noise *= clamp(1 - opTx(float4(worldPos, 1), noiseVolumeTransforms[i]), 0, 1);

		sum += noise;
	}
	return sum;
}

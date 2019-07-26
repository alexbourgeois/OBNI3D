// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "OBNI/OBNI3D"
{
    Properties
    {
		_MainTex("Main Texture", 2D) = "white" {}
		[HDR] _Color("Color", color) = (1,1,1,0)
		_ColorChangeThreshold("Color change threshold", Float) = 0
		_GradientTex("Gradient Texture", 2D) = "white" {}
		[HDR] _GradientColor("Gradient Color", color) = (1,1,1,0)

		_GradientTexRepetition("GradientRepetition", Range(-10,100)) = 1
		_GradientReadingSpeed("GradientReadingSpeed", Range(-100,100)) = 0
		_GradientOffset("Gradient Offset", Float) = 0

		_NoiseEmission("Noise emission", Float) = 0
		_Emission("Emission", Float) = 1

		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		_DeformationAxis("Deformation axis", Vector) = (0,1,0,0)
		_NormalInfluence("Normal influence in deformation", Float) = 0
		_NormalDelta("Gradient distance in normal recomputation", Float) = 0.01
		
		//_Tess("Tessellation", Range(1,32)) = 4

		_RimColor("Rim Color", Color) = (0,1,0,1)
		_RimPower("Rim Power", Float) = .5
		_RimIntensity("Rim Intensity", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

		#include "../Plugins/Unity-Noises/Includes/SimplexNoise3D.hlsl"
		#include "../Plugins/Unity-Noises/Includes/VoronoiNoise3D.hlsl"

		#pragma surface surf Standard addshadow fullforwardshadows vertex:vert //alpha:add//tessellate:tessFixed 
		#pragma target 5.0

		int noiseVolumeCount = 0;
		float4x4 noiseVolumeSettings[50];
		float4x4 noiseVolumeTransforms[50];

		/*NoiseSettings:
		type      scale         offset      speed.x
		speed.y   speed.z       octave      octavescale
		octaveAt  useCPUClock   clock       jitter
		intensity volumeTransformAffectsNoise
		*/

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		/*float4 tessFixed() //Can't use tesselation with out Input in vertex function
		{
			return _Tess;
		}
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
			return sdBox(p2, float3(1,1,1));
		}

		float sumNoisesOnPosition(float3 worldPos) {
			float sum = 0.0;
			float time = 0.0;

			for (int i = 0; i < noiseVolumeCount; i++) {
				time = noiseVolumeSettings[i][2][1] == 1.0f ? noiseVolumeSettings[i][2][2] : _Time.y;
				float noise = 0.0;
				float3 pos = mul(worldPos,noiseVolumeTransforms[i])*noiseVolumeSettings[i][3][1] + (1-noiseVolumeSettings[i][3][1])*worldPos;

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
			//return noiseVolumeSettings[0][3][0] * sin(worldPos.x *noiseVolumeSettings[0][0][1] + _Time.y);
		}

		float _NormalInfluence;
		float _NormalDelta;
		float3 _DeformationAxis;
		float _Tess;
		float _ColorChangeThreshold;

		float4 _Color;
		float4 _GradientColor;
		float _GradientTexRepetition, _GradientReadingSpeed, _GradientOffset;
		float _NoiseEmission;
		half _Emission;
		half _Glossiness;
		half _Metallic;
		sampler2D _MainTex;
		sampler2D _GradientTex;

		float4 _RimColor;
		float _RimPower;
		float _RimIntensity;

		struct Input
		{
			float2 uv_MainTex;
			float3 worldPos;
			float3 normal;
			float3 viewDir;
			float noiseValue;
		};


		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldPos = worldPos;

			float disp = sumNoisesOnPosition(worldPos);
			
			v.vertex.xyz += (v.normal * _NormalInfluence + _DeformationAxis) * disp;

			//Recompute normals
			float3 bitangent = cross(v.normal, v.tangent);

			float3 positionAndTangent = v.vertex + v.tangent * _NormalDelta + (v.normal * _NormalInfluence + _DeformationAxis) * sumNoisesOnPosition(mul(unity_ObjectToWorld, v.vertex + v.tangent * _NormalDelta));
			float3 positionAndBitangent = v.vertex + bitangent * _NormalDelta + (v.normal * _NormalInfluence + _DeformationAxis)  * sumNoisesOnPosition(mul(unity_ObjectToWorld, v.vertex + bitangent * _NormalDelta));

			float3 newTangent = (positionAndTangent - v.vertex); // leaves just 'tangent'
			float3 newBitangent = (positionAndBitangent - v.vertex); // leaves just 'bitangent'

			float3 newNormal = normalize(cross(newTangent, newBitangent));

			v.normal = newNormal;
			
			o.normal = v.normal;
			o.noiseValue = disp;
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {

			float disp = IN.noiseValue;

			float y = disp * _GradientTexRepetition;// * length(IN.normal * _NormalInfluence + _DeformationAxis);

			float time = noiseVolumeSettings[0][2][1] == 1.0f ? noiseVolumeSettings[0][2][2] : _Time.x;
			float2 colorReader = (1.0f, _GradientOffset + y + time *_GradientReadingSpeed);

			half4 c = tex2D(_GradientTex, colorReader) * _GradientColor;
			//float coeff = smoothstep(_ColorChangeThreshold, disp)
			if(abs(disp) <= _ColorChangeThreshold) {
				c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				_Emission = 0.0;
			}

			//o.Normal = IN.normal;

			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			float rimWeight = pow(rim, _RimPower) * _RimIntensity;

			o.Albedo = _RimColor * rimWeight + c.rgb * saturate(1 - rimWeight);
			o.Emission = c.rgb * _Emission + _NoiseEmission * disp;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			
		}

		ENDCG
	}
		FallBack "Diffuse"
}

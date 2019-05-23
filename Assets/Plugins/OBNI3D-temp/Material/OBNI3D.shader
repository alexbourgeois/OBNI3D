// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/OBNI3D"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		[HDR] _Color("Color", color) = (1,1,1,0)

		_ColorTexRepetition("ColorRepetition", Range(-10,100)) = 1
		_ColorReadingSpeed("ColorReadingSpeed", Range(-100,100)) = 0
		_ColorOffset("Color Offset", Float) = 0

		_Emission("Emission", Float) = 1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		_DeformationAxis("Deformation axis", Vector) = (0,1,0,0)
		_NormalInfluence("Normal influence in deformation", Float) = 0

		_Tess("Tessellation", Range(1,32)) = 4
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

		#pragma surface surf Standard addshadow fullforwardshadows vertex:vert //tessellate:tessFixed 
		#pragma target 5.0

		 int noiseVolumeCount = 0;
		 float4x4 noiseVolumeSettings[10];
		 float4x4 noiseVolumeTransforms[10];

		/*NoiseSettings:
		type      scale         offset      speed.x
		speed.y   speed.z       octave      octavescale
		octaveAt  useCPUClock   clock       jitter
		intensity
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

				//output += PerlinNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
				if (noiseVolumeSettings[i][0][0] == 1) {
					//output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);
					noise += noiseVolumeSettings[i][3][0] * VoronoiNoise_Octaves(worldPos, noiseVolumeSettings[i][0][1], float3(noiseVolumeSettings[i][0][3], noiseVolumeSettings[i][1][0], noiseVolumeSettings[i][1][1]), uint(noiseVolumeSettings[i][1][2]), noiseVolumeSettings[i][1][3], noiseVolumeSettings[i][2][0], noiseVolumeSettings[i][2][3], time);
				}
				if (noiseVolumeSettings[i][0][0] == 2) {
					//output += SimplexNoise_Octaves(float3(uv, 0), _Scale, float3(0.0f, 0.0f, _Speed), uint(_Octave), _OctaveScale, _Attenuation, time);
					noise += noiseVolumeSettings[i][3][0] * SimplexNoise_Octaves(worldPos, noiseVolumeSettings[i][0][1], float3(noiseVolumeSettings[i][0][3], noiseVolumeSettings[i][1][0], noiseVolumeSettings[i][1][1]), uint(noiseVolumeSettings[i][1][2]), noiseVolumeSettings[i][1][3], noiseVolumeSettings[i][2][0], time);

				}
				noise += noiseVolumeSettings[i][0][2]; //offset

				noise *= clamp(1 - opTx(float4(worldPos, 1), noiseVolumeTransforms[i]), 0, 1);

				sum += noise;
			}
			return sum;
		}

		float _NormalInfluence;
		float3 _DeformationAxis;
		float _Tess;

		struct Input
		{
			float2 uv_MainTex;
			float3 worldPos;
			float3 normal;
		};


		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			o.worldPos = worldPos;

			float disp = sumNoisesOnPosition(worldPos);
			
			//Recopute normals
			float3 bitangent = cross(v.normal, v.tangent);
			float3 position = v.vertex + v.normal  * disp;

			float3 positionAndTangent = v.vertex + v.tangent * 0.001 + v.normal  * disp;
			float3 positionAndBitangent = v.vertex + bitangent * 0.001 + v.normal  * disp;

			float3 newTangent = (positionAndTangent - position); // leaves just 'tangent'
			float3 newBitangent = (positionAndBitangent - position); // leaves just 'bitangent'

			float3 newNormal = normalize(cross(newTangent, newBitangent));

			v.vertex.xyz += (newNormal * _NormalInfluence + _DeformationAxis) * disp;
			v.normal = newNormal;
			o.normal = newNormal;
		}

		fixed4 _Color;
		float _ColorTexRepetition, _ColorReadingSpeed, _ColorOffset;
		half _Emission;
		half _Glossiness;
		half _Metallic;
		sampler2D _MainTex;

		void surf(Input IN, inout SurfaceOutputStandard o) {

			float disp = sumNoisesOnPosition(IN.worldPos);

			float y = disp * _ColorTexRepetition * length(IN.normal * _NormalInfluence + _DeformationAxis);

			float2 colorReader = (1.0f, _ColorOffset + y + _Time.x *_ColorReadingSpeed);
			half4 c = tex2D(_MainTex, colorReader) * _Color;

			o.Albedo = c.rgb;
			o.Emission = c.rgb * _Emission;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}

		ENDCG
	}
		FallBack "Diffuse"
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "OBNI/OBNI3D"
{
    Properties
    {
		[Header(Main Texture)]
		_MainTex("Main Texture", 2D) = "white" {}
		[HDR] _Color("Color", color) = (1,1,1,0)
		_NormalMap("Normal Map", 2D) = "bump" {}
		_NormalStrength("Normal strength", Float) = 1
		[Space]
		[Header(Gradient Texture)]
		_ColorChangeThreshold("Color Change Threshold", Float) = 0
		_GradientTex("Gradient Texture", 2D) = "white" {}
		[HDR] _GradientColor("Gradient Color", color) = (1,1,1,0)
		_GradientTexRepetition("Gradient Repetition", Range(-10,100)) = 1
		_GradientReadingSpeed("Gradient Reading Speed", Range(-100,100)) = 0
		_GradientOffset("Gradient Offset", Float) = 0
		_GradientFeathering("Gradient Feathering", Float) = 0
		[Space]
		[Header(Emission Noise)]
		[HDR]_NoiseEmissionColor("Noise Emission Color", color) = (0,0,0,0)
		[Header(Emission Texture)]
		_EmissionTex("EmissionTex", 2D) = "white" {}
		[HDR] _EmissionColor("EmissionColor", color) = (0,0,0,0)
		[Space]
		[Header(Material)]
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		
		//_Tess("Tessellation", Range(1,32)) = 4
		[Space]
		[Header(Rim Lighting)]
		[HDR] _RimColor("Rim Color", Color) = (0,1,0,1)
		_RimPower("Rim Power", Float) = .5
		_RimIntensity("Rim Intensity", Float) = 1
		_RimEmission("Rim emission", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
		
		#include "NoiseBlender.hlsl"

		#pragma surface surf Standard addshadow fullforwardshadows vertex:vert //alpha:add// tessellate:tessFixed 

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		/*float _Tess;
		float4 tessFixed() //Can't use tesselation with out Input in vertex function
		{
			return _Tess;
		}*/

		float _ColorChangeThreshold;

		sampler2D _MainTex;

		sampler2D _NormalMap;
		float4 _NormalMap_ST;
		float _NormalStrength;

		float4 _Color;
		float4 _GradientColor;
		float _GradientTexRepetition, _GradientReadingSpeed, _GradientOffset;
		float _GradientFeathering;
		float4 _NoiseEmissionColor;
		float4 _EmissionColor;
		sampler2D _EmissionTex;
		float4 _EmissionTex_ST;
		float _Glossiness;
		float _Metallic;
		
		sampler2D _GradientTex;
		float4 _GradientTex_ST;

		float4 _RimColor;
		float _RimPower;
		float _RimIntensity;
		float _RimEmission;

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

			float3 disp = GetNoiseOnPosition(v.vertex, v.normal);

			//Recompute normals : https://www.ronja-tutorials.com/2018/06/16/Wobble-Displacement.html
			float3 bitangent = cross(v.normal, v.tangent);

			float3 positionAndTangent = v.vertex + v.tangent * 0.01;
			float3 dispPosAndTangent = positionAndTangent + GetNoiseOnPosition(float4(positionAndTangent, 1), v.normal);
			float3 positionAndBitangent = v.vertex + bitangent * 0.01;
			float3 dispPosAndBitangent = positionAndBitangent + GetNoiseOnPosition(float4(positionAndBitangent, 1), v.normal);

			v.vertex.xyz += disp;

			float3 newTangent = (dispPosAndTangent - v.vertex); // leaves just 'tangent'
			float3 newBitangent = (dispPosAndBitangent - v.vertex); // leaves just 'bitangent'

			float3 newNormal = normalize(cross(newTangent, newBitangent));

			v.normal = newNormal;
			
			o.normal = v.normal;
			o.noiseValue = disp;
			o.uv_MainTex = v.texcoord.xy;
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {

			float disp = IN.noiseValue;

			float y = disp * _GradientTexRepetition;

			float time = noiseVolumeSettings[9] == 1.0f ? noiseVolumeSettings[10] : _Time.y;
			float2 colorReader = (1.0f, _GradientOffset + y + time *_GradientReadingSpeed);

			float4 gradCol = tex2D(_GradientTex, colorReader) * _GradientColor;
			float4 texCol = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			float4 e = tex2D(_EmissionTex, IN.uv_MainTex) * _EmissionColor;


			float blendCoeff = smoothstep(_ColorChangeThreshold - _GradientFeathering, _ColorChangeThreshold + _GradientFeathering, disp);
			//float blendCoeff = smoothstep((_ColorChangeThreshold - _GradientFeathering) * referenceAmplitude, (_ColorChangeThreshold + _GradientFeathering) * referenceAmplitude, disp);
			float4 c = lerp(texCol, gradCol, blendCoeff);
			float2 uv = TRANSFORM_TEX(IN.uv_MainTex, _NormalMap);
			o.Normal = UnpackScaleNormal(tex2D(_NormalMap, uv), _NormalStrength);

			float rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			float rimWeight = pow(rim, _RimPower) * _RimIntensity;

			o.Albedo = _RimColor * rimWeight + c.rgb * saturate(1 - rimWeight);
			o.Emission = _NoiseEmissionColor * disp + e.rgb + (_RimEmission * _RimColor * rimWeight);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			
		}

		ENDCG
	}
		FallBack "Diffuse"
}

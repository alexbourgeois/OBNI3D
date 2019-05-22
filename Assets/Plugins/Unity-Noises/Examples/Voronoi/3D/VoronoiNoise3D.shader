Shader "Unity-Noises/VoronoiNoise3D/Update"
{
	Properties
	{
		_Scale("Scale", Range(0,10)) = 3
		_Offset("Offset", Range(-3, 3)) = -0.5
		_Speed("Speed", Range(-5,5)) = 0.1
		_Octave("OctaveNumber", Range(1,6)) = 1
		_OctaveScale("OctaveScaleIncrease", Range(0,10)) = 2
		_Attenuation("OctaveAttenuation", Range(0,1)) = 0.5
		_Jitter("Jitter", Range(0,1)) = 1
		_IsTimeControlled("Is time controlled ? (1=yes)", Range(0,1)) = 0
	}

	CGINCLUDE

	#include "UnityCustomRenderTexture.cginc"
	#include "../../../Includes/VoronoiNoise3D.hlsl"

	float _Octave;
	float _OctaveScale;
	float _Scale;
	float _Offset;
	float _Attenuation;
	float _Speed;
	float _Jitter;
	float _IsTimeControlled;
	float _ControlledTime;

    half4 frag(v2f_customrendertexture i) : SV_Target
    {

        float2 uv = i.globalTexcoord;

        float4 output = _Offset;

		float time = _IsTimeControlled == 1.0f ? _ControlledTime : _Time.y;

		output += VoronoiNoise_Octaves(float3(uv,0), _Scale, float3(0, 0, _Speed), int(_Octave), _OctaveScale, _Attenuation, _Jitter, time);

		return output;

    }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            Name "Update"
            CGPROGRAM
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            ENDCG
        }
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public enum NoiseType
{
    Voronoi = 1, Simplex = 2
}

public class NoiseVolume : MonoBehaviour
{
    [Header("Global Settings")]
    public NoiseType noiseType;
    public float intensity = 1;
    public bool volumeTransformAffectsNoise;

    [Header("Noise Settings")]
    [Range(0.0f, 10.0f)]
    public float scale = 5;
    [Range(-3.0f, 3.0f)]
    public float offset = 0;
    public Vector3 speed = Vector3.zero;
    [Range(1,6)]
    public int octave = 1;
    [Range(0, 10)]
    public float octaveScale = 2;
    [Range(0.0f, 1.0f)]
    public float octaveAttenuation = 0.5f;
    [Range(0.0f, 1.0f)]
    public float jitter = 1.0f;

    public bool UseCPUClock = false;

    private static List<NoiseVolume> noiseVolumes = new List<NoiseVolume>();
    private static List<Matrix4x4> noiseVolumeTransforms = new List<Matrix4x4>();
    private static List<Matrix4x4> noiseVolumeSettings = new List<Matrix4x4>();
    public static bool shaderInitialized = false;

    private bool hasInitialized = false;

    /*NoiseSettings:
		type      scale         offset      speed.x
		speed.y   speed.z       octave      octavescale
		octaveAt  useCPUClock   clock       jitter
        intensity
	*/

    private int _noiseIndexInShader = -1;

    private void Awake()
    {
        if (!shaderInitialized)
        {
            for(var i=0; i<50; i++)
            {
                noiseVolumeTransforms.Add(new Matrix4x4());
                noiseVolumeSettings.Add(new Matrix4x4());
            }
 
            Shader.SetGlobalMatrixArray("noiseVolumeSettings", noiseVolumeSettings);
            Shader.SetGlobalMatrixArray("noiseVolumeTransforms", noiseVolumeTransforms);
            _noiseIndexInShader = 0;
            Shader.SetGlobalInt("noiseVolumeCount", 1);

            UpdateNoiseTransform();
            UpdateNoiseSettings();

            noiseVolumes.Add(this);

            shaderInitialized = true;
            hasInitialized = true;
        }
    }

    private void OnEnable()
    {
        if (hasInitialized)
            return;

        _noiseIndexInShader = Shader.GetGlobalInt("noiseVolumeCount");
        Shader.SetGlobalInt("noiseVolumeCount", _noiseIndexInShader + 1);

        UpdateNoiseTransform();
        UpdateNoiseSettings();

        noiseVolumes.Add(this);
    }

    private void OnDisable()
    {
        var volumeCount = Shader.GetGlobalInt("noiseVolumeCount");
        Shader.SetGlobalInt("noiseVolumeCount", volumeCount - 1);

        noiseVolumeSettings.RemoveAt(_noiseIndexInShader);
        noiseVolumeSettings.Add(new Matrix4x4());
        noiseVolumeTransforms.RemoveAt(_noiseIndexInShader);
        noiseVolumeTransforms.Add(new Matrix4x4());

        for(var i=_noiseIndexInShader; i<noiseVolumes.Count; i++)
        {
            noiseVolumes[i]._noiseIndexInShader--;
        }

        noiseVolumes.Remove(this);
        hasInitialized = false;
    }

    public void UpdateNoiseSettings()
    {
        var noiseSettings = noiseVolumeSettings[_noiseIndexInShader];
        noiseSettings.m00 = (int)noiseType;
        noiseSettings.m01 = scale;
        noiseSettings.m02 = offset;
        noiseSettings.m03 = speed.x;
        noiseSettings.m10 = speed.y;
        noiseSettings.m11 = speed.z;
        noiseSettings.m12 = octave;
        noiseSettings.m13 = octaveScale;
        noiseSettings.m20 = octaveAttenuation;
        noiseSettings.m21 = UseCPUClock ? 1.0f : 0.0f;
        noiseSettings.m22 = Time.time;
        noiseSettings.m23 = jitter;
        noiseSettings.m30 = intensity;
        noiseSettings.m31 = volumeTransformAffectsNoise ? 1.0f : 0.0f;

        noiseVolumeSettings[_noiseIndexInShader] = noiseSettings;

        Shader.SetGlobalMatrixArray("noiseVolumeSettings", noiseVolumeSettings);
    }

    public void UpdateNoiseTransform()
    {
        noiseVolumeTransforms[_noiseIndexInShader] = transform.localToWorldMatrix.inverse;
        Shader.SetGlobalMatrixArray("noiseVolumeTransforms", noiseVolumeTransforms);
    }
    
    private void Update()
    {
        UpdateNoiseTransform();
        UpdateNoiseSettings();
    }
    
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.black;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one * 4);
    }
}

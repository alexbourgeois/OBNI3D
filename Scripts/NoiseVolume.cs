using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public enum VolumeType
{
    Noise = 0, Mask = 1
}

public enum VolumeShape
{
    Sphere = 1, Box = 2
}

public enum NoiseSpace
{
    World = 1, Volume = 2
}

public enum NoiseType
{
    Voronoi = 1, Simplex = 2
}

public enum NoiseValueRemapType
{
    PositiveAndNegative = 0, PositiveOnly = 1, NegativeOnly = 2, Absolute = 3
}

public enum BlendOperator
{
    Addition = 1, Substraction = 2, Multiplication = 3, Division = 4, Modulo = 5
}

public enum TimeType { Absolute = 0, Relative = 1 }

[ExecuteInEditMode]
public class NoiseVolume : MonoBehaviour
{
    [Header("Time Settings")]
    public bool SyncWithCPU = false;
    public TimeType timeType = TimeType.Absolute;

    [Header("Shape Settings")]
    public VolumeType volumeType = VolumeType.Noise;
    public VolumeShape volumeShape = VolumeShape.Box;
    [Range(0.0f, 10.0f)]
    public float falloffRadius = 0.1f;
    public bool volumeTransformAffectsNoise;

    [Header("Blend Settings")]
    public float intensity = 1;
    public NoiseValueRemapType valueRemappingType = NoiseValueRemapType.PositiveAndNegative;
    public BlendOperator blendOperator = BlendOperator.Addition;

    [Header("Noise Settings")]
    public NoiseType noiseType = NoiseType.Simplex;
    public NoiseSpace noiseSpace = NoiseSpace.World;
    public int seed;
    public float offset = 0;
    public float scale = 5;
    public Vector3 speed = Vector3.zero;
    public Space speedSpace;
    [Range(1, 6)]
    public int octave = 1;
    public float octaveScale = 2;
    [Range(0.0f, 1.0f)]
    public float octaveAttenuation = 0.5f;
    [Range(0.0f, 1.0f)]
    public float jitter = 1.0f;

    private int _nbParameter = 20;

    private Vector3 _shaderSpeed;
    private Vector3 _speedOffset;

    private static List<NoiseVolume> noiseVolumes = new List<NoiseVolume>();
    private static List<Matrix4x4> noiseVolumeTransforms = new List<Matrix4x4>();
    private static List<float> noiseVolumeSettings = new List<float>();
    public static bool shaderInitialized = false;

    private bool hasInitialized = false;

    private int _noiseIndexInShader = -1;

    private void Awake()
    {
        if (!shaderInitialized)
        {
            for (var i = 0; i < 50; i++)
            {
                noiseVolumeTransforms.Add(new Matrix4x4());
            }
            for (var i = 0; i < _nbParameter * 10; i++)
            {
                noiseVolumeSettings.Add(0.0f);
            }
            Shader.SetGlobalFloatArray("noiseVolumeSettings", noiseVolumeSettings);
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
        for (int j = 0; j < _nbParameter; j++)
            noiseVolumeSettings[_noiseIndexInShader + j] = 0.0f;

        noiseVolumeTransforms.RemoveAt(_noiseIndexInShader);
        noiseVolumeTransforms.Add(new Matrix4x4());

        for (var i = _noiseIndexInShader; i < noiseVolumes.Count; i++)
        {
            noiseVolumes[i]._noiseIndexInShader--;
        }

        noiseVolumes.Remove(this);
        hasInitialized = false;
    }

    public void UpdateNoiseSettings()
    {
        _shaderSpeed = speed;

        if (speedSpace == Space.Self)
        {
            _shaderSpeed = Quaternion.Euler(transform.rotation.eulerAngles) * speed;
        }

        if (volumeType == VolumeType.Noise)
        {
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 0] = (int)noiseType;
        }
        if (volumeType == VolumeType.Mask)
        {
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 0] = 3;
        }

        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 1] = scale;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 2] = offset;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 3] = _shaderSpeed.x;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 4] = _shaderSpeed.y;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 5] = _shaderSpeed.z;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 6] = (int)octave;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 7] = octaveScale;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 8] = octaveAttenuation;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 9] = SyncWithCPU ? 1.0f : 0.0f;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 10] = Time.time;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 11] = jitter;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 12] = intensity;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 13] = volumeTransformAffectsNoise ? 1.0f : 0.0f;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 14] = falloffRadius;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 15] = (int)volumeShape;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 16] = (int)blendOperator;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 17] = seed;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 18] = (int)valueRemappingType;
        noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 19] = (int)noiseSpace;

        _speedOffset += Time.deltaTime * _shaderSpeed;
        if (timeType == TimeType.Relative)
        {
            //Relative time
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 3] = _speedOffset.x;
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 4] = _speedOffset.y;
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 5] = _speedOffset.z;
            noiseVolumeSettings[_noiseIndexInShader * _nbParameter + 10] = 1.0f;
        }

        Shader.SetGlobalFloatArray("noiseVolumeSettings", noiseVolumeSettings);
        //Debug.Log("---------------------------------------------------------------------");
        //for (var i = 0; i < 170; i++)
        //{
        //    Debug.Log(noiseVolumeSettings[i]);
        //}

    }

    public void UpdateNoiseTransform()
    {
        noiseVolumeTransforms[_noiseIndexInShader] = transform.worldToLocalMatrix;
        Shader.SetGlobalMatrixArray("noiseVolumeTransforms", noiseVolumeTransforms);
    }

    private void Update()
    {
        UpdateNoiseTransform();
        UpdateNoiseSettings();
    }

    private void OnDrawGizmos()
    {
        var color = new Color(1.0f, 0.5f, 0.0f);//Yellow
        if (volumeType == VolumeType.Mask)
        {
            color = new Color(0.0f, 0.5f, 1.0f);//Blue
        }
        if (!this.enabled)
        {
            color *= 0.5f; //Darker     //new Color(.5f, 0.25f, 0.0f);//Brown
        }
        Gizmos.color = color;
        Gizmos.matrix = transform.localToWorldMatrix;

        switch (volumeShape)
        {
            case VolumeShape.Box:
                Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
                break;
            case VolumeShape.Sphere:
                Gizmos.DrawWireSphere(Vector3.zero, 1.0f);
                break;
        }
    }
}

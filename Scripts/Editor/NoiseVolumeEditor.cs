using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(NoiseVolume)), CanEditMultipleObjects]
public class NoiseVolumeEditor : Editor
{
    SerializedProperty syncWithCPU;
    SerializedProperty timeType;
    SerializedProperty volumeType;
    SerializedProperty volumeShape;
    SerializedProperty volumeFallOff;
    SerializedProperty volumeTransformAffectsNoise;


    SerializedProperty intensity;
    SerializedProperty valueRemappingType;
    SerializedProperty blendOperator;
    SerializedProperty normalInfluence;
    SerializedProperty axisInfluence;
    SerializedProperty deformerType;
    SerializedProperty seed;
    SerializedProperty offset;
    SerializedProperty scale;
    SerializedProperty speed;
    SerializedProperty speedSpace;
    SerializedProperty octave;
    SerializedProperty octaveScale;
    SerializedProperty octaveAttenuation;
    SerializedProperty jitter;

    void OnEnable()
    {
        syncWithCPU = serializedObject.FindProperty("SyncWithCPU"); //ok
        timeType = serializedObject.FindProperty("timeType");//ok
        volumeType = serializedObject.FindProperty("volumeType");//ok
        volumeShape = serializedObject.FindProperty("volumeShape");//ok
        volumeFallOff = serializedObject.FindProperty("falloffRadius");//ok
        volumeTransformAffectsNoise = serializedObject.FindProperty("volumeTransformAffectsNoise");//ok
        valueRemappingType = serializedObject.FindProperty("valueRemappingType");//ok
        intensity = serializedObject.FindProperty("intensity");//ok
        valueRemappingType = serializedObject.FindProperty("valueRemappingType");
        blendOperator = serializedObject.FindProperty("blendOperator");//ok
        normalInfluence = serializedObject.FindProperty("normalInfluence");//ok
        axisInfluence = serializedObject.FindProperty("axisInfluence");//ok
        deformerType = serializedObject.FindProperty("deformerType");//ok
        scale = serializedObject.FindProperty("scale");//ok
        seed = serializedObject.FindProperty("seed");//ok
        offset = serializedObject.FindProperty("offset");//ok
        speed = serializedObject.FindProperty("speed");//ok
        speedSpace = serializedObject.FindProperty("speedSpace");//ok
        octave = serializedObject.FindProperty("octave");//ok
        octaveScale = serializedObject.FindProperty("octaveScale");//ok
        octaveAttenuation = serializedObject.FindProperty("octaveAttenuation");//ok
        jitter = serializedObject.FindProperty("jitter");
    }

    // Start is called before the first frame update
    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        
        EditorGUILayout.PropertyField(volumeShape);
        EditorGUILayout.PropertyField(volumeFallOff);
        EditorGUILayout.PropertyField(volumeType);

        if (volumeType.hasMultipleDifferentValues || volumeType.intValue == 0)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.PropertyField(intensity);
            EditorGUILayout.PropertyField(blendOperator);
            EditorGUILayout.PropertyField(normalInfluence);
            EditorGUILayout.PropertyField(axisInfluence);
            EditorGUILayout.PropertyField(valueRemappingType);
            EditorGUILayout.PropertyField(volumeTransformAffectsNoise);
            EditorGUILayout.PropertyField(deformerType);
            if (deformerType.hasMultipleDifferentValues || deformerType.intValue != 3)
            {
                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(seed);
                EditorGUILayout.PropertyField(offset);
                EditorGUILayout.PropertyField(scale);
                EditorGUILayout.PropertyField(speed);
                EditorGUILayout.PropertyField(speedSpace);
                EditorGUILayout.PropertyField(octave);
                EditorGUILayout.PropertyField(octaveScale);
                EditorGUILayout.PropertyField(octaveAttenuation);
                if (deformerType.hasMultipleDifferentValues || deformerType.intValue == 1)
                {
                    EditorGUILayout.PropertyField(jitter);
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.PropertyField(syncWithCPU);
            EditorGUILayout.PropertyField(timeType);

            EditorGUI.indentLevel--;
        }

        serializedObject.ApplyModifiedProperties();
        /*

        GradientCreator myScript = (GradientCreator)target;
        if (GUILayout.Button("Render gradient"))
        {
            myScript.RenderGradient();
        }

        if (GUILayout.Button("Write to file"))
        {
            myScript.WriteToFile();
        }*/
    }
}
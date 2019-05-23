using UnityEngine;
using System.Collections;
using UnityEditor;

[CustomEditor(typeof(GradientCreator))]
public class GradientCreatorEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        GradientCreator myScript = (GradientCreator)target;
        if (GUILayout.Button("Render gradient"))
        {
            myScript.RenderGradient();
        }

        if (GUILayout.Button("Write to file"))
        {
            myScript.WriteToFile();
        }
    }
}
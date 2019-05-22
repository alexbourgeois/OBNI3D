using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderTimeController : MonoBehaviour {

    /// <summary>
    /// Update the global shader parameter "_ControlledTime" to the value of Time.time every frame
    /// </summary>

    // Update is called once per frame
    void Update () {
        Shader.SetGlobalFloat("_ControlledTime", Time.time);
    }
    
}

using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class GradientCreator : MonoBehaviour
{

    public Gradient MyGradient;
    public TextureWrapMode Wrap;
    //private TextureWrapMode _wrap;
    //[SerializeField]
    //public TextureWrapMode Wrap
    //{
    //    get { return _wrap; }
    //    set
    //    {
    //        _wrap = value;
    //        CreateTexture();
    //    }
    //}

    public Texture2D GradientTexture;

    public string FileName;

    public Renderer OBNI;

    [SerializeField]
    public int TextureWidth
    {
        get { return m_textureWidth; }
        set
        {
            m_textureWidth = value;
            CreateTexture();
        }
    }
    public int m_textureWidth = 150;

    [SerializeField]
    public int TextureHeight
    {
        get { return m_textureHeight; }
        set
        {
            m_textureHeight = value;
            CreateTexture();
        }
    }
    public int m_textureHeight = 1;

    public bool ApplyInRealtime;

    private void Start()
    {
        CreateTexture();
        RenderGradient();
    }

    private void CreateTexture()
    {
        GradientTexture = new Texture2D(m_textureWidth, m_textureHeight);
        GradientTexture.wrapMode = Wrap;
    }

    private void Update()
    {
        if (ApplyInRealtime)
            RenderGradient();

    }

    public void WriteToFile()
    {
        var jpg = GradientTexture.EncodeToJPG(100);
        var file = File.Open(Application.dataPath + FileName + ".jpg", FileMode.OpenOrCreate);
        file.Write(jpg, 0, jpg.Length);

    }

    public void RenderGradient()
    {
        CreateTexture();

        for (var i = 0; i < GradientTexture.width; i++)
        {
            for (var j = 0; j < GradientTexture.height; j++)
            {
                GradientTexture.SetPixel(i, j, MyGradient.Evaluate((float)i / GradientTexture.width).linear);
            }
        }

        GradientTexture.Apply();
        OBNI.material.SetTexture("_MainTex", GradientTexture);
    }
}
using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class HexBokeh : MonoBehaviour
{
    // Reference to the shader.
    [SerializeField] Shader shader;

    // Focus settings.
    public float focalLength = 10.0f;
    [Range(0, 2)]
    public float focalSize = 0.05f;
    public float aperture = 11.5f;
    public bool visualizeCoc;
    public float maxDist = 1;

    // Temporary objects.
    Material material;

    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }  

    void SetUpObjects()
    {
        if (material != null) return;
        material = new Material(shader);
        material.hideFlags = HideFlags.DontSave;
    }

    void UpdateFocus()
    {
        var point = focalLength * camera.transform.forward + camera.transform.position;
        var dist01 = camera.WorldToViewportPoint(point).z / (camera.farClipPlane - camera.nearClipPlane);
        material.SetVector("_CurveParams", new Vector4(1.0f, focalSize, aperture / 10.0f, dist01));
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        SetUpObjects();

        UpdateFocus();

        material.SetFloat("_MaxDist", maxDist);

        Graphics.Blit(source, source, material, 0);

        if (visualizeCoc)
        {
            Graphics.Blit(source, destination, material, 1);
        }
        else
        {
            var rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            var rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            var rt3 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            
            /*
            source.filterMode = FilterMode.Point;
            rt1.filterMode = FilterMode.Point;
            rt2.filterMode = FilterMode.Point;
            */

            material.SetVector("_BlurDisp", new Vector4(1, 0, -1, 0) * maxDist);
            Graphics.Blit(source, rt1, material, 2);

            material.SetVector("_BlurDisp", new Vector4(-0.5f, -1, 0.5f, 1) * maxDist);
            Graphics.Blit(rt1, rt2, material, 2);

            material.SetVector("_BlurDisp", new Vector4(0.5f, -1, -0.5f, 1) * maxDist);
            Graphics.Blit(rt1, rt3, material, 2);

            material.SetTexture("_BlurTex1", rt2);
            material.SetTexture("_BlurTex2", rt3);
            Graphics.Blit(source, destination, material, 3);

            material.SetTexture("_BlurTex1", null);
            material.SetTexture("_BlurTex2", null);

            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
            RenderTexture.ReleaseTemporary(rt3);
        }
    }
}

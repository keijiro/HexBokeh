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

        Graphics.Blit(source, source, material, 0);

        if (visualizeCoc)
        {
            Graphics.Blit(source, destination, material, 1);
        }
        else
        {
            var rt1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            var rt2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

            Graphics.Blit(source, rt1, material, 2);
            Graphics.Blit(source, rt2, material, 3);

            material.SetTexture("_BlurTex1", rt1);
            material.SetTexture("_BlurTex2", rt2);
            Graphics.Blit(source, destination, material, 4);

            //Graphics.Blit(rt2, destination, material, 1);

            material.SetTexture("_BlurTex1", null);
            material.SetTexture("_BlurTex2", null);

            RenderTexture.ReleaseTemporary(rt1);
            RenderTexture.ReleaseTemporary(rt2);
        }
    }
}

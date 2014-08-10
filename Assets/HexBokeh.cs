using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class HexBokeh : MonoBehaviour
{
    // Reference to the shader.
    [SerializeField] Shader shader;

    // Temporary objects.
    Material material;

    void SetUpObjects()
    {
        if (material != null) return;
        material = new Material(shader);
        material.hideFlags = HideFlags.DontSave;
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        var rt1 = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, source.format);
        var rt2 = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, source.format);
        var rt3 = RenderTexture.GetTemporary(source.width / 2, source.height / 2, 0, source.format);

        SetUpObjects();

        Graphics.Blit(source, rt3);

        Graphics.Blit(rt3, rt1, material, 0);
        Graphics.Blit(rt3, rt2, material, 1);

        material.SetTexture("_BlurTex", rt2);
        Graphics.Blit(rt1, rt3, material, 2);

        Graphics.Blit(rt3, destination);

        RenderTexture.ReleaseTemporary(rt1);
        RenderTexture.ReleaseTemporary(rt2);
        RenderTexture.ReleaseTemporary(rt3);
    }
}

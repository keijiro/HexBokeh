Shader "Hidden/HexBokeh"
{
    Properties
    {
        _MainTex("-", 2D) = "black"{}
        _BlurTex("-", 2D) = "black"{}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    sampler2D _BlurTex1;
    float4 _BlurTex1_TexelSize;

    sampler2D _BlurTex2;
    float4 _BlurTex2_TexelSize;

    float4 _BlurDisp;
    float _MaxDist;

    sampler2D_float _CameraDepthTexture;

    // 1, focal_size, 1/aperture, distance01
    float4 _CurveParams;

    // zero vector
    static const float4 zero = float4(0, 0, 0, 0);

    //
    // 1st pass - CoC to alpha channel
    //

    float4 frag_write_coc(v2f_img i) : SV_Target
    {
        float d = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy));
        d = _CurveParams.z * abs(d - _CurveParams.w) / (d + 1e-5f);
        return float4(0, 0, 0, saturate(d - _CurveParams.y));
    }

    //
    // 2nd pass - Visualize CoC
    //

    float4 frag_alpha_to_gray(v2f_img i) : SV_Target
    {
        float a = tex2D(_MainTex, i.uv).a;
        return float4(a, a, a, a);
    }

    //
    // 3rd pass - separable blur filter
    //

    struct v2f_blur
    {
        float4 pos   : SV_POSITION;
        float2 uv    : TEXCOORD0;
        float4 uv_12 : TEXCOORD1;
        float4 uv_34 : TEXCOORD2;
        float4 uv_56 : TEXCOORD3;
        float4 uv_78 : TEXCOORD4;
    };

    v2f_blur vert_blur(appdata_img v)
    {
        v2f_blur o;

        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float4 uv = v.texcoord.xyxy;
        float4 d = _MainTex_TexelSize.xyxy * _BlurDisp;

        o.uv    = uv;
        o.uv_12 = uv + d;
        o.uv_34 = uv + d * 2;
        o.uv_56 = uv + d * 3;
        o.uv_78 = uv + d * 4;

        return o;
    }

    float4 frag_blur(v2f_blur i) : SV_Target 
    {
        float4 c   = tex2D(_MainTex, i.uv);
        float4 c_1 = tex2D(_MainTex, i.uv_12.xy);
        float4 c_2 = tex2D(_MainTex, i.uv_12.zw);
        float4 c_3 = tex2D(_MainTex, i.uv_34.xy);
        float4 c_4 = tex2D(_MainTex, i.uv_34.zw);
        float4 c_5 = tex2D(_MainTex, i.uv_56.xy);
        float4 c_6 = tex2D(_MainTex, i.uv_56.zw);
        float4 c_7 = tex2D(_MainTex, i.uv_78.xy);
        float4 c_8 = tex2D(_MainTex, i.uv_78.zw);

        float s = 1;
        float ca = c.a;

        if (min(c_1.a, ca) > 0.20) { c += c_1; s += 1; }
        if (min(c_2.a, ca) > 0.20) { c += c_2; s += 1; }
        if (min(c_3.a, ca) > 0.40) { c += c_3; s += 1; }
        if (min(c_4.a, ca) > 0.40) { c += c_4; s += 1; }
        if (min(c_5.a, ca) > 0.60) { c += c_5; s += 1; }
        if (min(c_6.a, ca) > 0.60) { c += c_6; s += 1; }
        if (min(c_7.a, ca) > 0.80) { c += c_7; s += 1; }
        if (min(c_8.a, ca) > 0.80) { c += c_8; s += 1; }

        return c / s;
    }

    //
    // 4th pass - combiner
    //

    float4 frag_final(v2f_img i) : SV_Target 
    {
        float4 c1 = tex2D(_BlurTex1, i.uv);
        float4 c2 = tex2D(_BlurTex2, i.uv);
        return min(c1, c2);
    }

    ENDCG 

    //
    // Subshader definitions.
    //

    Subshader
    {
        // 1st pass - CoC to alpha channel
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            ColorMask A
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_write_coc
            ENDCG
        }

        // 2nd pass - Visualize CoC
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_alpha_to_gray
            ENDCG
        }

        // 3rd pass - separable blur filter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_blur
            #pragma fragment frag_blur
            ENDCG
        }

        // 5th pass - combiner
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_img
            #pragma fragment frag_final
            #pragma glsl
            ENDCG
        }
    }
}

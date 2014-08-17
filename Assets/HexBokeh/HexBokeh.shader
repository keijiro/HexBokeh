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
        float a = _CurveParams.z * abs(d - _CurveParams.w) / (d + 1e-5f);
        return float4(0, 0, 0, saturate(a - _CurveParams.y));
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
        float4 uv_9a : TEXCOORD5;
        float4 uv_bc : TEXCOORD6;
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
        o.uv_9a = uv + d * 5;
        o.uv_bc = uv + d * 6;

        return o;
    }

    float4 frag_blur(v2f_blur i) : SV_Target 
    {
        float4 c  = tex2D(_MainTex, i.uv);
        float4 c1 = tex2D(_MainTex, i.uv_12.xy);
        float4 c2 = tex2D(_MainTex, i.uv_12.zw);
        float4 c3 = tex2D(_MainTex, i.uv_34.xy);
        float4 c4 = tex2D(_MainTex, i.uv_34.zw);
        float4 c5 = tex2D(_MainTex, i.uv_56.xy);
        float4 c6 = tex2D(_MainTex, i.uv_56.zw);
        float4 c7 = tex2D(_MainTex, i.uv_78.xy);
        float4 c8 = tex2D(_MainTex, i.uv_78.zw);
        float4 c9 = tex2D(_MainTex, i.uv_9a.xy);
        float4 ca = tex2D(_MainTex, i.uv_9a.zw);
        float4 cb = tex2D(_MainTex, i.uv_bc.xy);
        float4 cc = tex2D(_MainTex, i.uv_bc.zw);

        float d  = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
        float d1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_12.xy);
        float d2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_12.zw);
        float d3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_34.xy);
        float d4 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_34.zw);
        float d5 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_56.xy);
        float d6 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_56.zw);
        float d7 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_78.xy);
        float d8 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_78.zw);
        float d9 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_9a.xy);
        float da = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_9a.zw);
        float db = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_bc.xy);
        float dc = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_bc.zw);

        float s = 1;
        float a = c.a;

        if ((d1 <= d ? c1.a : min(c1.a, a)) > 1.0 / 7 * 1) { c += c1; s += 1; }
        if ((d2 <= d ? c2.a : min(c2.a, a)) > 1.0 / 7 * 1) { c += c2; s += 1; }
        if ((d3 <= d ? c3.a : min(c3.a, a)) > 1.0 / 7 * 2) { c += c3; s += 1; }
        if ((d4 <= d ? c4.a : min(c4.a, a)) > 1.0 / 7 * 2) { c += c4; s += 1; }
        if ((d5 <= d ? c5.a : min(c5.a, a)) > 1.0 / 7 * 3) { c += c5; s += 1; }
        if ((d6 <= d ? c6.a : min(c6.a, a)) > 1.0 / 7 * 3) { c += c6; s += 1; }
        if ((d7 <= d ? c7.a : min(c7.a, a)) > 1.0 / 7 * 4) { c += c7; s += 1; }
        if ((d8 <= d ? c8.a : min(c8.a, a)) > 1.0 / 7 * 4) { c += c8; s += 1; }
        if ((d9 <= d ? c9.a : min(c9.a, a)) > 1.0 / 7 * 5) { c += c9; s += 1; }
        if ((da <= d ? ca.a : min(ca.a, a)) > 1.0 / 7 * 5) { c += ca; s += 1; }
        if ((db <= d ? cb.a : min(cb.a, a)) > 1.0 / 7 * 6) { c += cb; s += 1; }
        if ((dc <= d ? cc.a : min(cc.a, a)) > 1.0 / 7 * 6) { c += cc; s += 1; }

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

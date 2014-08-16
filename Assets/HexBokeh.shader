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
    // 3rd pass - upward blur filter
    //

    struct v2f_blur1
    {
        float4 pos : SV_POSITION;
        float4 uv_01 : TEXCOORD0;
        float4 uv_23 : TEXCOORD1;
        float4 uv_45 : TEXCOORD2;
    };

    v2f_blur1 vert_blur1(appdata_img v)
    {
        v2f_blur1 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float4 uv = v.texcoord.xyxy;
        float4 d = _MainTex_TexelSize.xyxy * float4(0, -1, 0, -1) * _MaxDist;

        o.uv_01 = uv + d * float4(0, 0, 1, 1);
        o.uv_23 = uv + d * float4(2, 2, 3, 3);
        o.uv_45 = uv + d * float4(4, 4, 5, 5);

        return o;
    }

    float4 frag_blur1(v2f_blur1 i) : SV_Target 
    {
        static const float4 offs = float4(0, 0, 0, 100);

        float4 c1 = tex2D(_MainTex, i.uv_01.xy) + offs;
        float4 c2 = tex2D(_MainTex, i.uv_01.zw) + offs;
        float4 c3 = tex2D(_MainTex, i.uv_23.xy) + offs;
        float4 c4 = tex2D(_MainTex, i.uv_23.zw) + offs;
        float4 c5 = tex2D(_MainTex, i.uv_45.xy) + offs;
        float4 c6 = tex2D(_MainTex, i.uv_45.zw) + offs;

        float4 c = zero;

        c += c1;
        c += min(c2.a, c1.a) > 100.167 ? c2 : zero;
        c += min(c3.a, c1.a) > 100.333 ? c3 : zero;
        c += min(c4.a, c1.a) > 100.500 ? c4 : zero;
        c += min(c5.a, c1.a) > 100.667 ? c5 : zero;
        c += min(c6.a, c1.a) > 100.833 ? c6 : zero;

        float samples = floor(c.a * 0.01);
        //c.a = c.a - samples * 100;
        c.a = (c1.a - 100) * samples;
        return c / samples;
    }

    //
    // 4th pass - skewed blur filter
    //

    struct v2f_blur2
    {
        float4 pos : SV_POSITION;
        float4 uva_01 : TEXCOORD0;
        float4 uva_23 : TEXCOORD1;
        float4 uva_45 : TEXCOORD2;
        float4 uvb_01 : TEXCOORD3;
        float4 uvb_23 : TEXCOORD4;
        float4 uvb_45 : TEXCOORD5;
    };

    v2f_blur2 vert_blur2(appdata_img v)
    {
        v2f_blur2 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float4 uv = v.texcoord.xyxy;
        float4 d1 = _MainTex_TexelSize.xyxy * float4(0, -1, 0, -1) * _MaxDist;
        float4 d2 = _MainTex_TexelSize.xyxy * float4(0.866, 0.5, 0.866, 0.5) * _MaxDist;

        o.uva_01 = uv + d1 * float4(0, 0, 1, 1);
        o.uva_23 = uv + d1 * float4(2, 2, 3, 3);
        o.uva_45 = uv + d1 * float4(4, 4, 5, 5);

        o.uvb_01 = uv + d2 * float4(0, 0, 1, 1);
        o.uvb_23 = uv + d2 * float4(2, 2, 3, 3);
        o.uvb_45 = uv + d2 * float4(4, 4, 5, 5);

        return o;
    }

    float4 frag_blur2(v2f_blur2 i) : SV_Target 
    {
        static const float4 offs = float4(0, 0, 0, 100);

        float4 ca1 = tex2D(_MainTex, i.uva_01.xy) + offs;
        float4 ca2 = tex2D(_MainTex, i.uva_01.zw) + offs;
        float4 ca3 = tex2D(_MainTex, i.uva_23.xy) + offs;
        float4 ca4 = tex2D(_MainTex, i.uva_23.zw) + offs;
        float4 ca5 = tex2D(_MainTex, i.uva_45.xy) + offs;
        float4 ca6 = tex2D(_MainTex, i.uva_45.zw) + offs;

        float4 cb1 = tex2D(_MainTex, i.uvb_01.xy) + offs;
        float4 cb2 = tex2D(_MainTex, i.uvb_01.zw) + offs;
        float4 cb3 = tex2D(_MainTex, i.uvb_23.xy) + offs;
        float4 cb4 = tex2D(_MainTex, i.uvb_23.zw) + offs;
        float4 cb5 = tex2D(_MainTex, i.uvb_45.xy) + offs;
        float4 cb6 = tex2D(_MainTex, i.uvb_45.zw) + offs;

        float4 c = zero;

        c += ca1;
        c += min(ca2.a, ca1.a) > 100.167 ? ca2 : zero;
        c += min(ca3.a, ca1.a) > 100.333 ? ca3 : zero;
        c += min(ca4.a, ca1.a) > 100.500 ? ca4 : zero;
        c += min(ca5.a, ca1.a) > 100.667 ? ca5 : zero;
        c += min(ca6.a, ca1.a) > 100.833 ? ca6 : zero;

//      c += cb1;
        c += min(cb2.a, cb1.a) > 100.167 ? cb2 : zero;
        c += min(cb3.a, cb1.a) > 100.333 ? cb3 : zero;
        c += min(cb4.a, cb1.a) > 100.500 ? cb4 : zero;
        c += min(cb5.a, cb1.a) > 100.667 ? cb5 : zero;
        c += min(cb6.a, cb1.a) > 100.833 ? cb6 : zero;
        

        float samples = floor(c.a * 0.01);
        //c.a = c.a - samples * 100.0;
        c.a = (ca1.a - 100) * samples;
        return c / samples;
    }

    //
    // 5th pass - final blur filter
    //

    struct v2f_blur3
    {
        float4 pos : SV_POSITION;
        float4 uva_01 : TEXCOORD0;
        float4 uva_23 : TEXCOORD1;
        float4 uva_45 : TEXCOORD2;
        float4 uvb_01 : TEXCOORD3;
        float4 uvb_23 : TEXCOORD4;
        float4 uvb_45 : TEXCOORD5;
    };

    v2f_blur3 vert_blur3(appdata_img v)
    {
        v2f_blur3 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float4 uv = v.texcoord.xyxy;
        float4 d1 = _MainTex_TexelSize.xyxy * float4( 0.866, 0.5,  0.866, 0.5) * _MaxDist;
        float4 d2 = _MainTex_TexelSize.xyxy * float4(-0.866, 0.5, -0.866, 0.5) * _MaxDist;

        o.uva_01 = uv + d1 * float4(0, 0, 1, 1);
        o.uva_23 = uv + d1 * float4(2, 2, 3, 3);
        o.uva_45 = uv + d1 * float4(4, 4, 5, 5);

        o.uvb_01 = uv + d2 * float4(0, 0, 1, 1);
        o.uvb_23 = uv + d2 * float4(2, 2, 3, 3);
        o.uvb_45 = uv + d2 * float4(4, 4, 5, 5);

        return o;
    }

    float4 frag_blur3(v2f_blur3 i) : SV_Target 
    {
        static const float4 offs = float4(0, 0, 0, 100);

        float4 ca1 = tex2D(_BlurTex1, i.uva_01.xy) + offs;
        float4 ca2 = tex2D(_BlurTex1, i.uva_01.zw) + offs;
        float4 ca3 = tex2D(_BlurTex1, i.uva_23.xy) + offs;
        float4 ca4 = tex2D(_BlurTex1, i.uva_23.zw) + offs;
        float4 ca5 = tex2D(_BlurTex1, i.uva_45.xy) + offs;
        float4 ca6 = tex2D(_BlurTex1, i.uva_45.zw) + offs;

        float4 cb1 = tex2D(_BlurTex2, i.uvb_01.xy) + offs;
        float4 cb2 = tex2D(_BlurTex2, i.uvb_01.zw) + offs;
        float4 cb3 = tex2D(_BlurTex2, i.uvb_23.xy) + offs;
        float4 cb4 = tex2D(_BlurTex2, i.uvb_23.zw) + offs;
        float4 cb5 = tex2D(_BlurTex2, i.uvb_45.xy) + offs;
        float4 cb6 = tex2D(_BlurTex2, i.uvb_45.zw) + offs;

        float4 c = zero;

        c += ca1;
        c += min(ca2.a, ca1.a) > 100.167 ? ca2 : zero;
        c += min(ca3.a, ca1.a) > 100.333 ? ca3 : zero;
        c += min(ca4.a, ca1.a) > 100.500 ? ca4 : zero;
        c += min(ca5.a, ca1.a) > 100.667 ? ca5 : zero;
        c += min(ca6.a, ca1.a) > 100.833 ? ca6 : zero;

        //c += cb1;
        c += min(cb2.a, cb1.a) > 100.167 ? cb2 : zero;
        c += min(cb3.a, cb1.a) > 100.333 ? cb3 : zero;
        c += min(cb4.a, cb1.a) > 100.500 ? cb4 : zero;
        c += min(cb5.a, cb1.a) > 100.667 ? cb5 : zero;
        c += min(cb6.a, cb1.a) > 100.833 ? cb6 : zero;

        return c / floor(c.a * 0.01f);
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

        // 3rd pass - upward blur filter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_blur1
            #pragma fragment frag_blur1
            ENDCG
        }

        // 4th pass - skewed blur filter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_blur2
            #pragma fragment frag_blur2
            ENDCG
        }

        // 5th pass - final blur filter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma glsl
            #pragma target 3.0
            #pragma vertex vert_blur3
            #pragma fragment frag_blur3
            #pragma glsl
            ENDCG
        }
    }
}

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

    sampler2D _BlurTex;
    float4 _BlurTex_TexelSize;

    //
    // 1st pass (upward filter)
    //

    struct v2f_blur1
    {
        float4 pos  : SV_POSITION;
        float4 uv_01 : TEXCOORD0;
        float4 uv_23 : TEXCOORD1;
        float4 uv_45 : TEXCOORD2;
    };

    v2f_blur1 vert_blur1(appdata_img v)
    {
        v2f_blur1 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float2 uv = v.texcoord.xy + _MainTex_TexelSize.xyxy * float2(0.866, -0.5);
        float2 d = float2(0, -_MainTex_TexelSize.y);

        o.uv_01 = uv.xyxy + d.xyxy * float4(0, 0, 1, 1);
        o.uv_23 = uv.xyxy + d.xyxy * float4(2, 2, 3, 3);
        o.uv_45 = uv.xyxy + d.xyxy * float4(4, 4, 5, 5);

        return o;
    }

    float4 frag_blur1(v2f_blur1 i) : SV_Target 
    {
        float4 c =
            tex2D(_MainTex, i.uv_01.xy) +
            tex2D(_MainTex, i.uv_01.zw) +
            tex2D(_MainTex, i.uv_23.xy) +
            tex2D(_MainTex, i.uv_23.zw) +
            tex2D(_MainTex, i.uv_45.xy) +
            tex2D(_MainTex, i.uv_45.zw);
        return c * (1.0 / 6);
    }

    //
    // 2nd pass (skewed filter)
    //

    struct v2f_blur2
    {
        float4 pos    : SV_POSITION;
        float2 uv     : TEXCOORD0;
        float4 uva_01 : TEXCOORD1;
        float4 uva_23 : TEXCOORD2;
        float4 uva_45 : TEXCOORD3;
        float4 uvb_01 : TEXCOORD4;
        float4 uvb_23 : TEXCOORD5;
        float4 uvb_45 : TEXCOORD6;
    };

    v2f_blur2 vert_blur2(appdata_img v)
    {
        v2f_blur2 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float2 d1 = _MainTex_TexelSize.xy * float2(0, -1);
        float2 d2 = _MainTex_TexelSize.xy * float2(0.866, 0.5);

        o.uv = v.texcoord.xy;

        o.uva_01 = v.texcoord.xyxy + d1.xyxy * float4(1, 1, 2, 2);
        o.uva_23 = v.texcoord.xyxy + d1.xyxy * float4(3, 3, 4, 4);
        o.uva_45 = v.texcoord.xyxy + d1.xyxy * float4(5, 5, 6, 6);

        o.uvb_01 = v.texcoord.xyxy + d2.xyxy * float4(1, 1, 2, 2);
        o.uvb_23 = v.texcoord.xyxy + d2.xyxy * float4(3, 3, 4, 4);
        o.uvb_45 = v.texcoord.xyxy + d2.xyxy * float4(5, 5, 6, 6);

        return o;
    }

    float4 frag_blur2(v2f_blur2 i) : SV_Target 
    {
        float4 c =
            tex2D(_MainTex, i.uv) * 2 +
            tex2D(_MainTex, i.uva_01.xy) +
            tex2D(_MainTex, i.uva_01.zw) +
            tex2D(_MainTex, i.uva_23.xy) +
            tex2D(_MainTex, i.uva_23.zw) +
            tex2D(_MainTex, i.uva_45.xy) +
            tex2D(_MainTex, i.uva_45.zw) +
            tex2D(_MainTex, i.uvb_01.xy) +
            tex2D(_MainTex, i.uvb_01.zw) +
            tex2D(_MainTex, i.uvb_23.xy) +
            tex2D(_MainTex, i.uvb_23.zw) +
            tex2D(_MainTex, i.uvb_45.xy) +
            tex2D(_MainTex, i.uvb_45.zw);
        return c * (1.0 / 7);
    }

    //
    // 3rd pass (filter & combiner)
    //

    struct v2f_blur3
    {
        float4 pos   : SV_POSITION;
        float2 uv     : TEXCOORD0;
        float4 uva_01 : TEXCOORD1;
        float4 uva_23 : TEXCOORD2;
        float4 uva_45 : TEXCOORD3;
        float4 uvb_01 : TEXCOORD4;
        float4 uvb_23 : TEXCOORD5;
        float4 uvb_45 : TEXCOORD6;
    };

    v2f_blur3 vert_blur3(appdata_img v)
    {
        v2f_blur3 o;
        o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

        float2 d1 = _MainTex_TexelSize.xy * float2( 0.866, 0.5);
        float2 d2 = _MainTex_TexelSize.xy * float2(-0.866, 0.5);

        o.uv.xy = v.texcoord.xy;

        o.uva_01 = v.texcoord.xyxy + d1.xyxy * float4(1, 1, 2, 2);
        o.uva_23 = v.texcoord.xyxy + d1.xyxy * float4(3, 3, 4, 4);
        o.uva_45 = v.texcoord.xyxy + d1.xyxy * float4(5, 5, 6, 6);

        o.uvb_01 = v.texcoord.xyxy + d2.xyxy * float4(1, 1, 2, 2);
        o.uvb_23 = v.texcoord.xyxy + d2.xyxy * float4(3, 3, 4, 4);
        o.uvb_45 = v.texcoord.xyxy + d2.xyxy * float4(5, 5, 6, 6);

        return o;
    }

    float4 frag_blur3(v2f_blur3 i) : SV_Target 
    {
        float4 c =
            tex2D(_MainTex, i.uv) +
            tex2D(_MainTex, i.uva_01.xy) +
            tex2D(_MainTex, i.uva_01.zw) +
            tex2D(_MainTex, i.uva_23.xy) +
            tex2D(_MainTex, i.uva_23.zw) +
            tex2D(_MainTex, i.uva_45.xy) +
            tex2D(_MainTex, i.uva_45.zw) +
            tex2D(_BlurTex, i.uv) +
            tex2D(_BlurTex, i.uvb_01.xy) +
            tex2D(_BlurTex, i.uvb_01.zw) +
            tex2D(_BlurTex, i.uvb_23.xy) +
            tex2D(_BlurTex, i.uvb_23.zw) +
            tex2D(_BlurTex, i.uvb_45.xy) +
            tex2D(_BlurTex, i.uvb_45.zw);
        return c * (1.0 / 21);
    }

    ENDCG 

    Subshader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_blur1
            #pragma fragment frag_blur1
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_blur2
            #pragma fragment frag_blur2
            #pragma glsl
            ENDCG
        }
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode off }      
            CGPROGRAM
            #pragma vertex vert_blur3
            #pragma fragment frag_blur3
            #pragma glsl
            ENDCG
        }
    }
}

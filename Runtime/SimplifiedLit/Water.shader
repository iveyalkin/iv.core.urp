Shader "IV/URP/Water"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"

    struct Attributes
    {
        float4 positionOS : POSITION;
        float2 texcoord : TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float2 uv : TEXCOORD0;
        float4 positionSS : TEXCOORD1;
        float3 positionWP : TEXCOORD2;
        float4 positionCS : SV_POSITION;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };
    ENDHLSL

    Properties
    {
        [MainTexture] _BaseMap ("Texture", 2D) = "white" {}
        [MainColor] _BaseColor ("Color", Color) = (1, 1, 1, 1)
        _FoamColor("Foam Color", Color) = (1, 1, 1, 1)
        _WaterDepth ("Water Depth Fade", Range(0, 10)) = 1
        _FoamDepth ("Foam Depth", Range(0, 2)) = 0.5
        _FoamWidth ("Foam Width", Range(0, 2)) = 0.1
        _WaveSpeed ("Wave Speed", Range(0, 2)) = 0.5
        _WaveStrength ("Wave Strength", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags
        {

            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        Cull Back

        Pass
        {
            Name "WaterPass"
            Tags
            {
                "RenderType" = "Transparent"
                "Queue" = "Transparent"
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half4 _FoamColor;
                float _WaterDepth;
                float _FoamDepth;
                float _FoamWidth;
                float _WaveSpeed;
                float _WaveStrength;
            CBUFFER_END

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma shader_feature USE_FORWARD_PLUS

            Varyings Vertex(Attributes input)
            {
                Varyings output;

                // Add simple wave motion
                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                float wave = sin(worldPos.x + _Time.y * _WaveSpeed) * 
                           cos(worldPos.z + _Time.y * _WaveSpeed) * _WaveStrength;
                worldPos.y += wave;
                
                output.positionWP = worldPos;
                output.positionCS = TransformWorldToHClip(worldPos);
                output.positionSS = ComputeScreenPos(output.positionCS);

                return output;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                float2 screenUV = input.positionSS.xy / input.positionSS.w;

                // Sample scene depth
                float sceneDepth = SampleSceneDepth(screenUV);
                float linearSceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                float linearEyeDepth = LinearEyeDepth(input.positionCS.z, _ZBufferParams);

                // Calculate water depth
                float depthDifference = linearSceneDepth - linearEyeDepth;
                float waterDepthFade = exp(-depthDifference * _WaterDepth);

                // Calculate foam
                float foam = 1 - saturate((depthDifference - _FoamDepth) / _FoamWidth);

                // Combine colors
                float4 waterColor = lerp(_BaseColor, _FoamColor, foam);
                waterColor.a = lerp(waterColor.a, 1, waterDepthFade);

                return waterColor;
                // return _BaseColor * SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
            }
            ENDHLSL
        }
    }
}
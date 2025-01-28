Shader "IV/URP/FullscreenBlur"
{
    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // The Blit.hlsl file provides the vertex shader (Vert),
        // the input structure (Attributes), and the output structure (Varyings)
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        float _BlurRadius;
        float _Intensity;

        float4 FragBlur(Varyings IN) : SV_Target
        {
            float kernel[9] = {
                0.25, 0.5, 0.25,
                0.5,  1.0,  0.25,
                0.25, 0.5, 0.25
            };
            float3 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, IN.texcoord).rgb;

            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            float texelSize = length(_BlitTexture_TexelSize.xy);
            int flag = step(texelSize, _BlurRadius);
            int off = 1 - flag;
            float weightSum = 1.0; // center pixel
            for (int i = -1; i <= 1; i++)
            {
                int x = i * flag + off;
                for (int j = -1; j <= 1; j++)
                {
                    int y = j * flag + off;
                    float2 offset = float2(x, y) * _BlitTexture_TexelSize.xy * _BlurRadius * flag;
                    float weight = kernel[(x + 1) * 3 + (y + 1)] * _Intensity;
                    weightSum += weight;
                    color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, IN.texcoord + offset).rgb *
                        weight;
                }
            }

            color /= weightSum;

            return float4(color, 1.0);
        }
    ENDHLSL

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZWrite Off Cull Off

        Pass
        {
            Name "Blur"

            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment FragBlur

            ENDHLSL
        }
    }
}
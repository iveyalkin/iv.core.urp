#ifndef UNIVERSAL_UNLIT_LIGHTING_INCLUDED
#define UNIVERSAL_UNLIT_LIGHTING_INCLUDED

// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

// TEXTURE2D(_BaseMap);
// SAMPLER(sampler_BaseMap);
// float4 _BaseMap_ST;
// CBUFFER_START
// #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"

// float4 _FPParams0;

// Directional lights would be in all clusters, so they don't go into the cluster structure.
// Instead, they are stored first in the light buffer.
// #define URP_FP_DIRECTIONAL_LIGHTS_COUNT ((uint)_FPParams0.w)

// Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are
// set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in
// com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
// For Directional lights, _LightDirection is used when applying shadow Normal Bias.
// For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is
// different at each shadow caster geometry vertex.
float3 _LightDirection;

// struct Attributes
// {
//     float4 positionOS : POSITION;
//     float3 normalOS : NORMAL;
//     float4 tangentOS : TANGENT;
//     float2 texcoord : TEXCOORD0;
//     UNITY_VERTEX_INPUT_INSTANCE_ID
// };
//
// struct Varyings
// {
//     float2 uv : TEXCOORD0;
//     float4 shadowCoord : TEXCOORD1;
//     float3 normalWS : TEXCOORD2;
//     float3 positionWS : TEXCOORD3;
//     float4 positionCS : SV_POSITION;
//     UNITY_VERTEX_INPUT_INSTANCE_ID
// };

// struct InputData
// {
//     float3  positionWS;
//     float4  positionCS;
//     half3   viewDirectionWS;
//     float4  shadowCoord;
//     half3   vertexLighting;
//     float2  normalizedScreenSpaceUV;
//     half4   shadowMask;
// };

// struct LightingData
// {
//     half3 mainLightColor;
//     half3 additionalLightsColor;
//     half3 vertexLightingColor;
// };

// struct SurfaceData
// {
//     half3 albedo;
//     half  occlusion;
//     half  alpha;
// };

float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float3 lightDirectionWS = _LightDirection;

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
    positionCS = ApplyShadowClamping(positionCS);

    return positionCS;
}

inline InputData InitializeInputData(Varyings input)
{
    InputData inputData = (InputData)0;

    inputData.positionWS = input.positionWS;

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);

    viewDirWS = SafeNormalize(viewDirWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
        inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif

    // #ifdef _ADDITIONAL_LIGHTS_VERTEX
        // inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
        // inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    // #else
        // inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactor);
        inputData.vertexLighting = half3(0, 0, 0);
    // #endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    return inputData;
}

inline SurfaceData InitializeSimpleLitSurfaceData(float2 uv)
{
    SurfaceData outSurfaceData = (SurfaceData)0;

    half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    outSurfaceData.alpha = AlphaDiscard(albedo.a, _Cutoff);
    outSurfaceData.albedo = AlphaModulate(albedo.rgb, outSurfaceData.alpha);
    outSurfaceData.occlusion = 1.0;

    return outSurfaceData;
}

inline half3 CalculateLight(Light light)
{
    return light.color * light.shadowAttenuation;
}

inline half4 CalculateFinalColor(LightingData lightingData, SurfaceData surfaceData)
{
    half3 lightingColor = 0;
    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    half3 color = lightingColor * surfaceData.albedo;

    return half4(color, surfaceData.alpha);
}

// LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
// {
//     LightingData lightingData;
//
//     lightingData.vertexLightingColor = 0;
//     lightingData.mainLightColor = 0;
//     lightingData.additionalLightsColor = 0;
//
//     return lightingData;
// }

inline half4 UnlitWithShadow(Varyings input)
{
    SurfaceData surfaceData = InitializeSimpleLitSurfaceData(input.uv);
    InputData inputData = InitializeInputData(input);

    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    lightingData.mainLightColor += CalculateLight(mainLight);

    #if defined(_ADDITIONAL_LIGHTS)
    #if USE_FORWARD_PLUS
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += CalculateLight(light);
    }
    #endif

    uint pixelLightCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
    LIGHT_LOOP_END
    #endif

    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;

    return CalculateFinalColor(lightingData, surfaceData);
}

#endif
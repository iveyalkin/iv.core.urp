#ifndef UNIVERSAL_WEBGL_LIGHTING_INCLUDED
#define UNIVERSAL_WEBGL_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

// simplified simplelit lighting (BlinnPhong)
half4 SimplifiedLighting(InputData inputData, SurfaceData surfaceData)
{
#if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
#endif

    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
#ifdef _LIGHT_LAYERS
    uint meshRenderingLayers = GetMeshRenderingLayer();
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor += CalculateBlinnPhong(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS) && USE_FORWARD_PLUS
        uint lightIndex = 0;
        [loop] while (lightIndex < 2)
        {
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
        #ifdef _LIGHT_LAYERS
            if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        #endif
            {
                lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
            }

            ++lightIndex;
        }
    #endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
#endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

#endif
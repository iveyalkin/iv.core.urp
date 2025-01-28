using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;

namespace IV.Core.URP.FullscreenBlur
{
    class BlurPass : ScriptableRenderPass
    {
        private static readonly int BlurRadius = Shader.PropertyToID("_BlurRadius");
        private static readonly int Intensity = Shader.PropertyToID("_Intensity");

        private readonly FullscreenBlurRenderFeature.BlurSettings settings;
        private Material blurMaterial;

        private RenderTextureDescriptor blurTextureDescriptor;

        private RenderingData renderingData;

        public BlurPass(Material material, FullscreenBlurRenderFeature.BlurSettings settings)
        {
            this.settings = settings;
            this.blurMaterial = material;

            blurTextureDescriptor = new RenderTextureDescriptor(Screen.width, Screen.height,
                RenderTextureFormat.Default, 0);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var resourceData = frameData.Get<UniversalResourceData>();

            // The following line ensures that the render pass doesn't blit from the back buffer
            if (resourceData.isActiveTargetBackBuffer) return;

            var sourceHandle = resourceData.activeColorTexture;
            var cameraData = frameData.Get<UniversalCameraData>();
            // Set the blur texture size to be the same as the camera target size.
            blurTextureDescriptor.width = cameraData.cameraTargetDescriptor.width;
            blurTextureDescriptor.height = cameraData.cameraTargetDescriptor.height;
            blurTextureDescriptor.depthBufferBits = 0;
            var destinationHandle = UniversalRenderer.CreateRenderGraphTexture(renderGraph, blurTextureDescriptor,
                "_BlurTexture", false);

            // This check is to avoid an error from the material preview in the scene
            if (!sourceHandle.IsValid() || !destinationHandle.IsValid()) return;

            UpdateBlurSettings();

            RenderGraphUtils.BlitMaterialParameters blurPass =
                new(sourceHandle, destinationHandle, blurMaterial, 0);
            renderGraph.AddBlitPass(blurPass, "Blur");
            renderGraph.AddCopyPass(destinationHandle, sourceHandle);
        }

        private void UpdateBlurSettings()
        {
            if (blurMaterial == null) return;

            blurMaterial.SetFloat(BlurRadius, settings.blurRadius);
            blurMaterial.SetFloat(Intensity, settings.intensity);
        }
    }
}
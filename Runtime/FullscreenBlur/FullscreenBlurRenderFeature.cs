using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace IV.Core.URP.FullscreenBlur
{
    public class FullscreenBlurRenderFeature : ScriptableRendererFeature
    {
        [SerializeField] private BlurSettings settings = new();

        private BlurPass blurPass;
        private Material blurMaterial;

        public void SetFullscreenBlur(bool enable) => SetActive(enable);

        public override void Create()
        {
            if (settings.blurShader == null) return;

            if (blurMaterial == null)
                blurMaterial = CoreUtils.CreateEngineMaterial(settings.blurShader);

            if (blurPass == null)
                blurPass = new BlurPass(blurMaterial, settings)
                {
                    renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing
                };
        }

        public override void SetupRenderPasses(ScriptableRenderer renderer,
            in RenderingData renderingData)
        {
            blurPass.ConfigureInput(ScriptableRenderPassInput.Color);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer,
            ref RenderingData renderingData)
        {
            // if (!settings.isEnabled) return;
            if (blurPass == null) return;

            if (renderingData.cameraData.cameraType == CameraType.Game &&
                // pick only the main camera
                renderingData.cameraData.baseCamera == null)
                renderer.EnqueuePass(blurPass);
        }

        protected override void Dispose(bool disposing)
        {
            CoreUtils.Destroy(blurMaterial);
            blurMaterial = null;
            blurPass = null;
        }

        [Serializable]
        public class BlurSettings
        {
            public Shader blurShader;
            [Range(0f, 5f)]
            public float blurRadius = 2f;
            [Range(0f, 5f)]
            public float intensity = 1f;
        }
    }
}
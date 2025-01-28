using IV.Core.URP.FullscreenBlur;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace IV.Core.URP
{
    [CreateAssetMenu(fileName = nameof(GraphicsController), menuName = "Graphics/GraphicsController", order = 0)]
    public class GraphicsController : ScriptableObject
    {
        private UniversalRenderPipelineAsset CurrentAsset => (UniversalRenderPipelineAsset)GraphicsSettings.currentRenderPipeline;

        public void SetFullscreenBlur(bool enable)
        {
            foreach (var data in CurrentAsset.rendererDataList)
            {
                if (data.TryGetRendererFeature<FullscreenBlurRenderFeature>(out var fullscreenBlur))
                {
                    fullscreenBlur.SetFullscreenBlur(enable);
                }
            }
        }
    }
}
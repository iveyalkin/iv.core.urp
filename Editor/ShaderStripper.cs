using System.Collections.Generic;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;

namespace IV.Core.URP
{
    /// <summary>
    /// Remove passes from Shaders that aren't used. Rreduces build times.
    /// </summary>
    class StripShaderProcessor : IPreprocessShaders
    {
        private static readonly string[] shaderNameKeys =
        {
            "Standard",
            "Standard (Specular setup)",
            "Hidden/TerrainEngine/Details/",
            "Hidden/Nature/Tree"
        };

        public int callbackOrder => 0;

        public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
        {
            // Remove all DEFERRED passes, because FORWARD+ rendering used only.
            if (snippet.passType == UnityEngine.Rendering.PassType.Deferred)
            {
                Debug.LogWarning($"Deferred shader '{shader.name}' will be stripped.");
                data.Clear();
            }
            else
                TryStripShaderKeys(shader, data);
        }

        private void TryStripShaderKeys(Shader shader, IList<ShaderCompilerData> data)
        {
            foreach (var key in shaderNameKeys)
            {
                if (shader.name.Contains(key, System.StringComparison.OrdinalIgnoreCase))
                {
                    Debug.LogWarning($"Found shader '{key}' will be stripped.");
                    data.Clear();
                    break;
                }
            }
        }
    }
}
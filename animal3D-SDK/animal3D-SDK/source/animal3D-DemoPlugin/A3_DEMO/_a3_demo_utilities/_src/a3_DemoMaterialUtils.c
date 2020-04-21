#include "..\a3_DemoMaterialUtils.h"
#include <assert.h>

a3ret initRenderPass(a3_RenderPass* pass, a3ui32 uniformCount, a3_Framebuffer* writeFBO, a3_DemoStateShaderProgram* shaderProgram)
{
	pass->numUniforms = uniformCount;
	pass->uniformHandles = malloc(sizeof(a3i32) * uniformCount);
	pass->uniformTypes = malloc(sizeof(a3i32) * uniformCount);
	pass->uniformFlags = malloc(sizeof(a3_UniformSwitch) * uniformCount);
	pass->sources = malloc(sizeof(void*) * uniformCount);
	pass->sourceFunctions = malloc(sizeof(a3_UnifFunction) * uniformCount);
	pass->sourceFunctionFlags = malloc(sizeof(a3boolean) * uniformCount);
	pass->unifDataCounts = malloc(sizeof(a3ui32) * uniformCount);
	pass->unifSourceTargets = malloc(sizeof(a3ui32) * uniformCount);
	pass->writeFBO = writeFBO;
	pass->shaderProgram = shaderProgram;
	return 0;
}

a3ret addRenderUniform(a3_RenderPass* pass, int unifIndex, a3_UniformSwitch unifSwitch, a3i32 unifType, a3i32 unifHandle, a3ui32 count, void* source, a3_UnifFunction sourceFunction, a3boolean functionFlag)
{
	pass->uniformFlags[unifIndex] = unifSwitch;
	pass->uniformTypes[unifIndex] = unifType;
	pass->uniformTypes[unifIndex] = unifType;
	pass->uniformHandles[unifIndex] = unifHandle;
	pass->unifDataCounts[unifIndex] = count;
	pass->sources[unifIndex] = source;
	pass->sourceFunctions[unifIndex] = sourceFunction;
	pass->sourceFunctionFlags[unifIndex] = functionFlag;
	return 0;
}

a3ret drawMaterial(a3_DemoState const* demoState, const a3_VertexDrawable* drawable, const a3_RenderMaterial* mat)
{
	for (a3ui32 i = 0; i < mat->numPasses; ++i)
	{
		drawPass(demoState, drawable, mat->passes[i]);
	}
	return 0;
}

a3ret drawPass(a3_DemoState const* demoState, const a3_VertexDrawable* drawable, const a3_RenderPass* pass)
{
	//a3shaderProgramActivate(pass->shaderProgram->program);
	a3framebufferActivate(pass->writeFBO);
	//a3framebufferBindDepthTexture(demoState->fbo_shadow_d32, a3tex_unit00); //this needs to be configurable because phong uses 06.
	for (a3ui32 i = 0; i < pass->numUniforms; ++i)
	{
		void* source = pass->sourceFunctionFlags[i] ? pass->sourceFunctions[i](demoState) : pass->sources[i];
		//start of loading uniforms, not sure what else I'm missing or if this works.
		switch (pass->uniformFlags[i])
		{
		case uniformSwitch_Int:
			a3shaderUniformSendInt(pass->uniformTypes[i], pass->uniformHandles[i], pass->unifDataCounts[i], (const a3i32*)source);
			break;
		case uniformSwitch_Float:
			a3shaderUniformSendFloat(pass->uniformTypes[i], pass->uniformHandles[i], pass->unifDataCounts[i], (const a3f32*)source);
			break;
		case uniformSwitch_Double:
			a3shaderUniformSendDouble(pass->uniformTypes[i], pass->uniformHandles[i], pass->unifDataCounts[i], (const a3f64*)source);
			break;
		case uniformSwitch_FloatMat: //this only supports floats. How do we support doubles?
			a3shaderUniformSendFloatMat(pass->uniformTypes[i], 0, pass->uniformHandles[i], pass->unifDataCounts[i], (const a3f32*)source);
			break;
		case uniformSwitch_DoubleMat:
			a3shaderUniformSendDoubleMat(pass->uniformTypes[i], 0, pass->uniformHandles[i], pass->unifDataCounts[i], (const a3f64*)source);
			break;
		case uniformSwitch_UniformBuffer:
			//if it's a uniform buffer, the handle is just the index to bind it at. Usually a 0, 1, or 4. I'm not sure how this would be programmatically solved.
			//look up ubTransformStack and ubo_transformStack_model for more information.
			a3shaderUniformBufferActivate((const a3_UniformBuffer*)source, pass->uniformHandles[i]);
			break;
		case uniformSwitch_TextureUnit:
			a3textureActivate((const a3_Texture*)source, pass->uniformHandles[i]);
			break;
		case uniformSwitch_ColorBuffer:
			//binds a source texture to the correct color unit
			a3framebufferBindColorTexture((const a3_Framebuffer*)source, pass->uniformHandles[i], pass->unifSourceTargets[i]);
			break;
		case uniformSwitch_DepthBuffer:
			a3framebufferBindDepthTexture((const a3_Framebuffer*)source, pass->uniformHandles[i]);
		}
	}
	a3vertexDrawableActivateAndRender(drawable);
	return 0;
}

a3_DemoProjector* getActiveCamera(a3_DemoState* demoState)
{
	return (demoState->projector + demoState->activeCamera);
}

void* uniform_retrieveActiveCamProjMat(a3_DemoState* demoState)
{
	return (void*)getActiveCamera(demoState)->projectionMat.mm;
}

void* uniform_retrieveActiveCamProjMatInv(a3_DemoState* demoState)
{
	return (void*)getActiveCamera(demoState)->projectionMatInv.mm;
}

void* uniform_retrieveActiveCamProjBiasMat(a3_DemoState* demoState)
{
	const a3mat4 bias = {
		0.5f, 0.0f, 0.0f, 0.0f,
		0.0f, 0.5f, 0.0f, 0.0f,
		0.0f, 0.0f, 0.5f, 0.0f,
		0.5f, 0.5f, 0.5f, 1.0f,
	};

	a3_DemoProjector* activeCamera = getActiveCamera(demoState);
	a3mat4 viewProjectionBiasMat_other = demoState->shadowLight->viewProjectionMat;
	a3mat4* projectionBiasMatPointer = malloc(sizeof(a3mat4));
	*projectionBiasMatPointer = activeCamera->projectionMat;

	a3real4x4ConcatR(bias.m, viewProjectionBiasMat_other.m);

	a3real4x4Product(projectionBiasMatPointer->m, bias.m, activeCamera->projectionMat.m);
	return (void*)projectionBiasMatPointer->mm;
}

void* uniform_retrieveActiveCamProjBiasMatInv(a3_DemoState* demoState)
{
	const a3mat4 unbias = {
		 2.0f,  0.0f,  0.0f, 0.0f,
		 0.0f,  2.0f,  0.0f, 0.0f,
		 0.0f,  0.0f,  2.0f, 0.0f,
		-1.0f, -1.0f, -1.0f, 1.0f,
	};
	a3_DemoProjector* activeCamera = getActiveCamera(demoState);
	a3mat4 projectionBiasMat_inv = activeCamera->projectionMatInv;

	a3real4x4Product(projectionBiasMat_inv.m, activeCamera->projectionMatInv.m, unbias.m);
	return (void*)activeCamera->projectionMatInv.mm;
}

void* uniform_retrieveTotalRenderTime(a3_DemoState* demoState)
{
	return (void*)&demoState->renderTimer->totalTime;
}

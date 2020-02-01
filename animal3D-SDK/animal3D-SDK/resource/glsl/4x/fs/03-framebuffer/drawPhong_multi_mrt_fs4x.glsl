/*
	Copyright 2011-2020 Daniel S. Buckstein

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

/*
	animal3D SDK: Minimal 3D Animation Framework
	By Daniel S. Buckstein
	
	drawPhong_multi_mrt_fs4x.glsl
	Draw Phong shading model for multiple lights with MRT output.
*/

#version 410

//code taken from Lab 2
const int maxLightCount = 4;

in CoordData
{
	vec2 texCoord;
	vec4 mvPosition;
	vec4 mvNormal;
} coordData;

uniform sampler2D mainTex;
uniform sampler2D uTex_sm_Ramp;
uniform int uLightCt;
uniform int uLightSz;
uniform int uLightSzInvSq;
uniform vec4 uLightPos[maxLightCount];
uniform vec4 uLightCol[maxLightCount];
uniform vec4 uColor;

uniform mat4 uMV;

// ****TO-DO: 
//	1) declare uniform variables for textures; see demo code for hints
//	2) declare uniform variables for lights; see demo code for hints
//	3) declare inbound varying data
//	4) implement Phong shading model
//	Note: test all data and inbound values before using them!
//	5) set location of final color render target (location 0)
//	6) declare render targets for each attribute and shading component

layout (location = 0) out vec4 rtFragColor;
layout (location = 1) out vec4 rtViewPosition;
layout (location = 2) out vec4 rtNormal;
layout (location = 3) out vec4 rtTexCoord;
layout (location = 4) out vec4 rtDiffuseMap;
layout (location = 5) out vec4 rtSpecularMap;
layout (location = 6) out vec4 rtDiffuseTotal;
layout (location = 7) out vec4 rtSpecularTotal;

const int power = 16;
const vec3 ambientColor = vec3(0.1f);

struct LambertData
{
	vec4 LVec;
	float dotProd_LN;
};

vec4 CalculateDiffuse(vec4 NVec, int index, out LambertData lambert)
{
	vec4 LVec = normalize(uLightPos[index]- coordData.mvPosition); //w coord is zero, probably
	float dotProd_LN = dot(NVec, LVec);
	lambert = LambertData(LVec, dotProd_LN);
	float dotProd = max(0.0f, dotProd_LN);

	vec4 diffuseResult = uLightCol[index] * dotProd;

	return diffuseResult;
}

vec4 CalculateSpecular(vec4 NVec, int index, LambertData lambert, vec3 VVec3d, out float specValue)
{
	vec3 NVec3d = NVec.xyz;
	vec3 LVec3d = lambert.LVec.xyz; //unsure if this is actually necessary
	vec3 RVec3d = (2.0f * lambert.dotProd_LN * NVec3d) - LVec3d;
	specValue = pow(max(0.0f, dot(VVec3d, RVec3d)), power);
	return specValue * uLightCol[index];
}


void main()
{
	//this part's the same as Lambert
	vec4 mvNormal_normalized = normalize(coordData.mvNormal);

	vec4 diffuse = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 specular = vec4(0.0, 0.0, 0.0, 1.0);
	float specVal = 0.0f;
	vec3 VVec3d = normalize(-coordData.mvPosition.xyz);
	for(int i = 0; i < uLightCt; i++)
	{
		LambertData lambert;
		vec4 tempDiff = CalculateDiffuse(mvNormal_normalized, i, lambert);
		vec4 tempSpec = CalculateSpecular(mvNormal_normalized, i, lambert, VVec3d, specVal);
		specular += tempSpec;
		diffuse += tempDiff;
	}
	vec4 diffColor = texture(mainTex, coordData.texCoord) * diffuse;
	vec4 specularColor = texture(mainTex, coordData.texCoord) * specular;

	rtFragColor = vec4(diffColor.rgb + specularColor.rgb + (0.3f * ambientColor), 1.0);
	rtViewPosition = coordData.mvPosition;
	rtNormal =  vec4(mvNormal_normalized.xyz, 1.0);
	rtTexCoord = vec4(coordData.texCoord, 0.0, 1.0);
	rtDiffuseMap = texture(mainTex, coordData.texCoord);
	rtSpecularMap = texture(uTex_sm_Ramp, vec2(specVal, 0.0));
	rtDiffuseTotal = diffuse;
	rtSpecularTotal = specular;
}

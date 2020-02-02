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
	
	drawPhong_multi_fs4x.glsl
	Draw Phong shading model for multiple lights.
*/

#version 410

const int maxLightCount = 4;

in CoordData
{
	vec2 texCoord;
	vec4 mvPosition;
	vec4 mvNormal;
} coordData;

uniform sampler2D mainTex;
uniform int uLightCt;
uniform int uLightSz;
uniform int uLightSzInvSq;
uniform vec4 uLightPos[maxLightCount];
uniform vec4 uLightCol[maxLightCount];
uniform vec4 uColor;

uniform mat4 uMV;

const vec4 cHighlight = vec4(1.0f, 1.0f, 1.0f, 1.0f);
const vec4 cCool = vec4(0.0f, 0.0f, 0.55f, 1.0f);
const vec4 cWarm = vec4(0.3f, 0.3f, 0.0f, 1.0f);

// ****TO-DO: 
//	1) declare uniform variables for textures; see demo code for hints
//	2) declare uniform variables for lights; see demo code for hints
//	3) declare inbound varying data
//	4) implement Phong shading model
//	Note: test all data and inbound values before using them!

out vec4 rtFragColor;

vec4 CalculateGooch(vec4 n_vector, int index)
{
	vec3 NVec3d = n_vector.xyz;
	vec3 LVec3d = normalize(uLightPos[index].xyz - coordData.mvPosition.xyz);
	vec3 VVec3d = normalize(-coordData.mvPosition.xyz);
	vec3 RVec3d = (2.0f * max(0.0f,dot(NVec3d, LVec3d)) * NVec3d) - LVec3d;

	float t = (dot(NVec3d, LVec3d) + 1.0f)/2.0f;
	float s = clamp(100.0f * dot(RVec3d, VVec3d) - 97.0f, 0.0f, 1.0f);

	vec4 surfaceColor = 0.25f * texture(mainTex, coordData.texCoord);
	vec4 cShaded = s * cHighlight + (1.0f-s)*(t*(cWarm+surfaceColor) + (1.0f-t)*(cCool+surfaceColor));
	return cShaded;
}


void main()
{
	//this part's the same as Lambert
	vec4 mvNormal_normalized = normalize(coordData.mvNormal);

	vec4 gooch = vec4(0.0, 0.0, 0.0, 1.0);

	for(int i = 0; i < uLightCt; i++)
	{
		vec4 tempGooch = CalculateGooch(mvNormal_normalized, i);
		gooch += tempGooch;
	}

	rtFragColor.rgb = gooch.rgb;

}

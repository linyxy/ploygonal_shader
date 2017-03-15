//***************************************************************************************
// LightingUtil.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Contains API for shader lighting.
//***************************************************************************************

#define MaxLights 16
#define PI 3.141592653589789323
#include "AreaLightUtils.hlsl"

struct Light
{
    float3 Strength;
    float FalloffStart; // point/spot light only
    float3 Direction;   // directional/spot light only
    float FalloffEnd;   // point/spot light only
    float3 Position;    // point light only
    float SpotPower;    // spot light only
};

struct Material
{
    float4 DiffuseAlbedo;
    float3 FresnelR0;
    float Shininess;
};

#define F0				 param_F0_rought_sampleCount.x
#define roughness		 param_F0_rought_sampleCount.y
#define sampleCount  param_F0_rought_sampleCount.w

#define lightIntensity  lightInten_twoSide.x
#define twoSided       (lightInten_twoSide.y > 0.0)


struct AreaLight
{
	float4 quad_points[4];
	float4 samples[4];//num samples

	float4 lightPosition;
	float4 viewPosition;

	float4 albedo;

	float4 param_F0_rought_sampleCount;
	float4 lightInten_twoSide;

};

float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
    // Linear falloff.
    return saturate((falloffEnd-d) / (falloffEnd - falloffStart));
}

// Schlick gives an approximation to Fresnel reflectance (see pg. 233 "Real-Time Rendering 3rd Ed.").
// R0 = ( (n-1)/(n+1) )^2, where n is the index of refraction.
float3 SchlickFresnel(float3 R0, float3 normal, float3 lightVec)
{
    float cosIncidentAngle = saturate(dot(normal, lightVec));

    float f0 = 1.0f - cosIncidentAngle;
    float3 reflectPercent = R0 + (1.0f - R0)*(f0*f0*f0*f0*f0);

    return reflectPercent;
}

float3 BlinnPhong(float3 lightStrength, float3 lightVec, float3 normal, float3 toEye, Material mat)
{
    const float m = mat.Shininess * 256.0f;
    float3 halfVec = normalize(toEye + lightVec);

    float roughnessFactor = (m + 8.0f)*pow(max(dot(halfVec, normal), 0.0f), m) / 8.0f;
    float3 fresnelFactor = SchlickFresnel(mat.FresnelR0, halfVec, lightVec);

    float3 specAlbedo = fresnelFactor*roughnessFactor;

    // Our spec formula goes outside [0,1] range, but we are 
    // doing LDR rendering.  So scale it down a bit.
    specAlbedo = specAlbedo / (specAlbedo + 1.0f);

    return (mat.DiffuseAlbedo.rgb + specAlbedo) * lightStrength;
}

//---------------------------------------------------------------------------------------
// Evaluates the lighting equation for directional lights.
//---------------------------------------------------------------------------------------
float3 ComputeDirectionalLight(Light L, Material mat, float3 normal, float3 toEye)
{
    // The light vector aims opposite the direction the light rays travel.
    float3 lightVec = -L.Direction;

    // Scale light down by Lambert's cosine law.
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

//---------------------------------------------------------------------------------------
// Evaluates the lighting equation for point lights.
//---------------------------------------------------------------------------------------
float3 ComputePointLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
    // The vector from the surface to the light.
    float3 lightVec = L.Position - pos;

    // The distance from surface to light.
    float d = length(lightVec);

    // Range test.
    if(d > L.FalloffEnd)
        return 0.0f;

    // Normalize the light vector.
    lightVec /= d;

    // Scale light down by Lambert's cosine law.
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    // Attenuate light by distance.
    float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
    lightStrength *= att;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}


float3x3 identity3 = { {1,0,0},{0,1,0},{0,0,1} };

float3 ComputeAreaLighting(AreaLight AL, float3 pos, 
    float3 ray, float3 n, float rough, float3 baseColor) {
    //float3 pos; //p
    //float3 ray;//o
    //float3 n;//n
    //float rough;
    //float3 baseColor;


    //specular
    //float2 coords = LTC_Coords(dot(n,ray), rough);
    //float3x3 Minv = LTC_Matrix();
    float3 Lo_specular = 0.0f;// LTC_Evaluate();

    //Lo_specular *= light_intensity;
    ////float2 schlick = texture2D(s_texLTCAmp, coords).xy;//???
    //Lo_specular *= s.specColor*schlick.x + (1.0 - s.specColor)*schlick.y;

    //Lo_specular /= 2.0f * PI;


    //diffuse
    float2 coords = LTC_Coords(dot(n, ray), rough);
    float3x3 Minv = identity3;
    float3 Lo_diffuse = LTC_Evaluate(n,ray,pos,Minv, AL.quad_points,AL.lightInten_twoSide.y);//texture map
    Lo_diffuse *= AL.lightInten_twoSide.x;
    float3 diff_color = baseColor*(1.0 - 0);//metallic component set to 0
    Lo_diffuse *= AL.albedo * diff_color;
    Lo_diffuse /= 2.0f * PI;

    return float3(Lo_diffuse+ Lo_specular);

}


float4 computeAreaLights(AreaLight AL[NUM_AREA_LIGHTS], float3 pos,	float3 ray, float3 n, float rough, float3 baseColor) {
	
	float3 result = 0.0f;

	for (int i = 0; i < NUM_AREA_LIGHTS; i++) {
		result += ComputeAreaLighting(AL[i], pos, ray, n, rough, baseColor);
	}
	return float4(result.x, result.y, result.z, 1.0f);
}




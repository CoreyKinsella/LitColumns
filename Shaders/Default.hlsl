//***************************************************************************************
// Default.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Default shader, currently supports lighting.
//***************************************************************************************

// Defaults for number of lights.
#ifndef NUM_DIR_LIGHTS
    #define NUM_DIR_LIGHTS 3
#endif

#ifndef NUM_POINT_LIGHTS
    #define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
    #define NUM_SPOT_LIGHTS 0
#endif

// Include structures and functions for lighting.
#include "LightingUtil.hlsl"

// Constant data that varies per frame.

cbuffer cbPerObject : register(b0)
{
    float4x4 gWorld;
};

cbuffer cbMaterial : register(b1)
{
	float4 gDiffuseAlbedo;
    float3 gFresnelR0;
    float  gRoughness;
	float4x4 gMatTransform;
};

// Constant data that varies per material.
cbuffer cbPass : register(b2)
{
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
    float4 gAmbientLight;

    // Indices [0, NUM_DIR_LIGHTS) are directional lights;
    // indices [NUM_DIR_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHTS) are point lights;
    // indices [NUM_DIR_LIGHTS+NUM_POINT_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHT+NUM_SPOT_LIGHTS)
    // are spot lights for a maximum of MaxLights per object.
    Light gLights[MaxLights];
};
 
struct VertexIn
{
	float3 PosL    : POSITION;
    float3 NormalL : NORMAL;
};

struct VertexOut
{
	float4 PosH    : SV_POSITION;
    float3 PosW    : POSITION;
    float3 NormalW : NORMAL;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout = (VertexOut)0.0f;
	
    // Transform to world space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosW = posW.xyz;

    // Assumes nonuniform scaling; otherwise, need to use inverse-transpose of world matrix.
    vout.NormalW = mul(vin.NormalL, (float3x3)gWorld);

    // Transform to homogeneous clip space.
    vout.PosH = mul(posW, gViewProj);

    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    float4 diffuse = (0.0f, 0.0f, 0.0f, 0.0f);
    // Interpolating normal can unnormalize it, so renormalize it.
    pin.NormalW = normalize(pin.NormalW);
    
if (gDiffuseAlbedo.x <= 0.0f) {
    diffuse.x = 0.4f;
}
else if (gDiffuseAlbedo.y <= 0.0f) {
    diffuse.y = 0.4f;
}
else if (gDiffuseAlbedo.z <= 0.0f) {
    diffuse.z = 0.4f;
}

if (gDiffuseAlbedo.x > 0.0f && gDiffuseAlbedo.x <= 0.5f) {
    diffuse.x = 0.6f;
}
else if (gDiffuseAlbedo.y > 0.0f && gDiffuseAlbedo.y <= 0.5f) {
    diffuse.y = 0.6f;
}
else if (gDiffuseAlbedo.z > 0.0f && gDiffuseAlbedo.z <= 0.5f) {
    diffuse.z = 0.6f;
}

 if (gDiffuseAlbedo.x > 0.5f && gDiffuseAlbedo.x <= 1.0f) {
    diffuse.x = 1.0f;
}
 else if (gDiffuseAlbedo.y > 0.5f && gDiffuseAlbedo.y <= 1.0f) {
    diffuse.y = 1.0f;
}
 else if (gDiffuseAlbedo.z > 0.5f && gDiffuseAlbedo.z <= 1.0f) {
    diffuse.z = 1.0f;
}
 diffuse.a = gDiffuseAlbedo.a;
    // Vector from point being lit to eye. 
    float3 toEyeW = normalize(gEyePosW - pin.PosW);

	// Indirect lighting.
    float4 ambient = gAmbientLight*diffuse;

    const float shininess = 1.0f - gRoughness;
    Material mat = { diffuse, gFresnelR0, shininess };
    float3 shadowFactor = 1.0f;
    float4 directLight = ComputeLighting(gLights, mat, pin.PosW, 
        pin.NormalW, toEyeW, shadowFactor);

    float4 litColor = ambient + directLight;

    // Common convention to take alpha from diffuse material.
    litColor.a = gDiffuseAlbedo.a;

    return litColor;
}



#ifndef SHADER_HELPERS
#define SHADER_HELPERS

// -------------------------------------------------------------------------------------------------

float3x3 transpose(float3x3 v)
{
    float3x3 tmp;
    tmp[0] = float3(v[0].x, v[1].x, v[2].x);
    tmp[1] = float3(v[0].y, v[1].y, v[2].y);
    tmp[2] = float3(v[0].z, v[1].z, v[2].z);

    return tmp;
}

//float3x3 identity33()
//{
//    float3x3 tmp;
//    tmp[0] = float3(1, 0, 0);
//    tmp[1] = float3(0, 1, 0);
//    tmp[2] = float3(0, 0, 1);
//
//    return tmp;
//}

float3x3 float3x3_from_columns(float3 c0, float3 c1, float3 c2)
{
    float3x3 m = float3x3(c0, c1, c2);
#if BGFX_SHADER_LANGUAGE_HLSL
    // The HLSL matrix constructor takes rows rather than columns, so transpose after
    m = transpose(m);
#endif
    return m;
}

float3x3 float3x3_from_rows(float3 c0, float3 c1, float3 c2)
{
    float3x3 m = float3x3(c0, c1, c2);
#if !BGFX_SHADER_LANGUAGE_HLSL
    m = transpose(m);
#endif
    return m;
}

// -------------------------------------------------------------------------------------------------

int modi(int x, int y)
{
    return int(x%y);
}

float3x3 BasisFrisvad(float3 v)
{
    float3 x, y;

    if (v.z < -0.999999)
    {
        x = float3( 0, -1, 0);
        y = float3(-1,  0, 0);
    }
    else
    {
        float a = 1.0 / (1.0 + v.z);
        float b = -v.x*v.y*a;
        x = float3(1.0 - v.x*v.x*a, b, -v.x);
        y = float3(b, 1.0 - v.y*v.y*a, -v.y);
    }

    return float3x3_from_columns(x, y, v);
}



//float3 FetchDiffuseFilteredTexture(sampler2D texLightFiltered, float3 p1_, float3 p2_, float3 p3_, float3 p4_)
//{
//    // area light plane basis
//    float3 V1 = p2_ - p1_;
//    float3 V2 = p4_ - p1_;
//    float3 planeOrtho = (cross(V1, V2));
//    float planeAreaSquared = dot(planeOrtho, planeOrtho);
//    float planeDistxPlaneArea = dot(planeOrtho, p1_);
//    // orthonormal projection of (0,0,0) in area light space
//    float3 P = planeDistxPlaneArea * planeOrtho / planeAreaSquared - p1_;
//
//    // find tex coords of P
//    float dot_V1_V2 = dot(V1,V2);
//    float inv_dot_V1_V1 = 1.0 / dot(V1, V1);
//    float3 V2_ = V2 - V1 * dot_V1_V2 * inv_dot_V1_V1;
//    float2 Puv;
//    Puv.y = dot(V2_, P) / dot(V2_, V2_);
//    Puv.x = dot(V1, P)*inv_dot_V1_V1 - dot_V1_V2*inv_dot_V1_V1*Puv.y ;
//
//    // LOD
//    float d = abs(planeDistxPlaneArea) / pow(planeAreaSquared, 0.75);
//
//    return texture2DLod(texLightFiltered, float2(0.125, 0.125) + 0.75 * Puv, log(2048.0*d)/log(3.0) ).rgb;
//}

//float3 FetchNormal(sampler2D nmlSampler, float2 texcoord, float3x3 t2w)
//{
//    float3 n = texture2D(nmlSampler, texcoord).wyz*2.0 - 1.0;
//
//    // Recover z
//    n.z = sqrt(max(1.0 - n.x*n.x - n.y*n.y, 0.0));
//
//    return normalize(mul(t2w, n));
//}

// See section 3.7 of
// "Linear Efficient Antialiased Displacement and Reflectance Mapping: Supplemental Material"
float3 CorrectNormal(float3 n, float3 v)
{
    if (dot(n, v) < 0.0)
        n = normalize(n - 1.01*v*dot(n, v));
    return n;
}

#endif

#define MaxLights 16


#ifndef NUM_DIR_LIGHTS
#define NUM_DIR_LIGHTS 1
#endif

#ifndef NUM_POINT_LIGHTS
#define NUM_POINT_LIGHTS 0
#endif

#ifndef NUM_SPOT_LIGHTS
#define NUM_SPOT_LIGHTS 0
#endif

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

//������ �������� �����ϴ� ���� ���� ����� ���.
float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
    // ���� ����
    return saturate((falloffEnd-d) / (falloffEnd - falloffStart));
}

// ���� �ٻ�� ������ �ݻ��� �ٻ��� ����
// R0 = ( (n-1)/(n+1) )^2, n�� ���� ������.
float3 SchlickFresnel(float3 R0, float3 normal, float3 lightVec)
{
    float cosIncidentAngle = saturate(dot(normal, lightVec));

    float f0 = 1.0f - cosIncidentAngle;
    float3 reflectPercent = R0 + (1.0f - R0)*(f0*f0*f0*f0*f0);

    return reflectPercent;
}

float3 BlinnPhong(float3 lightStrength, float3 lightVec, float3 normal, float3 toEye, Material mat)
{
	// ��ĥ�⿡�� ���� ���õ��� m�� ����
    const float m = mat.Shininess * 256.0f;
    float3 halfVec = normalize(toEye + lightVec);

    float roughnessFactor = (m + 8.0f)*pow(max(dot(halfVec, normal), 0.0f), m) / 8.0f;
    float3 fresnelFactor = SchlickFresnel(mat.FresnelR0, halfVec, lightVec);

    float3 specAlbedo = fresnelFactor*roughnessFactor;

    // �ݻ����� 1�̸����� ����� (�ݿ� �ݻ��� ������ [0,1] �ٱ��� ���� �� ���� ������)
	// 1�̻��̸� ���� ���� ���̶���Ʈ�� ���� �� �ִ�
    specAlbedo = specAlbedo / (specAlbedo + 1.0f);

    return (mat.DiffuseAlbedo.rgb + specAlbedo) * lightStrength;
}

//---------------------------------------------------------------------------------------
// ���Ɽ�� ����
//---------------------------------------------------------------------------------------
float3 ComputeDirectionalLight(Light L, Material mat, float3 normal, float3 toEye , int toonLevel)
{
    // �� ���ʹ� �������� ���ư��� �ݴ������ ����Ŵ
    float3 lightVec = -L.Direction;

    // ������Ʈ �ڻ��� ��Ģ�� ���� ���� ���⸦ ���δ�(�̻��ѱ׷���)
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;
	lightStrength = ceil(lightStrength * toonLevel) / (float)toonLevel;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

//---------------------------------------------------------------------------------------
// ���� ������
//---------------------------------------------------------------------------------------
float3 ComputePointLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
    // ǥ�鿡�� ���������� ����
    float3 lightVec = L.Position - pos;

    // ������ ǥ�� ������ �Ÿ�
    float d = length(lightVec);

    // ���� ����
    if(d > L.FalloffEnd)
        return 0.0f;

    // �� ���͸� ����ȭ��
    lightVec /= d;

    // ������Ʈ �ڻ��� ��Ģ�� ���� ���� ���⸦ ����
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    // �Ÿ��� ���� ����
    float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
    lightStrength *= att;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

//---------------------------------------------------------------------------------------
// ������ ������
//---------------------------------------------------------------------------------------
float3 ComputeSpotLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
    // ǥ�鿡�� ���������� ����
    float3 lightVec = L.Position - pos;

    // ������ ǥ�� ������ �Ÿ�
    float d = length(lightVec);

    // ���� ����
    if(d > L.FalloffEnd)
        return 0.0f;

    // �� ���͸� ����ȭ�Ѵ�
    lightVec /= d;

    // ������Ʈ �ڻ��� ��Ģ�� ���� ���� ���⸦ ���δ�
    float ndotl = max(dot(lightVec, normal), 0.0f);
    float3 lightStrength = L.Strength * ndotl;

    // �Ÿ��� ���� ���� ����
    float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
    lightStrength *= att;

    // ������ ����� ����Ѵ�
    float spotFactor = pow(max(dot(-lightVec, L.Direction), 0.0f), L.SpotPower);
    lightStrength *= spotFactor;

    return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}

float4 ComputeLighting(Light gLights[MaxLights], Material mat,
                       float3 pos, float3 normal, float3 toEye,
                       float3 shadowFactor, int toonLevel)
{
    float3 result = 0.0f;

    int i = 0;

#if (NUM_DIR_LIGHTS > 0)
    for(i = 0; i < NUM_DIR_LIGHTS; ++i)
    {
        result += shadowFactor[i] * ComputeDirectionalLight(gLights[i], mat, normal, toEye, toonLevel);
    }
#endif

#if (NUM_POINT_LIGHTS > 0)
    for(i = NUM_DIR_LIGHTS; i < NUM_DIR_LIGHTS+NUM_POINT_LIGHTS; ++i)
    {
        result += ComputePointLight(gLights[i], mat, pos, normal, toEye);
    }
#endif

#if (NUM_SPOT_LIGHTS > 0)
    for(i = NUM_DIR_LIGHTS + NUM_POINT_LIGHTS; i < NUM_DIR_LIGHTS + NUM_POINT_LIGHTS + NUM_SPOT_LIGHTS; ++i)
    {
        result += ComputeSpotLight(gLights[i], mat, pos, normal, toEye);
    }
#endif 

    return float4(result, 0.0f);
}


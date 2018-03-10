#pragma once

#include "d3dUtil.h"
#include "MathHelper.h"
#include "UploadBuffer.h"

struct ObjectConstants
{
	DirectX::XMFLOAT4X4 World = MathHelper::Identity4x4();
	DirectX::XMFLOAT4X4 TexTransform = MathHelper::Identity4x4();
	UINT TextureAniIndex;
	UINT Pad0;
	UINT Pad1;
	UINT Pad2;
};

struct PassConstants
{
    DirectX::XMFLOAT4X4 View = MathHelper::Identity4x4();
    DirectX::XMFLOAT4X4 InvView = MathHelper::Identity4x4();
    DirectX::XMFLOAT4X4 Proj = MathHelper::Identity4x4();
    DirectX::XMFLOAT4X4 InvProj = MathHelper::Identity4x4();
    DirectX::XMFLOAT4X4 ViewProj = MathHelper::Identity4x4();
    DirectX::XMFLOAT4X4 InvViewProj = MathHelper::Identity4x4();

	DirectX::XMFLOAT4X4 ViewMini = MathHelper::Identity4x4();
	DirectX::XMFLOAT4X4 ProjMini = MathHelper::Identity4x4();
	DirectX::XMFLOAT4X4 ViewProjMini = MathHelper::Identity4x4();

    DirectX::XMFLOAT3 EyePosW = { 0.0f, 0.0f, 0.0f };
    float cbPerObjectPad1 = 0.0f;
	DirectX::XMFLOAT3 EyePosWMini = { 0.0f, 0.0f, 0.0f };
	float cbPerObjectPad2 = 0.0f;
    DirectX::XMFLOAT2 RenderTargetSize = { 0.0f, 0.0f };
    DirectX::XMFLOAT2 InvRenderTargetSize = { 0.0f, 0.0f };
    float NearZ = 0.0f;
    float FarZ = 0.0f;
    float TotalTime = 0.0f;
    float DeltaTime = 0.0f;

	DirectX::XMFLOAT4 AmbientLight = { 0.0f, 0.0f, 0.0f, 1.0f };

	DirectX::XMFLOAT4 FogColor = { 0.7f, 0.7f, 0.7f, 1.0f };
	float gFogStart = 50.0f;
	float gFogRange = 700.0f;
	DirectX::XMFLOAT2 cbPerObjectPad3;


	// Indices [0, NUM_DIR_LIGHTS) are directional lights;
	// indices [NUM_DIR_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHTS) are point lights;
	// indices [NUM_DIR_LIGHTS+NUM_POINT_LIGHTS, NUM_DIR_LIGHTS+NUM_POINT_LIGHT+NUM_SPOT_LIGHTS)
	// are spot lights for a maximum of MaxLights per object.
	Light Lights[MaxLights];
};

struct Vertex
{
	DirectX::XMFLOAT3 Pos;
	DirectX::XMFLOAT3 Normal;
	DirectX::XMFLOAT2 TexC0;
	DirectX::XMFLOAT2 TexC1;
};

struct RECTF {
	float left;
	float right;
	float top;
	float bottom;
};

// CPU�� �� �������� ���� ��ϵ��� �����ϴ� �� �ʿ��� �ڿ����� ��ǥ�ϴ� Ŭ����
// ���� ���α׷����� �ʿ��� �ڿ��� �ٸ� ���̹Ƿ�,
// �̷� Ŭ������ ��� ���� ���� ���� ���α׷����� �޶�� �� ��
struct FrameResource
{
public:
    
	FrameResource(ID3D12Device* device, UINT passCount, UINT objectCount, UINT materialCount);//, UINT waveVertCount);
    FrameResource(const FrameResource& rhs) = delete;
    FrameResource& operator=(const FrameResource& rhs) = delete;
    ~FrameResource();

    // ���� �Ҵ��ڴ� GPU�� ���ɵ��� �� ó���� �� �缳���ؾ� �Ѵ�.
	// ���� �����Ӹ��� �Ҵ��ڰ� �ʿ��ϴ�
    Microsoft::WRL::ComPtr<ID3D12CommandAllocator> CmdListAlloc;

    // ��� ���۴� �װ��� �����ϴ� ���ɵ��� GPU�� �� ó���� �Ŀ� �����ؾ� �Ѵ�.
	// �����Ӹ��� ��� ���۸� ���� ������ �Ѵ�.
    std::unique_ptr<UploadBuffer<PassConstants>> PassCB = nullptr;  //�� ���۴� �ϳ��� ������ �н� ��ü���� ������ �ʴ� ��� �ڷ� ����( ������ġ, �þ����,�������, ȭ��ũ��)
    std::unique_ptr<UploadBuffer<MaterialConstants>> MaterialCB = nullptr;
	std::unique_ptr<UploadBuffer<ObjectConstants>> ObjectCB = nullptr;
    // �潺�� ���� ��Ÿ�� ���������� ���ɵ��� ǥ���ϴ� ���̴�.
	// �� ���� GPU�� ���� �������� �ڿ����� ����ϰ� �ִ���
	// �����ϴ� �뵵�� ���δ�.
    UINT64 Fence = 0;
};
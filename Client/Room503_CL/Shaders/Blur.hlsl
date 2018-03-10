//=============================================================================
// �ִ� 5�ȼ������� �帮�� ���������� �и� ���� ���콺 �帮�� ����
//=============================================================================

cbuffer cbSettings : register(b0)
{
	// ��Ʈ ����鿡 �����Ǵ� ��� ���ۿ� �뿭�� �Ѽ���� ������ ����
	int gBlurRadius;

	// 11���� �帮�� ����ġ
	float w0;
	float w1;
	float w2;
	float w3;
	float w4;
	float w5;
	float w6;
	float w7;
	float w8;
	float w9;
	float w10;
};

static const int gMaxBlurRadius = 5;


Texture2D gInput            : register(t0);
RWTexture2D<float4> gOutput : register(u0);

#define N 256
#define CacheSize (N + 2*gMaxBlurRadius)
groupshared float4 gCache[CacheSize];

[numthreads(N, 1, 1)]
void HorzBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 groupID : SV_GroupID,
				int3 dispatchThreadID : SV_DispatchThreadID,
				int groupIndexID : SV_GroupIndex)
{
	// ����ġ�� �������� ���� �ְ� �迭�� �־���
	float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

	//
	// �뿪���� ���̷��� ���� ������ ����Ҹ� ä��
	// �帮�� ������ ������, �ȼ� N���� �帮���� N+ 2*blurRadius���� �Ƚ��� ����
	//
	
	// ������ �׷��� N���� �����带 �����Ѵ�.
	// ������ �ȼ� 2*blurRadius���� ���� �׸�ŭ�� �����尡 �ȼ��� �ϳ� �� �����ϰ� ��
	if(groupThreadID.x < gBlurRadius)
	{
		// �̹��� �����ڸ� �ٱ��� ǥ���� �̹��� �����ڸ� ǥ������ �����Ѵ�.
		int x = max(dispatchThreadID.x - gBlurRadius, 0);
		gCache[groupThreadID.x] = gInput[int2(x, dispatchThreadID.y)];
	}
	if(groupThreadID.x >= N-gBlurRadius)
	{
		// ���������� �����ڸ� ó���� �Ѵ�
		int x = min(dispatchThreadID.x + gBlurRadius, gInput.Length.x-1);
		gCache[groupThreadID.x+2*gBlurRadius] = gInput[int2(x, dispatchThreadID.y)];
	}
	gCache[groupThreadID.x+gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy-1)];
	// ����ȭ ó��.
	GroupMemoryBarrierWithGroupSync();
	
	//
	// �ȼ� �帮�� �˰�����
	//

	float4 blurColor = float4(0, 0, 0, 0);
	
	for(int i = -gBlurRadius; i <= gBlurRadius; ++i)
	{
		int k = groupThreadID.x + gBlurRadius + i;
		
		//if (groupID.x % 2 == 0)
		blurColor += weights[i+gBlurRadius]*gCache[k];
	}

	gOutput[dispatchThreadID.xy] = blurColor;
}

[numthreads(1, N, 1)]
void VertBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 groupID : SV_GroupID,
				int3 dispatchThreadID : SV_DispatchThreadID,
				int groupIndexID : SV_GroupIndex)
{
	float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

	
	if(groupThreadID.y < gBlurRadius)
	{
		int y = max(dispatchThreadID.y - gBlurRadius, 0);
		gCache[groupThreadID.y] = gInput[int2(dispatchThreadID.x, y)];
	}
	if(groupThreadID.y >= N-gBlurRadius)
	{
		int y = min(dispatchThreadID.y + gBlurRadius, gInput.Length.y-1);
		gCache[groupThreadID.y+2*gBlurRadius] = gInput[int2(dispatchThreadID.x, y)];
	}
	
	gCache[groupThreadID.y+gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy-1)];


	GroupMemoryBarrierWithGroupSync();
	
	//
	// �帮��
	//

	float4 blurColor = float4(0, 0, 0, 0);
	
	for(int i = -gBlurRadius; i <= gBlurRadius; ++i)
	{
		int k = groupThreadID.y + gBlurRadius + i;
		
		blurColor += weights[i+gBlurRadius]*gCache[k];
		//blurColor += weights[gBlurRadius] * gCache[k];
	}
	
	gOutput[dispatchThreadID.xy] = blurColor;
}
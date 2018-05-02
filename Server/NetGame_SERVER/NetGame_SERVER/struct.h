#pragma once


struct IoContextEx
{
	WSAOVERLAPPED over;
	WSABUF m_wsabuf;
	UCHAR m_szIoBuf[MAX_BUFSIZE];
	eClientType m_eType;
};


struct Client
{
	float m_ix;
	float m_iy;
	float m_iz;

	bool m_bConnect;
	eBulletDir m_eDir;

	UCHAR m_szPacket_buf[MAX_PACKET];
	
	SOCKET m_ClientSocket;
	IoContextEx m_IoEx;
	int m_iPredata;
	int m_iCursize;

	mutex m_lock;

	float m_Timer;
};

#include <sdktools>
#include <socket>

new Handle:g_hHostIP 			= INVALID_HANDLE;
new Handle:g_hHostPort 		= INVALID_HANDLE;
new Handle:g_hPassword 		= INVALID_HANDLE;
new Handle:g_hReconnectTime 	= INVALID_HANDLE;

new Handle:g_hMainSocket		= INVALID_HANDLE;
new Handle:g_hTimer			= INVALID_HANDLE;

new bool:g_bIsFirstTimer = true;

new g_iGamemode = 1;
new ClientLanguage[MAXPLAYERS+1];

new String:LanguageChart[10][2][32] = {
	{"en", "English"},		//영어
	{"ko", "한국어"},			//한국어
	{"ja", "日本語"},			//일본어
	{"zh-CN", "中国简体(CN)"},	//중국어-간체(CN)
	{"zh-TW", "中國傳統(TW)"},	//중국어-번체(TW)
	{"ru", "русский"},		//러시아어
	{"de", "Deutsch"},		//독일어
	{"ar", "العربية"},			//아랍어
	{"fr", "francaise"},		//프랑스어
	{"la", "latin"}			//라틴어
};

public Plugin:myinfo = 
{
	name = "Google Translate Chating(구글번역기)",
	author = "ys24ys",
	description = "[SOCKET]Google Translate Chating(소켓 구글번역기)",
	version = "1.0.2",
	url = "http://ys24ys.iptime.org/"
}

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) == 0) g_iGamemode = 1;
	else if(strcmp(game, "synergy", false) == 0) g_iGamemode = 2;
	else g_iGamemode = 1;
	
	g_hHostIP			= CreateConVar("GT_Host_Server_IP", "ys24ys.iptime.org", "연결할 호스트 IP(또는 Domain)");
	g_hHostPort			= CreateConVar("GT_Host_Server_Port", "21567", "연결할 호스트 Port");
	g_hPassword			= CreateConVar("GT_Password", "174396", "연결할 호스트의 접속 인증번호");
	g_hReconnectTime		= CreateConVar("GT_ReconnectTime", "30.0", "재연결을 시도할 시간");

	RegConsoleCmd("say", CommandSay);
	AutoExecConfig(true, "google_translate");
}

public OnConfigsExecuted()
{
	if(g_hMainSocket == INVALID_HANDLE)
	{
		new String:IP[32];
		new Port = GetConVarInt(g_hHostPort); //Port 값을 받아옵니다.
		GetConVarString(g_hHostIP, IP, sizeof(IP)); //IP 값을 받아옵니다.
		
		g_hMainSocket = SocketCreate(SOCKET_TCP, OnSocketCreateError); //핸들에 소켓을 생성합니다.
		SocketConnect(g_hMainSocket, OnSocketConnected, OnClientSocketReceive, OnSocketDisconnected, IP, Port); //생성된 소켓으로 서버에 연결합니다.
	}
}

public Action:CommandSay(Client, args)
{
	if(args >= 1)
	{
		new String:Text[512];
		new String:Message[512];
		GetCmdArgString(Text, sizeof(Text));
		strcopy(Message, sizeof(Message), Text);
		
		StripQuotes(Message);
		TrimString(Message);
		
		if(StrContains(Message, "/t ") == 0)
		{
			if(Client < 1)
			{
				PrintToChatAll("[Google Translate] Error!")
				return Plugin_Continue;
			}
			ReplaceStringEx(Message, sizeof(Message), "/t ", "");
			Socket_ProcessText(Client, Message); //채팅내역 패킷화 및 전송
		
			return Plugin_Handled;
		}
		else if(StrContains(Message, "!Lang", false) >= 0 || StrContains(Message, "!언어", false) >= 0)
		{
			if(Client < 1)
			{
				PrintToChatAll("[Google Translate] Error!")
				return Plugin_Continue;
			}
			
			Menu_Language_Mein(Client);
		}
	}
	
	return Plugin_Continue;
}

Socket_ProcessText(Client, String:Text[])
{
	//패스워드, 유저이름, 채팅내용, 출력대상자 index, 출력언어
	new String:Password[32];
	GetConVarString(g_hPassword, Password, sizeof(Password));
	
	new String:PlayerName[128];
	GetClientName(Client, PlayerName, sizeof(PlayerName));
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsPlayerOnGameServer(i))
		{
			new String:Message[512];
			Format(Message, 512, "@%s/xet/%s/xet/%s/xet/%d/xet/%s", Password, PlayerName, Text, i, LanguageChart[ClientLanguage[i]][0]);
			Socket_SendMessage(g_hMainSocket, Message, i);
		}
	}
}

public Socket_SendMessage(Handle:socket, String:Message[], Client)
{
	if(IsPlayerOnGameServer(Client))
	{
		if(g_hMainSocket != INVALID_HANDLE)
		{
			SocketSend(g_hMainSocket, Message);
		}
	}
}




public OnSocketCreateError(Handle:socket, const ErrorType, const ErrorNum, any:arg)
{
	PrintToServer("[GT]server connect error : %i (Error Num : %i)", ErrorType, ErrorNum);
	
	if(g_hMainSocket != INVALID_HANDLE)
	{
		CloseHandle(g_hMainSocket);
		g_hMainSocket = INVALID_HANDLE;
	}
	if(g_hTimer == INVALID_HANDLE)
	{
		if(g_bIsFirstTimer == true)
		{
			g_bIsFirstTimer = false;
			
			g_hTimer = CreateTimer(GetConVarFloat(g_hReconnectTime), ReconnectTimer, _, TIMER_REPEAT);
		}
	}
}

public OnSocketConnected(Handle:socket, any:arg)
{
	if(g_hTimer != INVALID_HANDLE)
	{
		g_bIsFirstTimer = true;
		CloseHandle(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	new String:IP[32];
	GetConVarString(g_hHostIP, IP, sizeof(IP));
	PrintToServer("[GT]server connected: %s", IP);
	
	if(g_hMainSocket != INVALID_HANDLE)
	{
		new String:hostname[64];
		GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
		Format(hostname, sizeof(hostname), "$%s", hostname);
		SocketSend(g_hMainSocket, hostname);
	}
}

public OnClientSocketReceive(Handle:socket, const String:packet[], const packet_size, any:arg)
{
	new String:Password[64], String:Password_Tag[64], String:Message[512];
	GetConVarString(g_hPassword, Password, sizeof(Password));
	
	strcopy(Message, sizeof(Message), packet); //////////////////여기서부터 수정해야함 (비밀번호 인증, 패킷 잘라내서 본문만 따로추출 등)
	
	StripQuotes(Message);
	TrimString(Message);
	
	new String:Message_Explode[4][256];
	ExplodeString(Message, "/xet/", Message_Explode, 4, 256);
	
	new String:p_Password[256], String:p_Username[256], String:p_Chattext[256], String:p_OnClient[256];
	Format(p_Password, sizeof(p_Password), "%s", Message_Explode[0]);
	Format(p_Username, sizeof(p_Username), "%s", Message_Explode[1]);
	Format(p_Chattext, sizeof(p_Chattext), "%s", Message_Explode[2]);
	Format(p_OnClient, sizeof(p_OnClient), "%s", Message_Explode[3]);
	
	if(StrEqual(Password, p_Password, false) == true)
	{
		new Client = StringToInt(p_OnClient);
		if(IsPlayerOnGameServer(Client))
		{
			PrintToChat(Client, "\x04[GoogleTrans]\x01%s: %s", p_Username, p_Chattext);
		}
	}
	else
	{
		PrintToServer("[GT]password wrong");
		Socket_Clear(socket);
	}
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
	if(g_hMainSocket != INVALID_HANDLE)
	{
		Socket_Clear(socket);
		CloseHandle(g_hMainSocket);
		g_hMainSocket = INVALID_HANDLE;
	}
	if(g_hTimer == INVALID_HANDLE)
	{
		if(g_bIsFirstTimer == true)
		{
			g_bIsFirstTimer = false;
			g_hTimer = CreateTimer(GetConVarFloat(g_hReconnectTime), ReconnectTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	new String:IP[32];
	GetConVarString(g_hHostIP, IP, sizeof(IP));
	PrintToServer("[GT]server disconnected: %s", IP);
}

public Action:ReconnectTimer(Handle:Timer, any:data) //메인 서버로의 접속을 재시도합니다.
{
	if(g_hMainSocket == INVALID_HANDLE)
	{
		new String:IP[32];
		new Port = GetConVarInt(g_hHostPort);
		GetConVarString(g_hHostIP, IP, sizeof(IP));
		
		g_hMainSocket = SocketCreate(SOCKET_TCP, OnSocketCreateError);
		SocketConnect(g_hMainSocket, OnSocketConnected, OnClientSocketReceive, OnSocketDisconnected, IP, Port);
	}
	
	g_hTimer = INVALID_HANDLE;
}

Socket_Clear(Handle:Socket) //소켓 정보를 초기화합니다.
{
	if(Socket != INVALID_HANDLE)
	{
		CloseHandle(Socket);
		Socket = INVALID_HANDLE;
	}
}

public Menu_Language_Mein(Client)
{
	new Handle:menu = CreateMenu(Callback_Menu_Language_Mein);
	decl String:TitleFormat[256], String:Count[128], String:Text[128];
	Format(TitleFormat, 256, "◈Language◈\nSelect Your Language\nCurrent : %s", LanguageChart[ClientLanguage[Client]][1]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	
	for(new i=0; i<=9; i++)
	{
		Format(Count, 128, "%d", i);
		Format(Text, 128, "%s", LanguageChart[i][1]);
		AddMenuItem(menu, Count, Text);
	}
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Menu_Language_Mein(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			
			if(action == MenuAction_Select)
			{
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Lang = StringToInt(sInfo)
				PrintToChat(param1, "\x04[Google Translate]\x01Change Language : \x04%s", LanguageChart[Lang][1]);
				ClientLanguage[param1] = Lang;
			}
		}
	}
}

stock bool:IsPlayerOnGameServer(Client)
{
	switch (g_iGamemode)
	{
		case 1:
		{
			if(IsClientConnected(Client) && IsClientInGame(Client)) return true;
		}
		case 2:
		{
			if(IsClientConnected(Client)) return true;
		}
	}
	return false;
}
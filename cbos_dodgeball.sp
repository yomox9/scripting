#include <sdktools>
#include <socket>

new Handle:g_hMainServer		= INVALID_HANDLE;
new Handle:g_hMainServerIP			= INVALID_HANDLE;
new Handle:g_hMainServerPort		= INVALID_HANDLE;
new Handle:g_hServerTag			= INVALID_HANDLE;
new Handle:g_hPassword			= INVALID_HANDLE;
new Handle:g_hReconnectTime		= INVALID_HANDLE;

new Handle:g_hMainSocket		= INVALID_HANDLE;
new Handle:g_hChilds			= INVALID_HANDLE;
new Handle:g_hTimer			= INVALID_HANDLE;

new bool:g_bIsMainServer;
new bool:g_bIsFirstTimer = true;

public Plugin:myinfo = 
{
	name = "Chat between other servers",
	author = "ABCDE & Trostal, Mr.Halt (a.k.a. 할짓없는놈, FineDrum), ys24ys (a.k.a. 흑룡)",
	description = "Send text to all server connected",
	version = "2.2",
	url = ""
}

public OnPluginStart()
{
	g_hMainServer			= CreateConVar("CBOS_Main_Server", "1", "If server using this plugin is master server or not");
	g_hMainServerIP			= CreateConVar("CBOS_Main_Server_IP", "0.0.0.0", "Main server's IP");
	g_hMainServerPort		= CreateConVar("CBOS_Main_Server_Port", "51000", "Port to connect to main server");
	g_hServerTag			= CreateConVar("CBOS_Tag", "(Another Server)", "Tag to prefix");
	g_hPassword				= CreateConVar("CBOS_Password", "ABCDE is genius", "Password");
	g_hReconnectTime		= CreateConVar("CBOS_ReconnectTime", "10.0", "Time(Float) to reconnect to main server");

	RegConsoleCmd("say", CommandSay);
	AutoExecConfig();
}

public OnPluginEnd()
{
	Socket_SendDisonnectMessage(g_hMainSocket);
	
	if(g_hMainSocket != INVALID_HANDLE)
	{
		CloseHandle(g_hMainSocket);
		g_hMainSocket = INVALID_HANDLE;
	}
	if(g_hChilds != INVALID_HANDLE)
	{
		CloseHandle(g_hChilds);
		g_hChilds = INVALID_HANDLE;
	}
	if(!g_bIsMainServer)
	{
		g_bIsFirstTimer = true;
		
		if(g_hTimer != INVALID_HANDLE)
		{
			CloseHandle(g_hTimer);
			g_hTimer = INVALID_HANDLE;
		}
	}
}

public OnMapStart()
{
	AutoExecConfig();
}

public OnMapEnd()
{
	new String:NextMap[256], String:Tag[128], String:Message[512];
	GetNextMap(NextMap, sizeof(NextMap));
	
	if(!StrEqual(NextMap, "sm_nextmap"))
	{
		GetConVarString(g_hServerTag, Tag, sizeof(Tag));
		Format(Message, sizeof(Message), "Changing map to: \x04%s", NextMap);
		
		Socket_AddTag(g_hMainSocket, Message);
	}
}

public OnConfigsExecuted()
{
	if(g_hMainSocket == INVALID_HANDLE)
	{
		if(GetConVarBool(g_hMainServer))
		{
			g_bIsMainServer = true;
			
			Socket_StartListen();
		}
		else
		{
			g_bIsMainServer = false;
			
			new String:IP[32];
			new Port = GetConVarInt(g_hMainServerPort);
			GetConVarString(g_hMainServerIP, IP, sizeof(IP));
			
			g_hMainSocket = SocketCreate(SOCKET_TCP, OnSocketCreateError);
			SocketConnect(g_hMainSocket, OnSocketConnected, OnClientSocketReceive, OnSocketDisconnected, IP, Port);
		}
	}
}

public Action:CommandSay(client, args)
{
	if(args >= 1)
	{
		new String:Text[512];
		new String:Message[512];
		GetCmdArgString(Text, sizeof(Text));
		strcopy(Message, sizeof(Message), Text);
		
		StripQuotes(Message);
		TrimString(Message);
		
		if(StrContains(Message, "\\") == 0)
		{
			ReplaceStringEx(Message, sizeof(Message), "\\", "");
			Socket_ProcessText(client, Message, sizeof(Message));
			
			return Plugin_Handled;
		}
		else if(StrContains(Message, "\\ ") == 0)
		{
			ReplaceStringEx(Message, sizeof(Message), "\\ ", "");
			Socket_ProcessText(client, Message, sizeof(Message));
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// functions

Socket_StartListen()
{
	if(g_bIsMainServer)
	{
		new String:IP[32];
		Socket_GetServerIP(IP, sizeof(IP));
		new Port = GetConVarInt(g_hMainServerPort);
			
		g_hMainSocket = SocketCreate(SOCKET_TCP, OnSocketCreateError);
		SocketSetOption(g_hMainSocket, SocketReuseAddr, 1);
		SocketBind(g_hMainSocket, IP, Port);	
		SocketListen(g_hMainSocket, OnMainSocketIncoming);
		
		g_hChilds = CreateArray();
	}
}

Socket_ProcessText(client, String:Text[], Length)
{
	Format(Text, Length, "%N :\x01 %s", client, Text);
	
	Socket_AddTag(g_hMainSocket, Text);
}

Socket_AddTag(Handle:Socket, const String:Message[])
{
	decl String:Tag[128], String:Tagged_Message[512];
	GetConVarString(g_hServerTag, Tag, sizeof(Tag));
	Format(Tagged_Message, sizeof(Tagged_Message), "\x04%s \x01%s", Tag, Message);
	
	if(g_bIsMainServer)
	{
		Socket_Broadcast(INVALID_HANDLE, Tagged_Message);
	}
	else if(Socket != INVALID_HANDLE)
	{
		new String:Encrypted_Message[512];
		Socket_EncryptMessage(Encrypted_Message, sizeof(Encrypted_Message), Tagged_Message);
		
		SocketSend(Socket, Encrypted_Message);
		PrintToChatAll(Tagged_Message);
	}
}

Socket_Broadcast(Handle:Socket, const String:Message[])
{
	new Size = GetArraySize(g_hChilds);
	new Handle:ClientServer = INVALID_HANDLE;

	for(new i = 0; i < Size; i++)
	{
		ClientServer = GetArrayCell(g_hChilds, i);
	
		if(ClientServer != Socket)
		{
			new String:Encrypted_Message[512];
			Socket_EncryptMessage(Encrypted_Message, sizeof(Encrypted_Message), Message);
			SocketSend(ClientServer, Encrypted_Message);
		}
	}
	
	PrintToChatAll(Message);
}

Socket_EncryptMessage(String:Message[], const Size, const String:Original_Message[])
{
	decl String:Password[64];
	GetConVarString(g_hPassword, Password, sizeof(Password));

	Format(Message, Size, "%s/%s", Password, Original_Message);
}

Socket_SendConnectMessage(Handle:Socket)
{
	Socket_AddTag(Socket, "Connect from main server.");
}

Socket_SendDisonnectMessage(Handle:Socket)
{
	Socket_AddTag(Socket, "Disconnect from main server.");
}

Socket_GetServerIP(String:IP[], Length)
{
	new HostIP = GetConVarInt(FindConVar("hostip"));
	Format(IP, Length, "%i.%i.%i.%i", (HostIP >> 24 & 0xFF), (HostIP >> 16 & 0xFF), (HostIP >> 8 & 0xFF), (HostIP & 0xFF));
	
	PrintToServer("[CBOS] Current Server IP : %s", IP);
}

Socket_Clear(Handle:Socket)
{
	if(g_hMainSocket != INVALID_HANDLE)
	{
		if(Socket != INVALID_HANDLE)
		{
			new Size = GetArraySize(g_hChilds);
			
			for(new i = 0; i < Size; i++)
			{
				if(GetArrayCell(g_hChilds, i) == Socket)
				{
					RemoveFromArray(g_hChilds, i);
					break;
				}
			}
			
			CloseHandle(Socket);
			Socket = INVALID_HANDLE;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// socket callback

public OnSocketCreateError(Handle:socket, const ErrorType, const ErrorNum, any:arg)
{
	if(g_bIsMainServer)
	{
		PrintToServer("[CBOS] Main server got error of creating socket : %i (Error Num : %i)", ErrorType, ErrorNum);
	}
	else
	{
		PrintToServer("[CBOS] Client server got error of creating socket : %i (Error Num : %i)", ErrorType, ErrorNum);
		
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
}

public Action:ReconnectTimer(Handle:Timer, any:data)
{
	if(!g_bIsMainServer)
	{
		if(g_hMainSocket == INVALID_HANDLE)
		{
			new String:IP[32];
			new Port = GetConVarInt(g_hMainServerPort);
			GetConVarString(g_hMainServerIP, IP, sizeof(IP));
			
			g_hMainSocket = SocketCreate(SOCKET_TCP, OnSocketCreateError);
			SocketConnect(g_hMainSocket, OnSocketConnected, OnClientSocketReceive, OnSocketDisconnected, IP, Port);
		}
	}
	
	g_hTimer = INVALID_HANDLE;
}

public OnMainSocketIncoming(Handle:socket, Handle:new_socket, String:remoteip[], port, any:arg)
{
	if(socket != INVALID_HANDLE && new_socket != INVALID_HANDLE)
	{
		PushArrayCell(g_hChilds, new_socket);
		PrintToServer("[CBOS] New client server has been connected");
	}

	SocketSetReceiveCallback(new_socket, OnMainSocketReceive);
	SocketSetDisconnectCallback(new_socket, OnSocketDisconnected);
	SocketSetErrorCallback(new_socket, OnSocketError);
}

public OnMainSocketReceive(Handle:socket, const String:packet[], const packet_size, any:arg)
{
	new String:Password[64], String:Password_Tag[64], String:Message[512];
	GetConVarString(g_hPassword, Password, sizeof(Password));
	Format(Password_Tag, sizeof(Password_Tag), "%s/", Password);
	
	strcopy(Message, sizeof(Message), packet);
	new Found_Password = ReplaceStringEx(Message, sizeof(Message), Password_Tag, "");
	
	if(Found_Password == 0)
	{
		Socket_Broadcast(socket, Message);
	}
	else if(Found_Password == -1)
	{
		PrintToServer("[CBOS] Connection has been rejected (Wrong password)");
		Socket_Clear(socket);
	}
}

public OnClientSocketReceive(Handle:socket, const String:packet[], const packet_size, any:arg)
{
	new String:Password[64], String:Password_Tag[64], String:Message[512];
	GetConVarString(g_hPassword, Password, sizeof(Password));
	Format(Password_Tag, sizeof(Password_Tag), "%s/", Password);
	
	strcopy(Message, sizeof(Message), packet);
	new Found_Password = ReplaceStringEx(Message, sizeof(Message), Password_Tag, "");
	
	if(Found_Password == 0)
	{
		PrintToChatAll(Message);
	}
	else
	{
		PrintToServer("[CBOS] Connection has been rejected (Wrong password)");
		Socket_Clear(socket);
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
	GetConVarString(g_hMainServerIP, IP, sizeof(IP));
	PrintToServer("[CBOS] Connected to main server", IP);
	
	Socket_SendConnectMessage(g_hMainSocket);
}

public OnSocketDisconnected(Handle:socket, any:arg)
{
	if(g_bIsMainServer)
	{
		Socket_Clear(socket);
		PrintToServer("[CBOS] Client server has been disconnected");
	}
	else
	{
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
				g_hTimer = CreateTimer(GetConVarFloat(g_hReconnectTime), ReconnectTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		new String:IP[32];
		GetConVarString(g_hMainServerIP, IP, sizeof(IP));
		PrintToServer("[CBOS] Disconnected from main server", IP);
	}
}

public OnSocketError(Handle:socket, const ErrorType, const ErrorNum, any:arg)
{
	Socket_Clear(socket);
	PrintToServer("[CBOS] Current socket has gotten Error : %i (Error Num : %i)", ErrorType, ErrorNum);
}
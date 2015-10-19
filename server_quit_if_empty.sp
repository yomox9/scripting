#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
#define TIMER_INTERVAL 30.0

public Plugin:myinfo =  
{
  name = "server quit if empty",
  author = "kimoto",
  description = "server quit if empty",
  version = PLUGIN_VERSION,
  url = "http://kymt.me/"
};

new Handle:g_timer = INVALID_HANDLE;

public Action:Timer_ServerQuit(Handle:timer, any:client)
{
  DebugPrint("each timer");
  ServerQuitIfEmpty();
}

public OnPluginStart()
{
  RegServerCmd("server_quit_if_empty", Command_ServerQuitIfEmpty);
  RegServerCmd("server_quit_next_empty", Command_ServerQuitNextEmpty);
}

public IsClientBot(client)
{
  new String:SteamID[256];
  GetClientAuthString(client, SteamID, sizeof(SteamID));
  if (StrEqual(SteamID, "BOT"))
    return true;
  return false;
}

public IsServerEmpty()
{
  for(new i=1; i<GetMaxClients(); i++){
    if( IsClientInGame(i) && !IsClientBot(i) ){ // human player & in game
      return false;
    }
  }
  return true;
}

public ServerQuitIfEmpty()
{
  DebugPrint("server quit next empty");
  if( IsServerEmpty() ){
    DebugPrint("server is empty try to restart");
    if( g_timer != INVALID_HANDLE){
      KillTimer(g_timer);
      g_timer = INVALID_HANDLE;
    }
    ServerCommand("quit");
  }else{
    DebugPrint("server is not empty");
  }
}

public Action:Command_ServerQuitIfEmpty(args)
{
  ServerQuitIfEmpty();
}

public Action:Command_ServerQuitNextEmpty(args)
{
  if(g_timer == INVALID_HANDLE){
    ServerQuitIfEmpty();
    g_timer = CreateTimer(TIMER_INTERVAL, Timer_ServerQuit, 0, TIMER_REPEAT);
  }else{
    DebugPrint("already executed!");
  }
}

public DebugPrint(const String:Message[], any:...)
{
  decl String:DebugBuff[256];
  VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
  LogMessage(DebugBuff);
}


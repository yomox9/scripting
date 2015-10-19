#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"
#define TIMER_INTERVAL 30.0

public Plugin:myinfo =  
{
  name = "server cln if empty",
  author = "kimoto / Modified yomox9",
  description = "server cln if empty",
  version = PLUGIN_VERSION,
  url = "http://kymt.me/"
};

new Handle:g_timer = INVALID_HANDLE;

public Action:Timer_ServerQuit(Handle:timer, any:client)
{
  DebugPrint("each timer");
  ServerclnIfEmpty();
}

public OnPluginStart()
{
  RegServerCmd("server_cln_if_empty", Command_ServerclnIfEmpty);
  RegServerCmd("server_cln_next_empty", Command_ServerclnNextEmpty);
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

public ServerclnIfEmpty()
{
  DebugPrint("server changelevel_next next empty");
  if( IsServerEmpty() ){
    DebugPrint("server is empty try to changelevel_next");
    if( g_timer != INVALID_HANDLE){
      KillTimer(g_timer);
      g_timer = INVALID_HANDLE;
    }
    ServerCommand("changelevel_next");
  }else{
    DebugPrint("server is not empty");
  }
}

public Action:Command_ServerclnIfEmpty(args)
{
  ServerclnIfEmpty();
}

public Action:Command_ServerclnNextEmpty(args)
{
  if(g_timer == INVALID_HANDLE){
    ServerclnIfEmpty();
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


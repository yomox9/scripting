

#include <sdktools>
#include <sourcemod>

public Plugin:myinfo =
{
  name = "Set Spectate",
  author = "데자뷰",
  version = "1.0.0"
};

public bool:IsStillConnect(Client)
{
  if(Client != 0)
    if(IsValidEntity(Client))
      if(Client <= MaxClients)
        if(IsClientConnected(Client))
          return true;
          
  return false;
}

public OnPluginStart()
{
  RegConsoleCmd("say", Chatting);
  RegConsoleCmd("say_team", Chatting);
  
  RegConsoleCmd("sm_joinplay", Player);
  RegConsoleCmd("sm_joinspec", Spectator);
  
  HookEvent("player_team", Event_Player, EventHookMode_Pre);
}

public Action:Player(Client, Args)
{
  if(GetClientTeam(Client) == 1)
  {
    decl String:ClientName[32];
    GetClientName(Client, ClientName, 32);
    
    ChangeClientTeam(Client, 0);
    PrintToChatAll("Player %s joined players team (플레이 팀에 참가 하셨습니다).", ClientName);
  }
  
  return Plugin_Handled;
}

public Action:Spectator(Client, Args)
{
  if(GetClientTeam(Client) == 0)
  {
    if(IsPlayerAlive(Client)) ForcePlayerSuicide(Client);

    decl String:ClientName[32];
    GetClientName(Client, ClientName, 32);
    
    ChangeClientTeam(Client, 1);
    PrintToChatAll("Player %s joined spectators team (관전자 팀에 참가하셨습니다).", ClientName);
  }
  
  return Plugin_Handled;
}

public Action:Event_Player(Handle:Event, const String:Name[], bool:Broadcast)
{
	SetEventBroadcast(Event, true);
	return Plugin_Continue;
}

public Action:Chatting(Client, Args)
{
  if(!IsStillConnect(Client)) return Plugin_Continue;

  if(GetClientTeam(Client) == 1)
  {
    decl String:ClientName[32], String:Message[256];
    
    GetCmdArgString(Message, 256);
    Message[strlen(Message) - 1] = '\0';
    GetClientName(Client, ClientName, 32);

    PrintToServer("(SPEC) %s : %s", ClientName, Message[1]);
    PrintToChatAll("(SPEC) %s : %s", ClientName, Message[1]);
    
    return Plugin_Handled;
  }
  
  return Plugin_Continue;
}
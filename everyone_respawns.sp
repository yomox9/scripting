#include <sourcemod>
#include <smlib/games/nmrih>

#define PLUGIN_VERSION "1.0.2"

new bool:g_bEnabled;

public Plugin:myinfo = { name = "[NMRiH] Everyone Respawns", author = "Marcus", description = "On a player's death, it gives him a credit to respawn with.", version = PLUGIN_VERSION, url = "http://www.snbx.info" };

public OnPluginStart()
{
	CreateConVar("sm_everyonerespawns_version", PLUGIN_VERSION, "Everyone Respawns Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);

	HookEvent("player_death", Event_Death, EventHookMode_Pre);
}

public OnMapStart()
{
	decl String:sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));

	if (StrContains(sMap, "nmo_") != -1) g_bEnabled = false;
		else
	if (StrContains(sMap, "nms_") != -1) g_bEnabled = true;
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!g_bEnabled) return;

	if (Nmrih_Client_GetTokens(iClient) <= 1)
		Nmrih_Client_SetTokens(iClient, 1)
}

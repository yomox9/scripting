/**
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <attachables>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define VERSION "0.9"

//Game detection constants
#define GAME_OTHER   		0
#define GAME_TF2			1
#define GAME_CSS			2
#define GAME_DODS			3
#define GAME_L4D			4
#define GAME_L4D2			5

#define EF_BONEMERGE	 	1

/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo = 
{
	name = "Model Fun",
	author = "Arg!",
	description = "Spawn entites/models in game in various ways",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=775016"
};


/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Handle:hTopMenu = INVALID_HANDLE;
new Handle:h_cvarMaxSpawns = INVALID_HANDLE;
new g_GameType;								//for use in game specific settigns, GameDetect will set this.
new g_maxSpawns = 10;

/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/
#include "modelfun/lists.sp"
#include "modelfun/model.sp"

#include "modelfun/hat.sp"
#include "modelfun/phat.sp"


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart()
{
	LoadTranslations("common.phrases");	
	
	CreateConVar("sm_modelfun_version", VERSION, "Spawn entites/models in game in various ways", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	h_cvarMaxSpawns = CreateConVar("sm_maxitemspawns", "10", "Max items ModelFun is allowed to spawn, change effective on map change", FCVAR_PLUGIN);
	
	g_maxSpawns = GetConVarInt(h_cvarMaxSpawns);
	
	HookConVarChange(h_cvarMaxSpawns, MaxSpawnsChanged);
	
	//detect game type
	GameDetect();
	
	//setup each plugin include
	OnPluginStart_Lists();
	OnPluginStart_Model();
	OnPluginStart_Hat();
	
	if( ParticlesAllowed() )
		OnPluginStart_PHat();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Account for late loading
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	OnMapStart_Model();
}

public OnMapEnd()
{
	OnMapEnd_Hat();
	
	if( ParticlesAllowed() )
		OnMapEnd_PHat();
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	new bool:retval;
	
	retval = OnClientConnect_Hat(client);
	
	if( ParticlesAllowed() )
		retval = OnClientConnect_PHat(client);
	
	return retval;
}

public OnPluginEnd()
{
	OnPluginEnd_Lists();
	
	OnPluginEnd_Model();
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_team", Event_PlayerTeam);
	UnhookEvent("player_disconnect", Event_PlayerDisconnect);
}

public OnLibraryRemoved(const String:name[])
{
	//remove this menu handle if adminmenu plugin unloaded
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("modelfun");
	
	
	new bool:retval;
	
	retval = AskPluginLoad_Hat();
	retval = AskPluginLoad_PHat();
	
	if( retval )
	{
		return APLRes_Success;
	}
	else
	{
		return APLRes_SilentFailure;
	}
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	
	Event_PlayerSpawn_Hat(event);
	
	if( ParticlesAllowed() )
		Event_PlayerSpawn_PHat(event);
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	Event_PlayerDeath_Hat(event);
	
	if( ParticlesAllowed() )
		Event_PlayerDeath_PHat(event);
	
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) 
{
	Event_PlayerTeam_Hat(event);
	
	return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	if( ParticlesAllowed() )
		Event_PlayerDisc_PHat(event);
	
	return Plugin_Continue;
}


public MaxSpawnsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl newVal;
	
	newVal = StringToInt( newValue );
	
	//is the cvar set to a valid value
	if( newVal > 0 )
	{
		g_maxSpawns = newVal;
	}
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
GameDetect()
{
	new String:gamename[10];
	GetGameFolderName(gamename,sizeof(gamename));
	
	if(StrEqual(gamename,"dods"))
	{
		g_GameType = GAME_DODS;
		LogMessage("Game detected as Day of Defeat: Source (GAME_DODS)");
	}
	else if(StrEqual(gamename,"tf"))
	{
		g_GameType = GAME_TF2;
		LogMessage("Game detected as Team Fortress 2: Source (GAME_TF2)");
	}
	else if(StrEqual(gamename,"cstrike"))
	{
		g_GameType = GAME_CSS;
		LogMessage("Game detected as Counter-Strike: Source (GAME_CSS)");
	}
	else if(StrEqual(gamename,"left4dead"))
	{
		g_GameType = GAME_L4D;
		LogMessage("Game detected as Left 4 Dead (GAME_L4D)");
	}
	else if(StrEqual(gamename,"left4dead2"))
	{
		g_GameType = GAME_L4D2;
		LogMessage("Game detected as Left 4 Dead 2 (GAME_L4D2)");
	}
	else
	{
		g_GameType = GAME_OTHER;
		LogMessage("Game detected as Other (unknown) (GAME_OTHER)");
	}
}

bool:ParticlesAllowed()
{
	return( g_GameType == GAME_TF2 || g_GameType == GAME_L4D );
}

/*****************************************************************


			A D M I N   M E N U   F U N C T I O N S


*****************************************************************/
public OnAdminMenuReady(Handle:topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	//Save the Handle
	hTopMenu = topmenu;
	
	//Build the "Player Commands" category
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		SetupAdminMenu_Hat(player_commands);
		
		if( ParticlesAllowed() )
			SetupAdminMenu_PHat(player_commands);
	}

	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (server_commands != INVALID_TOPMENUOBJECT)
	{
		SetupAdminMenu_Model_RemoveAll(server_commands);
		SetupAdminMenu_Model_Physics(server_commands);
		SetupAdminMenu_Model_Static(server_commands);		
	}
}
/***************************************************************************************

	Copyright (C) 2012 BCServ (plugins@bcserv.eu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
***************************************************************************************/

/***************************************************************************************


	C O M P I L E   O P T I O N S


***************************************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/***************************************************************************************


	P L U G I N   I N C L U D E S


***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>
#include <smlib/games/nmrih>

/***************************************************************************************


	P L U G I N   I N F O


***************************************************************************************/
public Plugin:myinfo = {
	name 						= "[NMRIH] Infinite Ammo",
	author 						= "BCServ - Chanz",
	description 				= "Like the title says INFINITE AMMO for all weapons in No More Romm in Hell",
	version 					= "1.2",
	url 						= "https://forums.alliedmods.net/showthread.php?p=1789646"
}

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/
#define MAX_BUTTONS 31
#define DISALLOW_SOUND "buttons/button10.wav"
#define THINK_INTERVAL 1.0

#define SET_AMMO_COUNT_TO 30

/***************************************************************************************


	G L O B A L   V A R S


***************************************************************************************/
// Server Variables


// Plugin Internal Variables


// Console Variables
new Handle:g_cvarEnable 					= INVALID_HANDLE;


// Console Variables: Runtime Optimizers
new g_iPlugin_Enable 						= 1;

// Timers


// Library Load Checks


// Game Variables


// Map Variables


// Client Variables
new g_iClient_LastButtons[MAXPLAYERS+1];
new bool:g_bPlayerRunCmd_Allow = false;

// M i s c


/***************************************************************************************


	F O R W A R D   P U B L I C S


***************************************************************************************/
public OnPluginStart()
{
	// Initialization for SMLib
	PluginManager_Initialize("nmrih-infinite-ammo", "[SM] ");
	
	// Translations
	// LoadTranslations("common.phrases");
	
	
	// Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	AddCommandListener(CommandHook_DropItem,"dropitem");
	//AddCommandListener(CommandHook_All,"");
	
	// Register New Commands (PluginManager_RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	// Register Admin Commands (PluginManager_RegAdminCmd)
	
	
	// Cvars: Create a global handle variable.
	g_cvarEnable = PluginManager_CreateConVar("enable", "1", "Enables or disables this plugin");
	
	
	// Hook ConVar Change
	HookConVarChange(g_cvarEnable, ConVarChange_Enable);
	
	
	// Event Hooks
	PluginManager_HookEvent("nmrih_practice_ending",Event_Practice_Ending);
	PluginManager_HookEvent("nmrih_reset_map",Event_Reset_Map);
	PluginManager_HookEvent("player_death",Event_Player_Death);
	
	// Library
	
	
	/* Features
	if(CanTestFeatures()){
		
	}
	*/
	
	// Create ADT Arrays
	
	
	// Timers
	CreateTimer(THINK_INTERVAL,Timer_Think,INVALID_HANDLE,TIMER_REPEAT);
	
	//Add Tag
	Server_AddTag("infinite ammo");
}

public OnMapStart() {
	
	// hax against valvefail (thx psychonic for fix)
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE) {
		SetConVarString(Plugin_VersionCvar, Plugin_Version);
	}
	
	//PrecacheSound(DISALLOW_SOUND,true);
}

public OnConfigsExecuted(){
	
	// Set your ConVar runtime optimizers here
	g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	
	// Mind: this is only here for late load, since on map change or server start, there isn't any client.
	// Remove it if you don't need it.
	Client_InitializeAll();
}

public OnClientPutInServer(client){
	
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client){
	
	Client_Initialize(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulsre, Float:vel[3], Float:angles[3], &weapon){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	if(!g_bPlayerRunCmd_Allow){
		return Plugin_Continue;
	}
	
	for (new i = 0; i < MAX_BUTTONS; i++) {
		
		new button = (1 << i);
		
		if ((buttons & button)) {
			
			if (!(g_iClient_LastButtons[client] & button)) {
				
				if(!OnButtonPress(client, button)){
					
					buttons &= ~button;
				}
			}
		} 
		else if ((g_iClient_LastButtons[client] & button)) {
			
			OnButtonRelease(client, button);
		} 
	}
	
	g_iClient_LastButtons[client] = buttons;
	return Plugin_Continue;
}

stock OnButtonPress(client, button) {
	
	if(IsPlayerAlive(client)){
		
		switch(button){
			
			case IN_RELOAD:
			{	
				if(!HasEnoughAmmoToReload(client)){
					
					SetInfiniteAmmo(client);
					g_bPlayerRunCmd_Allow = false;
					
					return false;
				}
			}
		}
	}
	return true;
}

stock OnButtonRelease(client, button) {
	
}

/**************************************************************************************


	C A L L B A C K   F U N C T I O N S


**************************************************************************************/
public Action:Timer_Think(Handle:timer){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	/*LOOP_CLIENTS(client,CLIENTFILTER_ALIVE){
		
		SetInfiniteAmmo(client);
	}*/
	
	g_bPlayerRunCmd_Allow = true;
	return Plugin_Continue;
}

/**************************************************************************************

	C O N  V A R  C H A N G E

**************************************************************************************/
/* Example Callback Con Var Change*/
public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_Enable = StringToInt(newVal);
}



/**************************************************************************************

	C O M M A N D S

**************************************************************************************/
/* Example Command Callback
public Action:Command_(client, args)
{
	
	return Plugin_Handled;
}
*/
public Action:CommandHook_DropItem(client, const String:command[], argc){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	//decl String:argString[192];
	//GetCmdArgString(argString,sizeof(argString));
	
	PrintCenterText(client," \n \n \n \n \n       Infinite Ammo is enabled!\n   Dropped ammo will be deleted!\nPress 'Reload' to receive new ammo.");
	//EmitSoundToClient(client,DISALLOW_SOUND,SOUND_FROM_PLAYER,SNDCHAN_AUTO,SNDLEVEL_DISHWASHER);
	
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}
public Action:CommandHook_All(client, const String:command[], argc){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	decl String:argString[192];
	GetCmdArgString(argString,sizeof(argString));
	
	PrintToConsole(client,"Comamnd: '%s %s'",command,argString);
	
	return Plugin_Continue;
}

/**************************************************************************************

	E V E N T S

**************************************************************************************/
/* Example Callback Event
public Action:Event_Example(Handle:event, const String:name[], bool:dontBroadcast)
{

}
*/
public Action:Event_Practice_Ending(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}
public Action:Event_Reset_Map(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}
public Action:Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast){
	
	if(g_iPlugin_Enable == 0){
		return Plugin_Continue;
	}
	
	RemoveAllAmmoBoxes();
	return Plugin_Continue;
}
/***************************************************************************************


	P L U G I N   F U N C T I O N S


***************************************************************************************/



/***************************************************************************************

	S T O C K

***************************************************************************************/
stock bool:Server_AddTag(const String:tag[])
{
	static Handle:cvarTags = INVALID_HANDLE;
	
	if (cvarTags == INVALID_HANDLE) {
		
		cvarTags = FindConVar("sv_tags");
		
		if (cvarTags == INVALID_HANDLE) {
			return false;
		}
	}
	
	decl String:currentTags[255];
	GetConVarString(cvarTags, currentTags, sizeof(currentTags));

	if (StrContains(currentTags, tag, false) == -1) {
		
		Format(currentTags, sizeof(currentTags), "%s,%s", currentTags, tag);
		SetConVarString(cvarTags, currentTags);
	}
	
	return true;
}

stock bool:HasEnoughAmmoToReload(client){
	
	new activeWeapon = Client_GetActiveWeapon(client);
	
	if(activeWeapon != INVALID_ENT_REFERENCE){
		
		new primaryAmmo = 0;
		Client_GetWeaponPlayerAmmoEx(client,activeWeapon,primaryAmmo);
		
		if(primaryAmmo >= SET_AMMO_COUNT_TO){
			
			return true;
		}
	}
	
	return false;
}

stock SetInfiniteAmmo(client){
	
	new activeWeapon = Client_GetActiveWeapon(client);
	
	if(activeWeapon != INVALID_ENT_REFERENCE){
		
		Client_SetWeaponPlayerAmmoEx(client,activeWeapon,SET_AMMO_COUNT_TO);
	}
}

stock RemoveAllAmmoBoxes(){
	
	static lastTime = 0;
	new theTime = GetTime();
	if(lastTime == theTime){
		return;
	}
	lastTime = theTime;
	
	new maxEntities = GetMaxEntities();
	
	for(new entity=MaxClients+1;entity<maxEntities;entity++){
		
		if(IsValidEdict(entity) && Entity_ClassNameMatches(entity,"item_ammo_box",true)){
			
			Entity_Kill(entity);
		}
	}
}

stock Client_InitializeAll(){
	
	for(new client=1;client<=MaxClients;client++){
		
		if(!IsClientInGame(client)){
			continue;
		}
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client){
	
	//Variables
	Client_InitializeVariables(client);
	
	
	//Functions
	
	
	//Functions where the player needs to be in game
}

stock Client_InitializeVariables(client){
	
	//Plugin Client Vars
	g_iClient_LastButtons[client] = 0;
}


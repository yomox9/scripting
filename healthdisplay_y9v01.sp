
/********************************************
* 
* Health Display Version "2.11.45"
* 
*********************************************
* Description:
*********************************************
* Shows the health of an entity (as HUD text or in the Hintbox). Highly customizable. Supports multi tanks in L4D. Works for all games/mods (if not tell me and I'll add suport).
* 
*********************************************
* INSTALLATION & UPDATE:
*********************************************
*     - Installation:
*         - Download sfPlayers config extension (get the newest version here: https://forums.alliedmods.net/showthread.php?t=69167 )
*         - Unzip the file into your main mod folder (there where the other folders are, like: addons, bin, cfg, maps...)
*         - Go to the config file and check the settings: addons/sourcemod/configs/healthdisplay.conf
*         - Done.
* 
*     - Update:
*         - IF YOU UPDATE THIS PLUGING BE SURE TO DELETE THE OLD 'cfg/sourcemod/shownpchp.cfg' or 'addons/sourcemod/configs/healthdisplay.conf'	
*         - Check if the Config extension is uptodate (see/get the newest version here: https://forums.alliedmods.net/showthread.php?t=69167 )
*         - Restart the map or the server and look into the console or error log files for errors.
*         - Done.
* 
*     - Update from older Versions (1.3.13 and older):
*         - Delete <modfolder>/addons/sourcemod/plugins/shownpchp.smx
*         - Delete <modfolder>/cfg/sourcemod/shownpchp.cfg
*         - Continue by 'Update' see above...
* 
*********************************************
* Health Display Config Vars: 
*********************************************
* Note: These are named the same as the Server Console Variables (cvars) ingame.
* 
* Main console variable to enable or disable Health Display:
* Possible settings are: false=Disable Health Display, true=Enable Health Display).
sm_healthdisplay_enable = true;
*
* Where do you want to display the health info: 
* Possible is: 0=Choose Automaticly, 1=Force Hud Text (HL2DM/SourceForts), 2=Force Hint Text (CSS/L4D), 3=Force Center Text
sm_healthdisplay_hud = 0;
*
* Adds a delay, in seconds, for the menu. This means the menu will be showen after X seconds after the player spawned.
* Possible range of seconds is: 0.0 and above.
sm_healthdisplay_menu_pre_delay = 2.0;
*
* This saves the player decision if he wants to display the health of others or not.
* Possible settings are: false=players decisions will not be saved, true=players decisions will be saved.
sm_healthdisplay_save_player_setting = true;
* 
* This forces the players to have Health Display on. No menu will be showed unless the player tiggers the menu via chat comamnd: '/hpmenu'.
* Possible settings are : false=players will be asked to enable disable Health Display. true=players will not be asked.
sm_healthdisplay_force_player_on = false;
* 
* 
*********************************************
* With the following console variables you can change what the display should show:
*********************************************
* 
* Possible settings are: true=Show enemy players, false=Hide enemy players.
sm_healthdisplay_show_enemyplayers = true;
*
* Possible settings are: true=Show friendly players, false=Hide friendly players.
sm_healthdisplay_show_teammates = false;
*
* Possible settings are: true=Show NPCs (Non Player Character), false=Hide NPCs (Non Player Character).
sm_healthdisplay_show_npcs = true;
*
* 
*********************************************
* Changelog:
*********************************************
* v2.11.45 - Fixed: Issues showing players dead, when healed.
*
* v2.11.44 - Fixed: [L4D(2)] Issues with [L4D & L4D2] MultiTanks (version 1.5).
*
* v2.11.43 - Fixed: [L4D(2)] Tanks showing "(DEAD)", even when alive or just spawned.
*
* v2.10.41 - Added: Temp health in L4D to the normal health. Thank you DieTeetasse I used your code from an snippet.
* 
* v2.9.40 - Added: 3 new settings/cvars: sm_healthdisplay_menu_pre_delay, sm_healthdisplay_save_player_setting, sm_healthdisplay_force_player_on.
*         - Fixed: Some problems with the menu and hintbox (the example was overwritten).
* 
* v2.6.34 - Fixed: When the player decided to show Health Display then he won't be asked again unless he entered the trigger in to chat or console.
*         - Fixed: When "sm_healthdisplay_show_enemyplayers" is "false" the team mates health won't be showen, even when "sm_healthdisplay_show_teammates" is set to "true".
*         - Removed: sm_healthdisplay_show_entities within all config files (post & zip-file).
* 
* v2.6.30 - Added: Force Center Text option for sm_healthdisplay_hud, its 3.
* 
* v2.5.28 - Fixed: Doesn't show health trough invisible walls.
*         - Removed: sm_healthdisplay_show_entities, since it's useless.
*         - Fixed: sm_healthdisplay_show_npcs did the wrong thing.
* 
* v2.5.25 - Renamed this plugin from Show NPC HP into Show Health (this includes all cvars aswell).
*         - Fixed: [L4D2] Tank health wrong when it dies.
*         - Added: Config extension (sfPlayer) support. (new config file is at addons/sourcemod/configs/healthdisplay.conf)
*         - Added: m_healthdisplay_show_enemyplayers, m_healthdisplay_show_teammates, m_healthdisplay_show_npcs, m_healthdisplay_show_entities
* 
* v1.3.13 - Fixed: A small bug with the HudMessages.
* 
* v1.3.12 - Added: Support for L4D2 and other games.
*         - Added: Automated usage of ShowHudText or PrintHintText last is prefered by this plugin
*         - Added: Relationship Suppot, this means you can see if a NPC or Player is Friend or Foe.
* 
* v1.1.2  - First char in name is now upper case
* 
* v1.1.1  - Small bugfix for player health
* 
* v1.1.0  - First Public Release
* 
* 
* Thank you Berni, Manni, Mannis FUN House Community and SourceMod/AlliedModders-Team
* Thank you DieTeetasse for the L4D temp health snippet.
* 
* *************************************************/

/****************************************************************
P R E C O M P I L E R   D E F I N I T I O N S
*****************************************************************/

// enforce semicolons after each code statement
#pragma semicolon 1

/****************************************************************
I N C L U D E S
*****************************************************************/

#include <sourcemod>
#include <sdktools>
#include <config>
#include <clientprefs>

/****************************************************************
P L U G I N   C O N S T A N T S
*****************************************************************/

#define PLUGIN_VERSION 				"2.11.45"
#define HUD_INTERVALL 				0.01

#define MAX_SHOWSTRING_LENGTH 		128
#define MAX_RELATIONSHIP_LENGTH 	64
#define MAX_HEALTH_LENGTH 			32
#define MAX_CLASSNAME_LENGTH		32
#define MAX_ENTITIES 				2048

#define MAX_HEALTH_VALUE			999999999

#define TRACE_FILTER				(MASK_SHOT)

#define HINTBOX_BLANK				"."

#define REPORT_DEAD 				"DEAD"
#define RELATIONSHIP_NONE 			"None"
#define RELATIONSHIP_ENEMY 			"Enemy"
#define RELATIONSHIP_FRIEND 		"Friend"
#define RELATIONSHIP_NEUTRAL 		"Neutral"
#define UNKNOWN						"Unknown"

/*****************************************************************
P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = 
{
	name = "Health Display",
	author = "Chanz",
	description = "Shows the Health Points of Players, NPCs and other entities with health (ex. bearkables)",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu / https://forums.alliedmods.net/showthread.php?p=1108211"
}

/*****************************************************************
G L O B A L   V A R S
*****************************************************************/
//convars
new Handle:g_cvar_version 			= INVALID_HANDLE;
new Handle:g_cvar_enable 			= INVALID_HANDLE;
new Handle:g_cvar_show_teammates	= INVALID_HANDLE;
new Handle:g_cvar_show_enemyplayers	= INVALID_HANDLE;
new Handle:g_cvar_show_npcs			= INVALID_HANDLE;
new Handle:g_cvar_hud				= INVALID_HANDLE;
new Handle:g_cvar_menu_delay		= INVALID_HANDLE;
new Handle:g_cvar_save_player		= INVALID_HANDLE;
new Handle:g_cvar_force_player_on	= INVALID_HANDLE;
new Handle:g_cvar_PainPillsDecayRate = INVALID_HANDLE;

//convar runtime saver
new Float:g_fPainPillsDecayRate;

new Handle:g_hEntity_ClassName			= INVALID_HANDLE;
new Handle:g_hEntity_Name				= INVALID_HANDLE;
new Handle:g_hEntity_Exclude 			= INVALID_HANDLE;
new Handle:g_hEntity_Include 			= INVALID_HANDLE;
new Handle:g_hEntity_RemoveFromName 	= INVALID_HANDLE;
new Handle:g_hModel_Include				= INVALID_HANDLE;

new g_iOldHealth[MAX_ENTITIES] = {MAX_HEALTH_VALUE,...};
new g_iIsGhostOffset = -1;
new g_iOffsetHealthBuffer = -1;
new g_iOffsetHealthBufferTime = -1;
new bool:g_bClearedDisplay[MAXPLAYERS+1] = {false,...};
new bool:g_bHookedTankSpawn = false;
new bool:g_bDontOverRideHealthDisplay[MAXPLAYERS+1] = false;
new Float:g_iUpdateHintTimeout[MAXPLAYERS+1];
new String:g_szOldShowString[MAXPLAYERS+1][MAX_SHOWSTRING_LENGTH];


//Client Settings:
new Handle:cookie_Enable						= INVALID_HANDLE;
new Handle:cookie_AskedForEnable				= INVALID_HANDLE;

new bool:g_bAskedForEnable[MAXPLAYERS+1] = {false,...};
new bool:g_bClientShowDisplay[MAXPLAYERS+1] = {true,...};
/*****************************************************************
F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart(){
	
	//Cvars:
	g_cvar_version = CreateConVar("sm_healthdisplay_version", PLUGIN_VERSION, "Health Display Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_enable = CreateConVar("sm_healthdisplay_enable", "1", "0=Disable Show NPC HP, 1=Enable Show NPC HP)", FCVAR_PLUGIN);
	g_cvar_show_teammates = CreateConVar("sm_healthdisplay_show_teammates", "1", "", FCVAR_PLUGIN);
	g_cvar_show_enemyplayers = CreateConVar("sm_healthdisplay_show_enemyplayers", "1", "", FCVAR_PLUGIN);
	g_cvar_show_npcs = CreateConVar("sm_healthdisplay_show_npcs", "0", "", FCVAR_PLUGIN);
	g_cvar_hud = CreateConVar("sm_healthdisplay_hud", "0", "Where do you want to display the health info: 0=Choose Automaticly, 1=Force Hud Text (HL2DM/SourceForts), 2=Force Hint Text (CSS/L4D), 3=Force Center Text", FCVAR_PLUGIN);
	g_cvar_menu_delay = CreateConVar("sm_healthdisplay_menu_pre_delay", "2.0", "Adds a delay for the menu. This means the menu will be showen after X seconds after the player spawned.", FCVAR_PLUGIN);
	g_cvar_save_player = CreateConVar("sm_healthdisplay_save_player_setting", "1", "This saves the player decision if he wants to display the health of others or not.", FCVAR_PLUGIN);
	g_cvar_force_player_on = CreateConVar("sm_healthdisplay_force_player_on", "0", "This forces the players to have Health Display on. No menu will be showed unless the player tiggers the menu via chat comamnd: '/hpmenu'.", FCVAR_PLUGIN);
	g_cvar_PainPillsDecayRate = FindConVar("pain_pills_decay_rate");
	
	//Runtime saver:
	if(g_cvar_PainPillsDecayRate != INVALID_HANDLE){
		g_fPainPillsDecayRate = GetConVarFloat(g_cvar_PainPillsDecayRate);
	}
	
	//Hooks:
	HookEventEx("player_spawn", Event_Spawn);
	g_bHookedTankSpawn = HookEventEx("tank_spawn", Event_Tank_Spawn);
	
	//Find offsets:
	g_iIsGhostOffset = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	g_iOffsetHealthBuffer = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	g_iOffsetHealthBufferTime = FindSendPropInfo("CTerrorPlayer","m_healthBufferTime");
	//PrintToServer("m_isGhost offset: %d",g_iIsGhostOffset);
	
	//Reg Client Commands:
	RegConsoleCmd("hpmenu",			Command_AsktoDisable);
	RegConsoleCmd("health",			Command_AsktoDisable);
	RegConsoleCmd("healthmenu",		Command_AsktoDisable);
	RegConsoleCmd("healthdisplay",	Command_AsktoDisable);
	
	//Reg Admin Commands:
	RegAdminCmd("sm_debug",Command_Debug,ADMFLAG_ROOT);
	
	//Start Timers:
	CreateTimer(HUD_INTERVALL, Timer_DisplayHud, 0, TIMER_REPEAT);
	
	//RegCookie:
	cookie_Enable = RegClientCookie("HealthDisplay-Enable","HealthDisplay Enable cookie",CookieAccess_Private);
	cookie_AskedForEnable = RegClientCookie("HealthDisplay-AskedForEnable","HealthDisplay AskedForEnable cookie",CookieAccess_Private);
	
	//Init Arrays:
	g_hEntity_ClassName = CreateArray(MAX_CLASSNAME_LENGTH);
	g_hEntity_Name = CreateArray(MAX_CLASSNAME_LENGTH);
	g_hEntity_Exclude = CreateArray(MAX_CLASSNAME_LENGTH);
	g_hEntity_Include = CreateArray(MAX_CLASSNAME_LENGTH);
	g_hEntity_RemoveFromName = CreateArray(MAX_CLASSNAME_LENGTH);
	g_hModel_Include = CreateArray(PLATFORM_MAX_PATH);
}

public Action:Command_Debug(client, args){
	
	new Float:pos[3];
	new entity = GetClientAimHullTarget(client,pos);
	
	PrintToChat(client, "[Health Display] Entity %d - pos: %fx, %fy, %fz",entity,pos[0],pos[1],pos[2]);
	
	if((entity != -1) && IsValidEdict(entity) && (g_iIsGhostOffset != -1) && GetEntData(entity, g_iIsGhostOffset, 1)){
		
		PrintToChat(client,"[Health Display] A ghost, you saw it! (value: %d)",GetEntData(entity, g_iIsGhostOffset, 1));
	}
	
	/*new String:arg1[64];
	GetCmdArg(1,arg1,sizeof(arg1));
	
	SetClientCookie(client,cookie_AskedForEnable,arg1);
	
	LoadClientCookies(client);*/
	
	return Plugin_Handled;
}

ConfigArrayToStringAdt(Handle:Setting, Handle:adtArray) {
	
	decl String:buffer[PLATFORM_MAX_PATH];
	new length = ConfigSettingLength(Setting);
	
	for (new i=0; i<length; i++) {
		ConfigSettingGetStringElement(Setting, i, buffer, sizeof(buffer));
		PushArrayString(adtArray, buffer);
		//PrintToServer("Debug: %s", buffer);
	}
}

public OnMapStart(){
	
	// hax against valvefail (thx psychonic for fix)
	if(GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE){
		SetConVarString(g_cvar_version, PLUGIN_VERSION);
	}
	
	ClearArray(g_hEntity_ClassName);
	ClearArray(g_hEntity_Name);
	ClearArray(g_hEntity_Exclude);
	ClearArray(g_hEntity_Include);
	ClearArray(g_hEntity_RemoveFromName);
	ClearArray(g_hModel_Include);
	
	if(GetExtensionFileStatus("config.ext") != 1){
		
		SetFailState("Extension 'config.ext' isn't loaded! Get it from here: https://forums.alliedmods.net/showthread.php?t=69167 if you got already the extension then ask for help in the sourcemod forum!");
	}
	
	new String:configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/healthdisplay.conf");
	
	new line;
	new String:errorMsg[PLATFORM_MAX_PATH];
	new Handle:config = ConfigCreate();
	
	if (!ConfigReadFile(config, configPath, errorMsg, sizeof(errorMsg), line)) {
		
		SetFailState("Can't read config file %s: %s @ line %d", configPath, errorMsg, line);
	}
	
	SetConVarBool(g_cvar_enable,ConfigLookupBool(config, "sm_healthdisplay_enable"));
	if(!GetConVarBool(g_cvar_enable)){ SetConVarBool(g_cvar_enable,bool:ConfigLookupInt(config, "sm_healthdisplay_enable"));}
	
	SetConVarBool(g_cvar_show_teammates,ConfigLookupBool(config, "sm_healthdisplay_show_teammates"));
	if(!GetConVarBool(g_cvar_show_teammates)){ SetConVarBool(g_cvar_show_teammates,bool:ConfigLookupInt(config, "sm_healthdisplay_show_teammates"));}
	
	SetConVarBool(g_cvar_show_enemyplayers,ConfigLookupBool(config, "sm_healthdisplay_show_enemyplayers"));
	if(!GetConVarBool(g_cvar_show_enemyplayers)){ SetConVarBool(g_cvar_show_enemyplayers,bool:ConfigLookupInt(config, "sm_healthdisplay_show_enemyplayers"));}
	
	SetConVarBool(g_cvar_show_npcs,ConfigLookupBool(config, "sm_healthdisplay_show_npcs"));
	if(!GetConVarBool(g_cvar_show_npcs)){ SetConVarBool(g_cvar_show_npcs,bool:ConfigLookupInt(config, "sm_healthdisplay_show_npcs"));}
	
	SetConVarInt(g_cvar_hud,ConfigLookupInt(config, "sm_healthdisplay_hud"));
	
	SetConVarFloat(g_cvar_menu_delay,ConfigLookupFloat(config, "sm_healthdisplay_menu_pre_delay"));
	
	SetConVarBool(g_cvar_save_player,ConfigLookupBool(config, "sm_healthdisplay_save_player_setting"));
	if(!GetConVarBool(g_cvar_save_player)){ SetConVarBool(g_cvar_save_player,bool:ConfigLookupInt(config, "sm_healthdisplay_save_player_setting"));}
	
	SetConVarBool(g_cvar_force_player_on,ConfigLookupBool(config, "sm_healthdisplay_force_player_on"));
	if(!GetConVarBool(g_cvar_force_player_on)){ SetConVarBool(g_cvar_force_player_on,bool:ConfigLookupInt(config, "sm_healthdisplay_force_player_on"));}
	
	
	new Handle:setting = ConfigLookup(config, "entity_exclude");
	ConfigArrayToStringAdt(setting,g_hEntity_Exclude);
	
	setting = ConfigLookup(config, "entity_include");
	ConfigArrayToStringAdt(setting,g_hEntity_Include);
	
	setting = ConfigLookup(config, "entity_removefromname");
	ConfigArrayToStringAdt(setting,g_hEntity_RemoveFromName);
	
	setting = ConfigLookup(config, "model_include");
	ConfigArrayToStringAdt(setting,g_hModel_Include);
	
	CloseHandle(config);
	
	/*new MaxEntities = GetEntityCount();
	new String:classname[64];
	
	for(new entity=MaxClients;entity<MaxEntities;entity++){
	
	if(IsValidEdict(entity)){
	
	GetEdictClassname(entity,classname,sizeof(classname));
	
	//if(StrContains(classname,"ragdoll",false) != -1){
	
	LogMessage("entity: %d is an %s",entity,classname);
	//}
	}
	}*/
}

public Action:Command_AsktoDisable(client, args) {
	
	AskToDisableMenu(client);
	return Plugin_Handled;
}

public OnConfigsExecuted(){
	
	SetConVarString(g_cvar_version, PLUGIN_VERSION);	
}

public OnClientConnected(client){
	
	g_bClientShowDisplay[client] = true;
	g_bAskedForEnable[client] = false;
	g_bClearedDisplay[client] = false;
	g_iUpdateHintTimeout[client] = GetGameTime();
	strcopy(g_szOldShowString[client],MAX_SHOWSTRING_LENGTH,"");
}

bool:LoadClientCookies(client){	
	
	if(!AreClientCookiesCached(client)){
		return false;
	}
	
	g_bClientShowDisplay[client] = LoadCookieBool(client,cookie_Enable,false);
	
	if(GetConVarBool(g_cvar_save_player)){
		g_bAskedForEnable[client] = LoadCookieBool(client,cookie_AskedForEnable,false);
	}
	
	return true;
}

bool:LoadCookieBool(client,Handle:cookie,bool:defaultValue){
	
	new String:buffer[64];
	
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	if(!StrEqual(buffer, "")){
		//PrintToServer("[Health Display] Loaded cookie %d with value %d for %N",cookie,StringToInt(buffer),client);
		return bool:StringToInt(buffer);
	}
	
	return defaultValue;
}

public OnClientCookiesCached(client){
	
	if(!IsClientInGame(client) || IsFakeClient(client)){
		return;
	}
	
	if(!LoadClientCookies(client)){
		return;
	}
	
	if(g_bAskedForEnable[client]){
		return;
	}
	
	if(GetConVarBool(g_cvar_force_player_on)){
		//PrintToServer("[Health Display] force player on is true -> return");
		return;
	}
	
	//PrintToServer("[Health Display] Activated the menu via OnClientCookiesCached for %N, but with a delay of: %f seconds",client,GetConVarFloat(g_cvar_menu_delay));
	CreateTimer(GetConVarFloat(g_cvar_menu_delay),Timer_AskToDisableMenuDelay,client);
	
}

public Event_Spawn(Handle:event, const String:name[], bool:broadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGame(client) || IsFakeClient(client)){
		return;
	}
	
	if(!LoadClientCookies(client)){
		return;
	}
	
	if(g_bAskedForEnable[client]){
		return;
	}
	
	if(GetConVarBool(g_cvar_force_player_on)){
		//PrintToServer("[Health Display] force player on is true -> return");
		return;
	}
	
	//PrintToServer("[Health Display] Activated the menu via Event_Spawn for %N, but with a delay of: %f seconds",client,GetConVarFloat(g_cvar_menu_delay));
	CreateTimer(GetConVarFloat(g_cvar_menu_delay),Timer_AskToDisableMenuDelay,client);
}

public Action:Timer_AskToDisableMenuDelay(Handle:timer,any:client) {
	
	AskToDisableMenu(client);
	return Plugin_Continue;
}

public Event_Tank_Spawn(Handle:event, const String:name[], bool:broadcast) {
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_iOldHealth[client] = MAX_HEALTH_VALUE;
	
	//PrintToChatAll("A tank spawned with index: %d and HP: %d",client,g_iOldHealth[client]);
}

stock AskToDisableMenu(client){
	
	if (!GetConVarBool(g_cvar_enable)) {
		return;
	}
	
	g_bDontOverRideHealthDisplay[client] = true;
	
	switch(GetConVarInt(g_cvar_hud)){
		
		case 0:{
			
			SetHudTextParams(0.000, 0.32, 5.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
			if(ShowHudText(client, -1, "Please select HealthDisplay\nNPCのHP表示のONOFFを選択して下さい") == -1){
				PrintHintText(client,"Please select HealthDisplay\nNPCのHP表示のONOFFを選択して下さい");
			}
		}
		case 3:{
			
			PrintCenterText(client,"Please select HealthDisplay\nNPCのHP表示のONOFFを選択して下さい");
		}
		case 2:{
			
			PrintHintText(client,"Please select HealthDisplay\nNPCのHP表示のONOFFを選択して下さい");
		}
		case 1:{
			
			SetHudTextParams(0.000, 0.32, 5.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
			ShowHudText(client, -1, "Please select HealthDisplay\nNPCのHP表示のONOFFを選択して下さい");
		}
	}
	
	new Handle:menu = CreateMenu(HandleMenu);
	new String:display[32];
	
	SetMenuTitle(menu, "Enable the Health Display?\nNPCのHP表示をONにしますか？\nTo disable it type \n'/hpmenu' (without '')\ninto chat!\nNPCのHP表示切り替えはチャットで\n!hpmenuと打って下さい");
	
	
	strcopy(display,sizeof(display),"Yes");
	AddMenuItem(menu, "1",  display);
	
	strcopy(display,sizeof(display),"No");
	AddMenuItem(menu, "2",  display);
	
	
	DisplayMenu(menu, client, 15);
}

public HandleMenu(Handle:menu, MenuAction:action, client, param) {
	
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select) {
		
		decl String:info[64];
		new bool:found = GetMenuItem(menu, param, info, sizeof(info));
		
		if(found){
			
			switch(StringToInt(info)){
				
				//MainMenu:
				case 1:{
					g_bClientShowDisplay[client] = true;
					SetClientCookie(client,cookie_Enable,"1");
				}
				case 2:{
					g_bClientShowDisplay[client] = false;
					SetClientCookie(client,cookie_Enable,"0");
					
					switch(GetConVarInt(g_cvar_hud)){
						
						case 0:{
							
							SetHudTextParams(0.000, 0.32, 5.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
							if(ShowHudText(client, -1, "Health Display Disabled!\nHP表示をOFFにしました") == -1){
								PrintHintText(client,"Health Display Disabled!\nHP表示をOFFにしました");
							}
						}
						case 3:{
							
							PrintCenterText(client,"Health Display Disabled!\nHP表示をOFFにしました");
						}
						case 2:{
							
							PrintHintText(client,"Health Display Disabled!\nHP表示をOFFにしました");
						}
						case 1:{
							
							SetHudTextParams(0.000, 0.32, 5.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
							ShowHudText(client, -1, "Health Display Disabled!\nHP表示をOFFにしました");
						}
					}
				}
			}
			
			if(GetConVarBool(g_cvar_save_player)){
				SetClientCookie(client,cookie_AskedForEnable,"1");
				g_bAskedForEnable[client] = true;
			}
			
			g_bDontOverRideHealthDisplay[client] = false;
		}
	}
	else if (action == MenuAction_Cancel){
		
		g_bDontOverRideHealthDisplay[client] = false;
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}	

GetClientAimTargetPos(client, Float:pos[3]) {
	
	if(client < 1) {
		return;
	}
	
	decl Float:vAngles[3], Float:vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, TRACE_FILTER, RayType_Infinite, TraceFilterAllEntities);
	
	TR_GetEndPosition(pos, trace);
	
	CloseHandle(trace);
}

public bool:TraceFilterAllEntities(entity, contentsMask) {
	
	if(entity != 0){
		return false;
	}
	
	return true;
}

stock bool:GetEntityName(entity, String:name[]="", maxlen=MAX_CLASSNAME_LENGTH){
	
	if(IsPlayer(entity) && IsClientInGame(entity) && IsPlayerAlive(entity)){
		
		GetClientName(entity,name,maxlen);
		
		if(IsFakeClient(entity)){
			Format(name,maxlen,"(BOT) %s",name);
		}
		
		return true;
	}
	else if(IsValidEdict(entity)) {
		
		new size;
		new String:rule[PLATFORM_MAX_PATH+MAX_CLASSNAME_LENGTH];
		new String:modelPath[PLATFORM_MAX_PATH];
		new String:modelName[PLATFORM_MAX_PATH];
		
		Entity_GetModel(entity,modelPath,PLATFORM_MAX_PATH);
		
		if(!StrEqual(modelPath,"",false)){
			
			GetFileName(modelPath,modelName,PLATFORM_MAX_PATH);
			
			size = GetArraySize(g_hModel_Include);
			
			for(new i=0;i<size;i++){
				
				GetArrayString(g_hModel_Include,i,rule,PLATFORM_MAX_PATH);
				
				if(StrContains(modelName,rule,false) != -1){
					
					strcopy(name,maxlen,modelName);
					UpperFirstCharInString(name);
					return true;
				}
			}
		}
		
		new String:classname[MAX_CLASSNAME_LENGTH];
		GetEdictClassname(entity, classname, maxlen);
		
		new index = -1;
		if((index = FindStringInArray(g_hEntity_ClassName,classname)) != -1){
			
			GetArrayString(g_hEntity_Name,index,name,maxlen);
			//PrintToServer("Classname (%s) is already found name is: %s",classname,name);
			return true;
		}
		
		strcopy(name,maxlen,classname);
		
		size = GetArraySize(g_hEntity_Exclude);
		
		for(new i=0;i<size;i++){
			
			GetArrayString(g_hEntity_Exclude,i,rule,MAX_CLASSNAME_LENGTH);
			
			if(StrContains(name,rule,false) != -1){
				
				return false;
			}
		}
		
		size = GetArraySize(g_hEntity_Include);
		
		for(new i=0;i<size;i++){
			
			GetArrayString(g_hEntity_Include,i,rule,MAX_CLASSNAME_LENGTH);
			
			if(StrContains(name,rule,false) != -1){
				
				size = GetArraySize(g_hEntity_RemoveFromName);
				
				for(new j=0;j<size;j++){
					
					GetArrayString(g_hEntity_RemoveFromName,j,rule,MAX_CLASSNAME_LENGTH);
					
					ReplaceString(name,maxlen,rule,"",false);
				}
				
				UpperFirstCharInString(name);
				PushArrayString(g_hEntity_ClassName,classname);
				PushArrayString(g_hEntity_Name,name);
				//PrintToServer("Build out of classname: %s the name: %s and saved it.",classname,name);
				return true;
			}
		}
	}
	
	return false;
}


public bool:TraceEntityFilter(entity, contentsMask, any:client) {
	
	if(entity == client){
		return false;
	}
	
	if(IsPlayer(entity)){
		
		if((g_iIsGhostOffset != -1) && GetEntData(entity, g_iIsGhostOffset, 1)){
			
			//PrintToServer("[Health Display] A ghost, %N saw it!",client);
			return false;
		}
		
		if(!GetConVarBool(g_cvar_show_enemyplayers)){
			
			if(GetClientTeam(client) != GetClientTeam(entity)){
				
				return false;
			}
		}
		
		if(!GetConVarBool(g_cvar_show_teammates)){
			
			if(GetClientTeam(client) == GetClientTeam(entity)){
				
				return false;
			}
		}
	}
	else {
		
		if(IsNpc(entity)){
			
			if(!GetConVarBool(g_cvar_show_npcs)){
				
				return false;
			}
		}
		else {
			return true;
		}
	}
	
	return GetEntityName(entity);
}

bool:IsNpc(entity){
	
	if(IsValidEdict(entity)){
		
		decl String:classname[MAX_CLASSNAME_LENGTH];
		GetEdictClassname(entity,classname,sizeof(classname));
		
		if(StrContains(classname,"npc_",false) == 0){
			return true;
		}
	}
	
	return false;
}

GetClientAimHullTarget(client,Float:resultPos[3]) {
	
	//Hull trace calculation by berni all credits for this goes to him!
	
	decl Float:pos[3];
	GetClientAimTargetPos(client, pos);
	
	decl Float:vEyePosition[3];
	GetClientEyePosition(client, vEyePosition);
	
	decl Float:m_vecMins[3], Float:m_vecMaxs[3];
	//GetEntPropVector(entity, Prop_Send, "m_vecMins", m_vecMins);
	//GetEntPropVector(entity, Prop_Send, "m_vecMaxs", m_vecMaxs);
	m_vecMins[0] = m_vecMins[1] = m_vecMins[2] = 0.0;
	m_vecMaxs[0] = m_vecMaxs[1] = 1.0;
	m_vecMaxs[2] = 1.0;
	
	new Handle:trace = TR_TraceHullFilterEx(vEyePosition, pos, m_vecMins, m_vecMaxs, TRACE_FILTER,TraceEntityFilter,client);
	
	TR_GetEndPosition(resultPos, trace);
	
	if(TR_DidHit(trace)){
		
		new entity = TR_GetEntityIndex(trace);
		
		CloseHandle(trace);
		
		return entity;
	}
	
	CloseHandle(trace);
	
	return -1;
}

public Action:Timer_DisplayHud(Handle:timer) {
	
	decl Float:pos[3];
	
	for (new client=1; client<=MaxClients; ++client) {
		
		if(!g_bClientShowDisplay[client]){
			continue;
		}
		
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			
			new aimTarget = GetClientAimHullTarget(client, pos);
			
			ShowHPInfo(client, aimTarget);
		}
	}
	
	return Plugin_Continue;
}

public ShowHPInfo(client, target) {
	
	if (!GetConVarBool(g_cvar_enable)) {
		return;
	}
	
	if(g_bDontOverRideHealthDisplay[client]){
		return;
	}
	
	new String:targetname[MAX_TARGET_LENGTH];
	new bool:success = GetEntityName(target,targetname,sizeof(targetname));
	
	if(success){
		
		new String:health[MAX_HEALTH_LENGTH];
		GetEntityHealthString(target, health);
		
		new String:relationship[MAX_RELATIONSHIP_LENGTH] = RELATIONSHIP_NONE;
		GetEntityRelationship(client,target,relationship,sizeof(relationship));
		
		switch(GetConVarInt(g_cvar_hud)){
			
			case 0:{
				
				SetHudTextParams(0.000, 0.32, HUD_INTERVALL, 255, 255, 255, 255, 0, 6.0, 0.1 , 0.2);
				if(ShowHudText(client, -1, "%s(%s)",targetname,health) == -1){
					
					new String:showstring[MAX_SHOWSTRING_LENGTH];
					g_bClearedDisplay[client] = false;
					Format(showstring,MAX_SHOWSTRING_LENGTH,"%s(%s)",targetname,health);
					
					if(!StrEqual(showstring,g_szOldShowString[client],false) || ((GetGameTime() - g_iUpdateHintTimeout[client]) > 4.0)){
						
						PrintHintText(client,showstring);
						strcopy(g_szOldShowString[client],MAX_SHOWSTRING_LENGTH,showstring);
						g_iUpdateHintTimeout[client] = GetGameTime();
					}
				}
			}
			case 3:{
				
				PrintCenterText(client,"%s(%s)",targetname,health);
			}
			case 2:{
				
				new String:showstring[MAX_SHOWSTRING_LENGTH];
				g_bClearedDisplay[client] = false;
				Format(showstring,MAX_SHOWSTRING_LENGTH,"%s(%s)",targetname,health);
				
				if(!StrEqual(showstring,g_szOldShowString[client],false) || ((GetGameTime() - g_iUpdateHintTimeout[client]) > 4.0)){
					
					PrintHintText(client,showstring);
					strcopy(g_szOldShowString[client],MAX_SHOWSTRING_LENGTH,showstring);
					g_iUpdateHintTimeout[client] = GetGameTime();
				}
			}
			case 1:{
				
				SetHudTextParams(0.000, 0.32, HUD_INTERVALL, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
				ShowHudText(client, -1, "%s(%s)",targetname,health);
				//PrintToChat(client,"%s(%s)",targetname,health);
			}
			default: return;
		}
	}
	else if(!g_bClearedDisplay[client]) {
		
		g_bClearedDisplay[client] = true;
		
		switch(GetConVarInt(g_cvar_hud)){
			case 0:{
				
				if(ShowHudText(client, -1, " ") == -1){
					PrintHintText(client,HINTBOX_BLANK);
				}
			}
			case 1:{
				PrintHintText(client,HINTBOX_BLANK);
			}
		}
		
		strcopy(g_szOldShowString[client],sizeof(g_szOldShowString[]),HINTBOX_BLANK);
	}
}

stock UpperFirstCharInString(String:string[]){
	
	string[0] = CharToUpper(string[0]);
}

stock bool:IsPlayer(client) {
	
	if(!IsValidEdict(client)){
		return false;
	}
	
	if ((client < 1) || (MaxClients < client)) {
		return false;
	}
	
	return true;
}

stock GetEntityHealth(entity){
	
	new health = 0;
	
	if(IsPlayer(entity)){
		
		health = GetClientHealth(entity);
		
		new temphealth = 0;
		
		if((g_iOffsetHealthBuffer != -1) && (g_iOffsetHealthBufferTime != -1)){
			
			temphealth = RoundToCeil(GetEntDataFloat(entity, g_iOffsetHealthBuffer) - ((GetGameTime() - GetEntDataFloat(entity,g_iOffsetHealthBufferTime)) * g_fPainPillsDecayRate)) - 1;
			if (temphealth < 0) {
				temphealth = 0;
			}
		}
		
		health += temphealth;
		
		//Block l4d2 wrong tank death health value:
		if(g_bHookedTankSpawn){
			
			new String:targetname[MAX_TARGET_LENGTH];
			new bool:success = GetEntityNetClass(entity,targetname,sizeof(targetname));
			
			//PrintToChatAll("target: %s",targetname);
			
			if(success && (StrContains(targetname,"tank",false) != -1) && (g_iOldHealth[entity] < health)){
				health = 0;
			}
		}
	}
	else {
		
		health = GetEntProp(entity, Prop_Data, "m_iHealth", 1);
		
		if(health <= 1){
			health = 0;
		}
	}
	
	g_iOldHealth[entity] = health;
	return health;
}

stock GetEntityHealthString(entity,String:health[MAX_HEALTH_LENGTH]){
	
	new iHealth = GetEntityHealth(entity);
	
	if(iHealth < 1){
		
		if(IsPlayer(entity) || IsNpc(entity)){
			
			strcopy(health,MAX_HEALTH_LENGTH,REPORT_DEAD);
		}
		else {
			
			strcopy(health,MAX_HEALTH_LENGTH,"!!");
		}
	}
	else {
		Format(health,MAX_HEALTH_LENGTH,"%d HP",iHealth);
	}
	
	return iHealth;
}

stock GetEntityRelationship(client,entity,String:relationship[],maxlen){
	
	if(IsPlayer(entity)){
		
		new playerTeam=GetClientTeam(entity);
		new clientTeam=GetClientTeam(client);
		
		if(playerTeam == clientTeam){
			strcopy(relationship,maxlen,RELATIONSHIP_FRIEND);
		}
		else {
			strcopy(relationship,maxlen,RELATIONSHIP_ENEMY);
		}
	}
	else if(IsNpc(entity)) {
		
		strcopy(relationship,maxlen,UNKNOWN);
		
		//GetEntPropString(entity, Prop_Data, "m_RelationshipString", relationship, maxlen);
		//PrintToServer("Relship: %s",relationship);
	}
	else {
		
		strcopy(relationship,maxlen,RELATIONSHIP_NEUTRAL);
	}
	
	if(StrEqual(relationship,"",false)){
		strcopy(relationship,maxlen,RELATIONSHIP_NONE);
	}
}

stock GetFileName(String:path_or_file[],String:name[],maxlen,bool:stripExtension=true){
	
	new String:path[strlen(path_or_file)+1];
	strcopy(path,strlen(path_or_file)+1,path_or_file);
	
	new pos = FindCharInString(path, '/', true);
	
	if (pos == -1) {
		
		pos = 0;
	}
	else {
		pos++;
	}
	
	if(stripExtension && !StrEqual(path[pos],"",false)) {
		
		strcopy(name,maxlen,path[pos]);
		
		new String:extension[maxlen];
		GetFileExtension(path[pos],extension,maxlen,false);
		
		if(!StrEqual(extension,"",false)){
			
			ReplaceString(name,maxlen,extension,"",false);
		}
	}
}

stock Entity_GetModel(entity, String:buffer[], size) {
	
	GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, size);
}

stock GetFileExtension(String:path_or_file[],String:extension[],maxlen,bool:removeDot=true){
	
	new String:path[strlen(path_or_file)+1];
	strcopy(path,strlen(path_or_file)+1,path_or_file);
	
	new pos = FindCharInString(path, '.', true);
	
	if (pos == -1) {
		
		return;
	}
	else {
		
		if(removeDot){
			
			pos++;
		}
	}
	
	if(!StrEqual(path[pos],"",false)) {
		
		strcopy(extension,maxlen,path[pos]);
	}
}


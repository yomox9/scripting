#include <sourcemod>
//#include <smlib>
//#include <smlib/games/nmrih>
#include <sdktools>
#include <sdkhooks>
//						White			Red			Orange			Yellow			Green
new g_Colors[5][3] = {	{255,255,255},	{255,0,0},	{255,128,0},	{255,255,0},	{0,255,0}};

public Plugin:myinfo = {
	name = "Chinese Objective",
	author = "Tast - SDC",
	description = "NMRiH Test",
	version = "1.2",
	url = "http://tast.xclub.tw/viewthread.php?tid=115"
};

new extraction_begin_available = 0

new String:MapName[64]
new String:ObjCfgPath[PLATFORM_MAX_PATH];

public OnPluginStart(){
	GetCurrentMap(MapName, sizeof(MapName));
	BuildPath(Path_SM, ObjCfgPath, sizeof(ObjCfgPath), "/configs/Cross_Objective.cfg");
	//-----------------------------------------------------------------------
	//任務中文指標
	//HookEvent("objective_complete", Event_ServerMessage2,EventHookMode_Pre );
	RegAdminCmd("nmrih_obj", Command_objective, ADMFLAG_ROOT);
	RegConsoleCmd("obj", Command_objective2, "顯示當前任務");
	//HookEvent("extraction_complete", Event_Extraction_Complete,EventHookMode_Pre);
	//HookEvent("extraction_expire", Event_Extraction_Expire,EventHookMode_Pre);
	HookEvent("extraction_begin", Event_Extraction_Begin,EventHookMode_Pre);
	HookEvent("state_change", state_change,EventHookMode_Pre);
}

new g_LastButtons[9];
#define IN_Compass		(1 << 28) //Objective button
public Action:OnPlayerRunCmd(client, &buttons, &impulsre, Float:vel[3], Float:angles[3], &weapon){
	//if(!GetUserFlagBits(client) && ADMFLAG_ROOT) return
	//if((!buttons && !impulsre)) return
	if ((buttons & IN_Compass) && (g_LastButtons[client] & ~IN_Compass)){
		//Command_objective2(client,1)
    }
	g_LastButtons[client] = buttons;
	
	if(buttons & IN_Compass) Command_objective2(client,1)
	
	/*
	for (new i = 0; i < 30; i++){
        new button = (1 << i);
        
        if(buttons & button){
			PrintToChat(client,"Buttons:%d:%d , impulsre:%d",i,buttons,impulsre)
        }
    }
	*/
}

public state_change(Handle:event, const String:name[], bool:dontBroadcast){
	//PrintToChatAll("%s:state%d , game_type%d",name,GetEventInt(event, "state"),GetEventInt(event, "game_type"))
	//game_type 0 = NMO ; 1 = NMS
	//state 2 Practice End Freeze
	//state 3 Round Start
	//state 5 All Extracted
	//state 6 freeze end?
	//state 8 Round End?
	
	new states = GetEventInt(event, "state")
	if(states == 2 || states == 3) extraction_begin_available = 1
	if(states == 5){
		ShowCustomObjectiveText("OnAllPlayersExtracted","",0,1)
		extraction_begin_available = 0
	}
	if(states == 6){
		ShowCustomObjectiveText("OnExtractionExpired","",0,1)
		extraction_begin_available = 0
	}
}

//==================================================================================================
//Common

public OnMapStart(){
	extraction_begin_available = 0
	GetCurrentMap(MapName, sizeof(MapName));
	
	new maxEntities = GetMaxEntities();
	for (new entity = 0; entity < maxEntities; entity++) {
		if(IsValidEntity(entity)){
			new String:ClassName[128]
			GetEntityClassname(entity, ClassName, sizeof(ClassName));
			if(StrContains(ClassName,"nmrih_objective_boundary",false) != -1){
				HookSingleEntityOutput(entity, "OnObjectiveBegin", OnObjectiveBegin, false);
			}
		}
	}
}

public OnEntityCreated(entity, const String:classname[]){
	if(StrContains(classname,"nmrih_objective_boundary",false) != -1){
		HookSingleEntityOutput(entity, "OnObjectiveBegin", OnObjectiveBegin, false);
	}
}

//==================================================================================================
//Objective Message
new OnAllPlayersExtracted = 0
public Event_Extraction_Complete(Handle:hEvent, const String:name[], bool:dontBroadcast){
	OnAllPlayersExtracted = 1
	ShowCustomObjectiveText("OnAllPlayersExtracted","",0,1)
}

public Event_Extraction_Expire(Handle:hEvent, const String:name[], bool:dontBroadcast){
	if(!OnAllPlayersExtracted) ShowCustomObjectiveText("OnExtractionExpired","",0,1)
}

public Event_Extraction_Begin(Handle:hEvent, const String:name[], bool:dontBroadcast){
	if(!extraction_begin_available) return
	ShowCustomObjectiveText("ExtractionBegin","",0,1)
	extraction_begin_available = 0
}

new String:ObjectiveNow[256]
public Action:Command_objective2(id, Args){
	new String:ObjectiveNowText[256]
	ShowCustomObjectiveText(ObjectiveNow,ObjectiveNowText,sizeof(ObjectiveNowText))
	if(!strlen(ObjectiveNowText) || StrEqual(ObjectiveNowText,"NoData",false)) Format(ObjectiveNowText,sizeof(ObjectiveNowText),"無任務提示")
	//PrintToChat(id,"C:%d",Args)
	PrintCenterText(id, ObjectiveNowText);
	PrintHintText(id, "任務：%s",ObjectiveNowText)
	if(!Args) PrintToChat(id,"\x04(All) 任務\x01：%s",ObjectiveNowText)
	SendDialogToOne(id, 0, "任務：%s",ObjectiveNowText)
}

public Action:Command_objective(id, Args){
	new String:Lists[1024]
	new count = 1
	new entity = -1
	PrintToConsole(id,"===================================================================")
	while((entity = Entity_FindByClassName(entity, "nmrih_objective_boundary")) != INVALID_ENT_REFERENCE){
		new String:Name[128],String:ObjectiveList[128]
		Entity_GetName(entity, Name, sizeof(Name));
		ShowCustomObjectiveText(Name,ObjectiveList,sizeof(ObjectiveList))
		Format(Lists,sizeof(Lists),"%s\n%d:%s",Lists,count,ObjectiveList)
		PrintToConsole(id,"#%d:%s - %s",count,Name,ObjectiveList)
		count++
	}
	PrintToConsole(id,"===================================================================")
}

public OnObjectiveBegin(const String:output[], caller, activator, Float:delay){
	new String:ClassName[128]
	Entity_GetName(activator, ClassName, sizeof(ClassName));
	//PrintToChatAll("ClassName:%s",ClassName)
	ShowCustomObjectiveText(ClassName)
}

public Event_ServerMessage2(Handle:hEvent, const String:name[], bool:dontBroadcast){
	new String:ServerMsg[512]
	GetEventString(hEvent, "name" , ServerMsg, sizeof(ServerMsg));
	if(GetEventInt(hEvent, "id") == 0) Format(ServerMsg,sizeof(ServerMsg),"start")
	ShowCustomObjectiveText(ServerMsg)
	
	for(new i=1; i <= 8; i++){
		if(IsClientInGame(i) && GetUserFlagBits(i) && ADMFLAG_ROOT){
			PrintToChat(i, "objective_complete:%d:%s",GetEventInt(hEvent, "id"),ServerMsg)
			PrintToServer( "objective_complete:%d:%s",GetEventInt(hEvent, "id"),ServerMsg)
		}
	}
}

stock ShowCustomObjectiveText(const String:MSG[] = "",String:CallBack[] = "",size = 0,IsCommon = 0){
	//PrintToChatAll("ShowOBJ:%s",MSG)
	if(!strlen(MSG)) return
	
	new String:ObjectiveMessage[512]
	new Handle:kv = CreateKeyValues("text");
	
	if (FileToKeyValues(kv, ObjCfgPath)){
		if(IsCommon) 	KvJumpToKey(kv, "Common",true)
		else 			KvJumpToKey(kv, MapName,true)
		//if(KvJumpToKey(kv, MapName)) return;
		//if(!KvJumpToKey(kv, MSG)) return;
		KvGetString(kv, MSG,ObjectiveMessage, sizeof(ObjectiveMessage),"NoData")
		
		if(size) strcopy(CallBack, size, ObjectiveMessage);
		
		if(StrEqual(ObjectiveMessage,"NoData")){
			//PrintToChatAll("ShowOBJ (NoData):%s by %s",MSG,MapName)
			KvSetString(kv, MSG, "NoData");
			//KvGotoFirstSubKey(kv,true);
			KvRewind(kv);
			KeyValuesToFile(kv, ObjCfgPath)
		}
		else if(strlen(ObjectiveMessage) && !size){
			strcopy(ObjectiveNow,sizeof(ObjectiveNow),MSG)
			DisplayCenterTextToAll(ObjectiveMessage)
			PrintHintTextAll(ObjectiveMessage)
			PrintToChatAll("\x04(All) 任務\x01：%s",ObjectiveMessage)
			SendDialogToAll(ObjectiveMessage)
		}
	}
	CloseHandle(kv);
}

//==================================================================================================
//Stock
DisplayCenterTextToAll(String:message[]){
	for (new i = 1; i <= 8; i++){
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		PrintCenterText(i, "%s", message);
	}
}
PrintHintTextAll(String:message[]){
	new String:message2[256]
	Format(message2,strlen(message)+10,"任務：%s",message)
	for (new i = 1; i <= 8; i++){
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		PrintHintText(i, message2);
	}
}
SendDialogToAll(String:ObjectiveMessage[]){
	new String:ObjectiveMessage2[256]
	Format(ObjectiveMessage2,strlen(ObjectiveMessage)+10,"任務：%s",ObjectiveMessage)
	for (new i = 1; i <= 8; i++){
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		SendDialogToOne(i,0, ObjectiveMessage2);
	}
}
SendDialogToOne(client, color2, String:text[], any:...){
	//new color = RoundToFloor(color2 /255 *100 / 20.0) - 1
	if(color2 > 100) color2 = 100
	new color = RoundToFloor(color2 / 20.0) - 1
	if(color < 0) color = 0
	if(color > 4){
		PrintToServer("Health:%d,%d",Entity_GetHealth(client),color)
		return
	}
	new String:message[100];
	VFormat(message, sizeof(message), text, 4);	
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", g_Colors[color][0], g_Colors[color][1], g_Colors[color][2], 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 1);
	CreateDialog(client, kv, DialogType_Msg);
	CloseHandle(kv);
}
//=======================================================================================================
//SMLIB
stock Entity_FindByClassName(startEntity, const String:className[])
{
	return FindEntityByClassname(startEntity, className);
}
stock Entity_GetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}
stock Entity_GetHealth(entity)
{	
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Keypad Controller",
	author = "Tast - SDC",
	description = "Show input Password keypad",
	version = "1.1",
	url = "http://tast.xclub.tw/viewthread.php?tid=117"
};

new sdn_showpass = 1
new sdn_allpass = 0
new sdn_cospass = 1

new Handle:TirePad
new String:MapName[64]
new String:MapCfgPath[PLATFORM_MAX_PATH];

/*
01:23:33 find sm_dump
01:23:33 "sm_dumpentites"
         "sm_dump_netprops_xml"
          - Dumps the networkable property table as an XML file
         "sm_dump_netprops"
          - Dumps the networkable property table as a text file
         "sm_dump_classes"
          - Dumps the class list as a text file
         "sm_dump_datamaps"
          - Dumps the data map list as a text file
         "sm_dump_teprops"
          - Dumps tempentity props to a file
*/
public OnPluginStart(){
	HookConVarChange(	CreateConVar("sdn_showpass", 		"1",	"show password that player enter")		, Cvar_PassShow);
	HookConVarChange(	CreateConVar("sdn_allpass", 		"0",	"Random password can unlock")		, Cvar_AllPass);
	HookConVarChange(	CreateConVar("sdn_cospass", 		"1",	"Set password you wrote")		, Cvar_CosPass);
	
	HookEvent("keycode_enter", Event_Keycode_Enter,EventHookMode_Pre);
	
	RegAdminCmd("setcode", Command_SetCode, ADMFLAG_ROOT);
	RegAdminCmd("getcode", Command_GetCode, ADMFLAG_ROOT);
}

public Cvar_PassShow(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sdn_showpass = StringToInt(newValue); }
public Cvar_AllPass(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sdn_allpass = StringToInt(newValue); }
public Cvar_CosPass(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sdn_cospass = StringToInt(newValue); }

public Action:Command_GetCode(id, Args){
	PrintToChat(id,"Please enter the randomly to get code")
	SetTrieValue(TirePad, "GetKeyPadClient", id);
}

public Action:Command_SetCode(id, Args){
	PrintToChat(id,"Please enter the code to change this keypad")
	SetTrieValue(TirePad, "TempKeyPadClient", id);
}

public OnMapStart(){
	TirePad = CreateTrie();
	ClearTrie(TirePad);
	GetCurrentMap(MapName, sizeof(MapName));
	BuildPath(Path_SM, MapCfgPath, sizeof(MapCfgPath), "/configs/Key_Pad.cfg");
	/*
	new entity = -1
	while((entity = Entity_FindByClassName(entity, "trigger_keypad")) != INVALID_ENT_REFERENCE){
		HookSingleEntityOutput(entity, "OnIncorrectCode", OnIncorrectCode, false);
		HookSingleEntityOutput(entity, "OnTrigger", OnTrigger, false);
	}
	*/
}
/*
public OnEntityCreated(entity, const String:classname[]){
	if(StrContains(classname,"trigger_keypad") != -1){
		HookSingleEntityOutput(entity, "OnIncorrectCode", OnIncorrectCode, false);
		HookSingleEntityOutput(entity, "OnTrigger", OnTrigger, false);
	}
}
*/
stock SaveCode(const KeyPadID , const String:KeyPadCode[]){
	if(!IsValidEntity(KeyPadID) || !IsEntityKeyPad(KeyPadID) || strlen(KeyPadCode) < 4) return
	new Hammerid = Entity_GetHammerId(KeyPadID)
	new Handle:kv = CreateKeyValues("Code");
	new String:CodeName[16]
	IntToString(Hammerid, CodeName, sizeof(CodeName));
	
	FileToKeyValues(kv, MapCfgPath)
	KvJumpToKey(kv, MapName,true)
	KvSetString(kv, CodeName, KeyPadCode);
	KvRewind(kv);
	KeyValuesToFile(kv, MapCfgPath)
	
	CloseHandle(kv);
}

stock ReadCode(const KeyPadID , String:KeyPadCode[], const maxlength){
	if(!IsValidEntity(KeyPadID) || !IsEntityKeyPad(KeyPadID)) return
	new Hammerid = Entity_GetHammerId(KeyPadID)
	new Handle:kv = CreateKeyValues("Code");
	new String:CodeName[16]
	IntToString(Hammerid, CodeName, sizeof(CodeName));
	
	FileToKeyValues(kv, MapCfgPath)
	KvJumpToKey(kv, MapName,true)
	KvGetString(kv, CodeName, KeyPadCode, maxlength);
	
	CloseHandle(kv);
	
	return;
}
/*
stock EndCode(const KeyPadID , const String:Code[] = "", const Correct = -1,const client = -1){
	//PrintToChatAll("EndCode:%d",Correct)
	if(!sdn_showpass) return;
	new String:KeyPadName[16],String:KeyPadCode[16],String:KeyPadCorrect[16],String:KeyPadClient[16]
	Format(KeyPadName,		sizeof(KeyPadName)		,"KeyPad_%d",KeyPadID)
	Format(KeyPadCode,		sizeof(KeyPadCode)		,"KeyPad_%d_Code",KeyPadID)
	Format(KeyPadCorrect,	sizeof(KeyPadCorrect)	,"KeyPad_%d_Correct",KeyPadID)
	Format(KeyPadClient,	sizeof(KeyPadClient)	,"KeyPad_%d_Client",KeyPadID)
	
	if(KeyPadID)		SetTrieString(TirePad, KeyPadName, KeyPadName);
	if(strlen(Code)) 	SetTrieString(TirePad, KeyPadCode, Code);
	if(client != -1)	SetTrieValue(TirePad, KeyPadClient, client);
	if(StrEqual(Code,"NNNN",false)){
		RemoveFromTrie(TirePad,KeyPadName);
		RemoveFromTrie(TirePad,KeyPadCode);
		RemoveFromTrie(TirePad,KeyPadCorrect);
		RemoveFromTrie(TirePad,KeyPadClient);
		return
	}
	if(Correct != -1){
		new client2,String:Code2[16]
		SetTrieValue(TirePad, KeyPadCorrect, Correct);
		GetTrieValue(TirePad, KeyPadClient,client2);
		GetTrieString(TirePad, KeyPadCode, Code2, 16);
		
		if(sdn_allpass){
			//PrintToChatAll("\x04%N\x01Randomly enter the code for unlock\x04%s",client2,Code2)
		}
		else if(sdn_showpass == 2 && client2 != -1){
			PrintToChatAll("\x04%N\x01 enter the code \x04%s",client2,Code2)
		}
		else if(Correct == 1 && client2 != -1){
			PrintToChatAll("\x04%N\x01 Eter the correct password \x04%s",client2,Code2)
		}
		else if(Correct == 0 && client2 != -1){
			PrintToChatAll("\x04%N\x01 Enter the wrong password \x04%s",client2,Code2)
		}
		
		RemoveFromTrie(TirePad,KeyPadName);
		RemoveFromTrie(TirePad,KeyPadCode);
		RemoveFromTrie(TirePad,KeyPadCorrect);
		RemoveFromTrie(TirePad,KeyPadClient);
	}
}

public OnTrigger(const String:output[], caller, activator, Float:delay){
	EndCode(caller,"",1)
}

public OnIncorrectCode(const String:output[], caller, activator, Float:delay){
	if(!sdn_allpass) EndCode(caller,"",0)
}
*/
public Action:Command_Test(id, Args){
	PrintToConsole(id,"Searching for Ents")
	new count = 0
	new maxEntities = GetMaxEntities();
	for (new entity = 0; entity < maxEntities; entity++) {
		if(IsValidEntity(entity)){
			new String:ClassName[128]
			GetEntityClassname(entity, ClassName, sizeof(ClassName));
			if(StrContains(ClassName,"key") != -1){
				count++
				PrintToChat(id,"%d:%s",entity,ClassName)
			}
		}
	}
	if(!count) PrintToConsole(id,"No ents with")
}
//http://forums.alliedmods.net/showthread.php?t=156431
//https://forums.alliedmods.net/showthread.php?t=172874
/*
stock CreateCoder(){
	new ent = CreateEntityByName("logic_case");
	if(ent != -1){
		EntCoder = ent
		return true
	}
	return false
}

stock AcceptCoder(const KeyPadID,const String:Code[]){
	if(EntCoder == -1 ) return
	new String:OutPutStr[64],String:Name[64]
	Entity_GetName(KeyPadID, Name, sizeof(Name));
	Format(OutPutStr,sizeof(OutPutStr),"OnCase01 %s:InputSetCode:%s:0:-1",Name,Code)
	SetVariantString(OutPutStr);
	AcceptEntityInput(EntCoder, "AddOutput");
	DispatchSpawn(EntCoder);
	AcceptEntityInput(EntCoder, "PickRandom");
	//PrintToChatAll(OutPutStr)
}
*/
public Event_Keycode_Enter(Handle:event, const String:name[], bool:dontBroadcast){
	new String:Code[16],String:CodeString[16],String:KeyPadCode[5]
	new client = GetEventInt(event, "player")
	new KeyPad = GetEventInt(event, "keypad_idx")
	new NewClient = GetTrieValue2(TirePad,"TempKeyPadClient",-1)
	new GetClient = GetTrieValue2(TirePad,"GetKeyPadClient",-1)
	ReadCode(KeyPad , KeyPadCode, sizeof(KeyPadCode))
	GetEventString(event, "code", Code, sizeof(Code));
	GetEntPropString(KeyPad, Prop_Data, "m_pszCode", CodeString, sizeof(CodeString), 0);
	
	//PrintToChatAll("keypad_idx:%d , player:%d , code:%s",GetEventInt(event, "keypad_idx"),GetEventInt(event, "player"),Code)
	
	if(GetClient != -1 && GetClient == client){
		SetEventString(event, "code", "95271");
		PrintToChat(NewClient,"\x01 Correct password is：\x04%s",CodeString)
		RemoveFromTrie(TirePad,"GetKeyPadClient");
		return
	}
	if(NewClient != -1 && NewClient == client){
		SetEventString(event, "code", CodeString);
		SaveCode(KeyPad,Code)
		PrintToChat(NewClient,"\x01 Password has been changed to：\x04%s",Code)
		RemoveFromTrie(TirePad,"TempKeyPadClient");
		return
	}
	if(strlen(KeyPadCode) && sdn_cospass){
		//PrintToChatAll("keypad_idx:%d , player:%d , code:%s/%s from:%s",GetEventInt(event, "keypad_idx"),GetEventInt(event, "player"),Code,CodeString,KeyPadCode)
		if(StrEqual(Code,KeyPadCode) || (StrEqual(Code,"0000") && StrEqual(KeyPadCode,"0"))){
			SetEventString(event, "code", CodeString);
			if(sdn_showpass) PrintToChatAll("\x04%N\x01 Eter the correct password",client)
		}
		else {
			if(sdn_showpass) PrintToChatAll("\x04%N\x01 Enter the wrong password \x04%s",client,Code)
			SetEventString(event, "code", "95271");
		}
		return;
	}
	if(sdn_allpass == 1 || (sdn_allpass == 2 && GetUserFlagBits(client) && ADMFLAG_GENERIC) || (sdn_allpass == 3 && GetUserFlagBits(client) && ADMFLAG_ROOT)){
		SetEventString(event, "code", CodeString);
		if(sdn_showpass) PrintToChatAll("\x04%N\x01 Randomly enter the code for unlock \x04%s",client,Code)
		return
	}
	
	if(sdn_showpass){
		if(StrEqual(Code,CodeString))
				PrintToChatAll("\x04%N\x01 Eter the correct password\x04%s",client,CodeString)
		else 	PrintToChatAll("\x04%N\x01 Enter the wrong password\x04%s",client,Code)
	}
		
	//PrintToChatAll("\x04%N\x01 Eter the password\x04%s \x01%s",client,Code,CodeString)
}

stock bool:IsStringNumeric(const String:str[]){
	//http://pastebin.com/8ZeTjCkn
	new q = 0
	while(str[q] != '\0'){
		if(!IsCharNumeric(str[q])){
			//ReplyToCommand(client, "\x04[Calcy]\x03 Invalid Syntax (%c) in %s.", Numbers[q], Numbers);
			return false
		}
		q++;
	}
	return true
}

stock IsKeyPadEntered(const KeyPadID,const set = 0){
	new String:KeyPadName[16]
	Format(KeyPadName,		sizeof(KeyPadName)		,"KeyPad_%d_ED",KeyPadID)
	if(GetTrieValue2(TirePad, KeyPadName,0)) return true
	else if(set)	SetTrieValue(TirePad, KeyPadName, 1);
	return false
}

stock GetTrieValue2(Handle:trie, const String:key[],any:value2){
	new value
	if(!GetTrieValue(trie, key, value)) return value2
	return value
}

stock IsEntityKeyPad(ent){
	new String:ClassName[32]
	GetEntityClassname(ent, ClassName, sizeof(ClassName))
	if(StrEqual(ClassName, "trigger_keypad", false))
			return true
	return 	false
}

stock Entity_FindByClassName(startEntity, const String:className[]){
	return FindEntityByClassname(startEntity, className);
}

stock Entity_GetHammerId(entity)
{	
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}
stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_target", buffer, size);
}
stock Entity_GetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}
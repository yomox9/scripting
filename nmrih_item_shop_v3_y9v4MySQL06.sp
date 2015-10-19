#pragma semicolon 1
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#define PLUGIN_VERSION "2.0.0.8"

//각 종목별 아이템 개수
#define MELEE_MAX 14
#define PISTOL_MAX 5
#define RIFLE_MAX 10
#define SNIPER_MAX 3
#define SHOTGUN_MAX 4
#define EXPLOSIVE_MAX 3
#define TOOLS_MAX 10

public Plugin:myinfo =
{
	name = "[NMRiH]Item Shop V3 customized y9v4 forSrv06",
	author = "ys24ys & Mr.Halt.Modified yomox9",
	description = "Item Shop(Supported SQL)",
	version = PLUGIN_VERSION,
	url = "http://ys24ys.iptime.org/xpressengine/"
};

//무기이름, 상점에 출력될 이름, 가격, 무게(변경금지)
static String:Weapon_Melee[MELEE_MAX][4][64] = {
	{"me_kitknife", "Kit Knife(부엌칼)", "100", "50"},
	{"me_wrench", "Wrench(렌치)", "120", "80"},
	{"me_pipe_lead", "Lead Pipe(쇠파이프)", "150", "200"},
	{"me_crowbar", "Crowbar(쇠지레)", "150", "200"},
	{"me_bat_metal", "Baseball Bat(야구방망이)", "130", "200"},
	{"me_shovel", "Shovel(삽)", "130", "300"},
	{"me_etool", "E-Tool(야전삽)", "140", "200"},
	{"me_hatchet", "Hatchet(손도끼)", "150", "100"},
	{"me_machete", "Machete(정글도)", "150", "100"},
	{"me_sledge", "Sledgehammer(오함마)", "150", "400"},
	{"me_axe_fire", "Fire Axe(소방 도끼)", "150", "400"},
	{"me_fubar", "FUBAR(파괴망치)", "130", "450"},
	{"me_chainsaw", "Chainsaw(전기톱)", "1500", "600"},
	{"me_abrasivesaw", "Abrasive Saw(연마용톱)", "1200", "550"}
};

static String:Weapon_Pistol[PISTOL_MAX][4][64] = {
	{"fa_m92fs", "Berreta M92FS", "200", "100"},
	{"fa_glock17", "Glock", "200", "100"},
	{"fa_mkiii", "Ruger MKiii", "200", "100"},
	{"fa_1911", "Colt 1911", "200", "100"},
	{"fa_sw686", "S&W 686", "200", "150"}
};

static String:Weapon_Rifle[RIFLE_MAX][4][64] = {
	{"fa_mp5a3", "H&K MP5A3", "300", "300"},
	{"fa_mac10", "Mac-10", "300", "300"},
	{"fa_1022", "Ruger 10/22", "300", "250"},
	{"fa_1022_25mag", "Ruger 10/22 w/ BX25 Magazine", "400", "250"},
	{"fa_sks", "Simonov SKS", "300", "400"},
	{"fa_winchester1892", "Winchester 1892", "300", "300"},
	{"fa_m16a4", "FN M16A4", "500", "400"},
	{"fa_m16a4_carryhandle", "FN M16A4 w/ Carry Handle", "500", "400"},
	{"fa_cz858", "CZ858", "500", "400"},
	{"fa_fnfal", "FN FAL", "500", "450"}
};

static String:Weapon_Sniper[SNIPER_MAX][4][64] = {
	{"bow_deerhunter", "PSE Deer Hunter", "50", "150"},
	{"fa_sako85", "Sako 85", "300", "450"},
	{"fa_jae700", "JAE 700", "500", "450"}
};

static String:Weapon_Shotgun[SHOTGUN_MAX][4][64] = {
	{"fa_sv10", "Beretta Perennia SV10", "200", "350"},
	{"fa_500a", "Mossberg 500a", "300", "350"},
	{"fa_superx3", "Winchester Super X3", "300", "350"},
	{"fa_870", "Remington 870", "300", "350"}
};


static String:Weapon_Explosive[EXPLOSIVE_MAX][4][64] = {
	{"exp_grenade", "FlashGrenade(수류탄)", "50", "100"},
	{"exp_tnt", "TNT", "1000", "100"},
	{"exp_molotov", "Molotov(화염병)", "800", "100"}
};

static String:Weapon_Tools[TOOLS_MAX][4][64] = {
	{"item_bandages", "Bandages(붕대)", "300", "35"},
	{"item_first_aid", "First Aid Kit(응급치료킷)", "800", "85"},
	{"item_pills", "Pills(감염지연제)", "300", "35"},
	{"item_gene_therapy", "Gene Therapy(백신)", "1000", "35"},
	{"tool_flare_gun", "Flare Gun(신호탄총)", "3000", "50"},
	{"tool_barricade", "Barricade Hammer(장도리)", "150", "50"},
	{"item_maglite", "Maglite(손전등)", "300", "100"},
	{"tool_welder", "Welder(용접기)", "1000", "70"},
	{"tool_extinguisher", "Fire Extinguisher(소화기)", "500", "400"},
	{"item_walkietalkie", "Walkie Talkie(무전기)", "5", "0"}
};

new Handle:hDatabase = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_startcash = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_death = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_teamkill = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_killcash = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_killcash_head = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_killcash_fire = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_extracted = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_sell_ratio = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_price_respawn = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_price_respawn_other = INVALID_HANDLE;
new Handle:sm_nmrih_itemshop_sell_restriction = INVALID_HANDLE;

new ClientCash[MAXPLAYERS+1];
new ClientSellCounter[MAXPLAYERS+1];

new TotalPlayers;
new String:Top10RichName[10][64];
new Top10RichCash[10];
new Cash_Rank[MAXPLAYERS+1];
new Cash_Diff[MAXPLAYERS+1];
new RespawnStation[MAXPLAYERS+1];
new Float:LastDeathPosition[MAXPLAYERS+1][3];

public OnPluginStart()
{
	decl String:game[16];
	GetGameFolderName(game, sizeof(game));
	if(strcmp(game, "nmrih", false) != 0)
	{
		SetFailState("Unsupported game!");
	}

	LoadTranslations("nmrih_item_shop.phrases");

	sm_nmrih_itemshop_startcash = CreateConVar("sm_nmrih_itemshop_startcash", "500", "Give cash to first join players");
	sm_nmrih_itemshop_death = CreateConVar("sm_nmrih_itemshop_death", "10", "Gain cash when players are dead");
	sm_nmrih_itemshop_teamkill = CreateConVar("sm_nmrih_itemshop_teamkill", "10", "Gain cash when players killed the other players");
	sm_nmrih_itemshop_killcash = CreateConVar("sm_nmrih_itemshop_killcash", "1", "Give cash when players killed zombies");
	sm_nmrih_itemshop_killcash_head = CreateConVar("sm_nmrih_itemshop_killcash_head", "1", "Give cash when players killed zombies with headshot");
	sm_nmrih_itemshop_killcash_fire = CreateConVar("sm_nmrih_itemshop_killcash_fire", "1", "Give cash when players killed zombies with the fire");
	sm_nmrih_itemshop_extracted = CreateConVar("sm_nmrih_itemshop_extracted", "10", "Give cash when players escaped");
	sm_nmrih_itemshop_sell_ratio = CreateConVar("sm_nmrih_itemshop_sell_ratio", "0.1", "Sell items - Price of ratio of when sell items\n0.01 = 1%\n1.00 = 100%", FCVAR_PLUGIN, true, 0.01, true, 1.00);
	sm_nmrih_itemshop_price_respawn = CreateConVar("sm_nmrih_itemshop_price_respawn", "100", "Need cash when respawn");
	
	sm_nmrih_itemshop_price_respawn_other = CreateConVar("sm_nmrih_itemshop_price_respawn_other", "100", "Need cash when respawn");
	sm_nmrih_itemshop_sell_restriction = CreateConVar("sm_nmrih_itemshop_sell_restriction", "5", "Sell Restriction");
	
	AutoExecConfig(true, "nmrih_itemshop");
	
	RegConsoleCmd("sm_shop", ClientCommand_Shop, "Item shop");
	RegConsoleCmd("sm_cs", ClientCommand_Cash, "Confirmation of cache information");
	RegAdminCmd("sm_nmrih_itemshop_setcash", AdminCommand_SetPoint, ADMFLAG_RCON, "Set cash of target");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("npc_killed", Event_NPCKilled);
	HookEvent("zombie_killed_by_fire", Event_ZombieKilledByFire);
	HookEvent("zombie_head_split", Event_ZombieHeadSplit);
	HookEvent("player_extracted", Event_PlayerExtracted);
	
	CreateTimer(60.0, ClientFunction_RankRenewal, _, TIMER_REPEAT);
	
	ConnectDatabase();
}

public Action:AdminCommand_SetPoint(Client, Args)
{
	if(Args < 2)
	{
		ReplyToCommand(Client, "[SM] Usage: sm_nmrih_itemshop_setcash <cash> <#userid|name>");
		return Plugin_Handled;
	}
	
	decl String:pointsString[64], String:targetString[256];
	
	GetCmdArg(1, pointsString, sizeof(pointsString));
	new cash = StringToInt(pointsString);
	
	GetCmdArg(2, targetString, sizeof(targetString));
	decl targets[64], String:tn[MAX_TARGET_LENGTH], bool:tn_is_ml;
	new count = ProcessTargetString(targetString, Client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, tn, sizeof(tn), tn_is_ml);
	if(count < 1)
	{
		ReplyToTargetError(Client, count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < count; i++)
	{
		if(IsClientAuthorized(targets[i]))
		{
			ClientCash[targets[i]] = cash;
		}
	}
	
	return Plugin_Handled;
}

public ConnectDatabase()
{
	new String:db[] = "nmrih_itemshop";
	if(SQL_CheckConfig("nmrih_itemshop"))
	{
		db = "nmrih_itemshop";
	}
	decl String:error[256];
	hDatabase = SQL_Connect(db, true, error, sizeof(error));
	if(hDatabase == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	
	SQL_TQuery(hDatabase, T_FastQuery, "CREATE TABLE IF NOT EXISTS nmrih_itemshop06 (steam_id VARCHAR(64) PRIMARY KEY, name TEXT, cash INTEGER);");
}

public OnMapStart()
{
	for(new Client=1; Client<=MaxClients; Client++)
	{
		if(IsClientInGame(Client) && IsClientAuthorized(Client))
		{
			decl String:query[512], String:auth[64];
			GetClientAuthId(Client, AuthId_Steam2, auth, sizeof(auth));
			
			Format(query, sizeof(query), "SELECT name, cash FROM nmrih_itemshop06 WHERE steam_id = '%s' LIMIT 1;", auth);
			SQL_TQuery(hDatabase, T_LoadPlayer, query, Client);
		}
	}
}

public OnMapEnd()
{
	for(new Client=1; Client<=MaxClients; Client++)
	{
		if(IsClientInGame(Client) && IsClientAuthorized(Client))
		{
			Data_Save(Client);
		}
		
		LastDeathPosition[Client][0] = 0.0;
	}
}

public OnClientConnected(Client)
{
	ClientCash[Client] = -1;
}

public OnClientAuthorized(Client, const String:auth[])
{
	if(IsFakeClient(Client))
		return;
		
	ClientCash[Client] = -1;
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT name, cash FROM nmrih_itemshop06 WHERE steam_id = '%s' LIMIT 1;", auth);
	SQL_TQuery(hDatabase, T_LoadPlayer, query, Client);
}

public OnClientPutInServer(Client)
{
	CashRank(Client);
	CashRank_Top10(Client);
	
	CreateTimer(1.0, ClientFunction_PrintRank, Client);
}

public Action:ClientFunction_PrintRank(Handle:timer, any:Client)
{
	new String:name[32];
	GetClientName(Client, name, sizeof(name));
	CPrintToChatAll("[\x04ItemShop\x01] %t", "Welcome message", name, ClientCash[Client], Cash_Rank[Client], TotalPlayers);
}

public OnClientDisconnect(Client)
{
	Data_Save(Client);
	ClientCash[Client] = -1;
	RespawnStation[Client] = 0;
	LastDeathPosition[Client][0] = 0.0;
}

public Data_Save(Client)
{
	if(ClientCash[Client] != -1)
	{
		decl String:query[1024], String:authid[64];
		GetClientAuthId(Client, AuthId_Steam2, authid, sizeof(authid));
		Format(query, sizeof(query), "UPDATE nmrih_itemshop06 SET cash = %d WHERE steam_id = '%s';", ClientCash[Client], authid);
		SQL_TQuery(hDatabase, T_FastQuery, query);
	}
	else
	{
		PrintToServer("[NMRiH Item Shop] Player %N Cash Error. (Authorized Number INVALID)", Client);
	}
}

public T_LoadPlayer(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	if(IsFakeClient(Client)) return;

	if(hndl != INVALID_HANDLE)
	{
		decl String:authid[64], String:playername[64];
		GetClientAuthId(Client, AuthId_Steam2, authid, sizeof(authid));
		GetClientName(Client, playername, sizeof(playername));
		
		if(SQL_FetchRow(hndl))
		{
			decl String:dbname[64];
			SQL_FetchString(hndl, 0, dbname, sizeof(dbname));
			if(strcmp(playername, dbname) != 0)
			{
				UpdatePlayerName(authid, playername);
			}
			
			ClientCash[Client] = SQL_FetchInt(hndl, 1);
		}
		else
		{
			decl String:query[512], String:escname[129];
			SQL_EscapeString(hDatabase, playername, escname, sizeof(escname));
			new cash = GetConVarInt(sm_nmrih_itemshop_startcash);
			
			Format(query, sizeof(query), "INSERT INTO nmrih_itemshop06 VALUES ('%s', '%s', %d);", authid, escname, cash);
			SQL_TQuery(hDatabase, T_FastQuery, query);
			
			ClientCash[Client] = cash;
		}
	}
	else
	{
		ClientCash[Client] = -1;
		PrintToServer("[NMRiH Item Shop] Player %N Error - T_LoadPlayer - INVALID_HANDLE", Client);
	}
}

public T_FastQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// Nothing to do
}

public UpdatePlayerName(const String:authid[], const String:name[])
{
	decl String:query[1024], String:escname[129];
	SQL_EscapeString(hDatabase, name, escname, sizeof(escname));
	Format(query, sizeof(query), "UPDATE nmrih_itemshop06 SET name = '%s' WHERE steam_id = '%s';", escname, authid);
	SQL_TQuery(hDatabase, set_utf8, "SET NAMES UTF8;", 0);
	SQL_TQuery(hDatabase, T_FastQuery, query);
}

public set_utf8(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if (handle == INVALID_HANDLE) 
		LogError("Failed attempt to set the charset : %s", error);
}

public OnClientSayCommand_Post(Client, const String:command[], const String:sArgs[])
{
	decl String:text[192];
	new startidx = 0;
	
	if(strcopy(text, sizeof(text), sArgs) < 1)
	{
		return;
	}
	
	if(text[0] == '"')
	{
		startidx = 1;
	}

	if((strcmp(command, "say2", false) == 0) && strlen(sArgs) >= 4)
		startidx += 4;

	if((strcmp(text[startidx], "!상점", false) == 0) || (strcmp(text[startidx], "!샵", false) == 0) || (strcmp(text[startidx], "!store", false) == 0) || (strcmp(text[startidx], "/상점", false) == 0) || (strcmp(text[startidx], "/store", false) == 0) || (strcmp(text[startidx], "/샵", false) == 0))
	{
		FakeClientCommand(Client, "sm_shop");
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	GetClientAbsOrigin(Client, LastDeathPosition[Client]);
	
	new DeathCash = GetConVarInt(sm_nmrih_itemshop_death);
	if(ClientCash[Client]-DeathCash >= 0)
	{
		ClientCash[Client] -= DeathCash;
	}
	else
	{
		ClientCash[Client] = 0;
	}
	
	if(Client != Attacker)
	{
		new TKCash = GetConVarInt(sm_nmrih_itemshop_teamkill);
		if(Attacker > 0 && Attacker <= 8)
		{
			if(ClientCash[Attacker]-TKCash >= 0)
			{
				ClientCash[Attacker] -= TKCash;
			}
			else
			{
				ClientCash[Attacker] = 0;
			}
		}
	}
}

public Action:Event_NPCKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	//new Zombie = GetEventInt(event, "entidx");
	new Client = GetEventInt(event, "killeridx");
	
	if(Client <= -1 || Client > MaxClients)
		return;
	
	new KillCash = GetConVarInt(sm_nmrih_itemshop_killcash);
	ClientCash[Client] += KillCash;
}

public Action:Event_ZombieKilledByFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetEventInt(event, "igniter_id");
	//new Zombie = GetEventInt(event, "zombie_id");
	if(Client <= -1 || Client > MaxClients)
		return;
	
	new KillCash_Fire = GetConVarInt(sm_nmrih_itemshop_killcash_fire);
	ClientCash[Client] += KillCash_Fire;
}

public Action:Event_ZombieHeadSplit(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetEventInt(event, "player_id");
	
	new KillCash_Head = GetConVarInt(sm_nmrih_itemshop_killcash_head);
	ClientCash[Client] += KillCash_Head;
}

public Action:Event_PlayerExtracted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetEventInt(event, "player_id");
	
	new KillCash_Extracted = GetConVarInt(sm_nmrih_itemshop_extracted);
	ClientCash[Client] += KillCash_Extracted;
}

public Action:ClientFunction_RankRenewal(Handle:timer)
{
	for(new Client=1; Client<=8; Client++)
	{
		if(IsClientInGame(Client) && IsClientAuthorized(Client))
		{
			Data_Save(Client);
			CashRank(Client);
			CashRank_Top10(Client);
		}
	}
}

public Action:ClientCommand_Cash(Client, Args)
{	
	Cash_Menu(Client);
	return Plugin_Handled;
}

public CashRank(Client)
{
	if(Client == 0)
		return;
	
	SQL_TQuery(hDatabase, T_UpdateTotalQuery, "SELECT COUNT(*) FROM nmrih_itemshop06;");
	
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT cash FROM nmrih_itemshop06 WHERE cash > %d ORDER BY cash ASC;", ClientCash[Client]);
	SQL_TQuery(hDatabase, T_CashQuery, query, Client);
}

public T_UpdateTotalQuery(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	if(hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		TotalPlayers = SQL_FetchInt(hndl, 0);
	}
}

public T_CashQuery(Handle:owner, Handle:hndl, const String:error[], any:Client)
{
	if(hndl == INVALID_HANDLE || !IsClientInGame(Client))
		return;
	
	if(SQL_FetchRow(hndl))
	{
		Cash_Rank[Client] = SQL_GetRowCount(hndl) + 1;
		Cash_Diff[Client] = SQL_FetchInt(hndl, 0) - ClientCash[Client];
	}
	else
	{
		Cash_Rank[Client] = 1;
		Cash_Diff[Client] = 0;
	}
}

public CashRank_Top10(Client)
{
	SQL_TQuery(hDatabase, T_Top10Query, "SELECT name, cash FROM nmrih_itemshop06 ORDER BY cash DESC LIMIT 10;", Client);
}

public T_Top10Query(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(hndl == INVALID_HANDLE || !IsClientInGame(client))
		return;
	
	new i;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, Top10RichName[i], 64);
		Top10RichCash[i] = SQL_FetchInt(hndl, 1);
		i++;
	}
}

public Cash_Menu(Client)
{
	decl String:Title[128];
	decl String:Line1[256], String:Line2[256], String:Line3[128];
	
	Format(Title, sizeof(Title), "* * * Rich Rank * * *");
	Format(Line1, sizeof(Line1), "Top1. %s(%d)\nTop2. %s(%d)\nTop3. %s(%d)\nTop4. %s(%d)\nTop5. %s(%d)", Top10RichName[0], Top10RichCash[0], Top10RichName[1], Top10RichCash[1], Top10RichName[2], Top10RichCash[2], Top10RichName[3], Top10RichCash[3], Top10RichName[4], Top10RichCash[4]);
	Format(Line2, sizeof(Line2), "Top6. %s(%d)\nTop7. %s(%d)\nTop8. %s(%d)\nTop9. %s(%d)\nTop10. %s(%d)", Top10RichName[5], Top10RichCash[5], Top10RichName[6], Top10RichCash[6], Top10RichName[7], Top10RichCash[7], Top10RichName[8], Top10RichCash[8], Top10RichName[9], Top10RichCash[9]);
	Format(Line3, sizeof(Line3), "Your rank : %d/%d(%d cash for next ranking)", Cash_Rank[Client], TotalPlayers, Cash_Diff[Client]);
	
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, Title); // 타이틀
	DrawPanelText(hPanel, Line1);
	DrawPanelText(hPanel, Line2);
	DrawPanelText(hPanel, Line3);
	DrawPanelItem(hPanel, "Close");
	SendPanelToClient(hPanel, Client, Callback_Menu_Player_Class, 60);
}

public Callback_Menu_Player_Class(Handle:hHandle, MenuAction:action, param1, param2)
{
	new Handle:hPanel = CreatePanel();
	CloseHandle(hPanel);
}

public Action:ClientCommand_Shop(Client, Args)
{
	Shop_Menu_Main(Client);
	
	return Plugin_Handled;
}

public Shop_Menu_Main(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Main);
	new Sell_Ratio = RoundToCeil(GetConVarFloat(sm_nmrih_itemshop_sell_ratio) * 100.0);
	new sellmax = GetConVarInt(sm_nmrih_itemshop_sell_restriction);
	decl String:TitleFormat[256], String:ItemSell[128], String:MadeBy[128];
	Format(TitleFormat, 256, "◈Item Shop◈\nCash : %d", ClientCash[Client]);
	Format(ItemSell, 128, "Sell items(%d %% of original price)\n└You can sell items on your hand.(Counter=%d Max=%d)", Sell_Ratio, ClientSellCounter[Client], sellmax);
	Format(MadeBy, 128, "Made by : \n*Creator: ys24ys & Mr.Halt\n*E-Mail: kstae6116.sk@gmail.com\n*Version: %s", PLUGIN_VERSION);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "1", "Buy Items");
	AddMenuItem(menu, "2", ItemSell);
	AddMenuItem(menu, "3", "Respawn");
	AddMenuItem(menu, "-1", MadeBy, ITEMDRAW_DISABLED);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Main(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));

				switch (StringToInt(sInfo))
				{
					case 1: Shop_Menu_Buy(param1);
					case 2: Shop_Menu_Sell(param1);
					case 3: Shop_Menu_Respawn(param1);
				}
			}
		}
	}
}

public Shop_Menu_Buy(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Buy);
	decl String:TitleFormat[256];
	Format(TitleFormat, 256, "◈Buy items◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "1", "Melee(근접무기)");
	AddMenuItem(menu, "2", "Pistols(권총)");
	AddMenuItem(menu, "3", "Rifles(소총)");
	AddMenuItem(menu, "4", "Sniper Rifles(저격총)");
	AddMenuItem(menu, "5", "Shotguns(산탄총)");
	AddMenuItem(menu, "6", "Explosives(폭발물)");
	AddMenuItem(menu, "7", "Tools(도구)");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Buy(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Main(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));

				switch (StringToInt(sInfo))
				{
					case 1: Shop_Menu_Melee(param1);
					case 2: Shop_Menu_Pistol(param1);
					case 3: Shop_Menu_Rifle(param1);
					case 4: Shop_Menu_Sniper(param1);
					case 5: Shop_Menu_Shotgun(param1);
					case 6: Shop_Menu_Explosive(param1);
					case 7: Shop_Menu_Tools(param1);
				}
			}
		}
	}
}

public Shop_Menu_Melee(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Melee);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Melee(근접무기)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=MELEE_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Melee[i][1], Weapon_Melee[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Melee(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Melee[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Melee[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Melee[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Pistol(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Pistol);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Pistols(권총)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=PISTOL_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Pistol[i][1], Weapon_Pistol[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Pistol(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Pistol[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Pistol[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Pistol[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Rifle(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Rifle);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Rifles(소총)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=RIFLE_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Rifle[i][1], Weapon_Rifle[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Rifle(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					PrintToChat(param1, "For use item shop, you need to alive.");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Rifle[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Rifle[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Rifle[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Sniper(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Sniper);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Sniper Rifles(저격총)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=SNIPER_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Sniper[i][1], Weapon_Sniper[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Sniper(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Sniper[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Sniper[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Sniper[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Shotgun(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Shotgun);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Shotguns(산탄총)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=SHOTGUN_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Shotgun[i][1], Weapon_Shotgun[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Shotgun(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Shotgun[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Shotgun[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Shotgun[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Explosive(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Explosive);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Explosives(폭발물)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=EXPLOSIVE_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Explosive[i][1], Weapon_Explosive[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Explosive(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Explosive[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Explosive[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Explosive[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Tools(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Tools);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Tools(도구)◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=0; i<=TOOLS_MAX-1; i++)
	{
		Format(MenuCount, 32, "%d", i);
		Format(MenuFormat, 128, "%s - %sc", Weapon_Tools[i][1], Weapon_Tools[i][2]);
		AddMenuItem(menu, MenuCount, MenuFormat);
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Tools(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Buy(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need to alive");
					return;
				}
				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new Num = StringToInt(sInfo);
				new Price = StringToInt(Weapon_Tools[Num][2]);
				
				if(ClientCash[param1] >= Price)
				{
					new iWeapon = GivePlayerItem(param1, Weapon_Tools[Num][0]);
					AcceptEntityInput(iWeapon, "use", param1);
					ClientCash[param1] -= Price;
					
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Bought successful", Weapon_Tools[Num][1]);
				}
				else
				{
					CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
				}
			}
		}
	}
}

public Shop_Menu_Sell(Client)
{
	new iWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
	if(iWeapon > 0)
	{
		decl String:WeaponName[64];
		GetEntityClassname(iWeapon, WeaponName, 64);
		new Sell_Price = FindFunction_ItemPrice(WeaponName);
		if(Sell_Price > 0)
		{
			new OtherUse = FindFunction_MyWeapon(Client, "me_fists");
			if(OtherUse > 0)
			{
				new sellmax = GetConVarInt(sm_nmrih_itemshop_sell_restriction);
				if(ClientSellCounter[Client] < sellmax)
				{
					RemovePlayerItem(Client, iWeapon);
					RemoveEdict(iWeapon);
					new ItemWeight = FindFunction_ItemWeight(WeaponName);
					ClientFunction_ItemWeightRemove(Client, ItemWeight);
					
					CreateTimer(1.0, ClientFunction_SwitchWeapon, Client);
					
					ClientCash[Client] += Sell_Price;
					ClientSellCounter[Client] += 1;
					CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Sell successful", Sell_Price);
				} else CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Sell failed 3", sellmax);
			}
		}
		else CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Sell failed 1");
	}
	else CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Sell failed 2");
}

public Action:ClientFunction_SwitchWeapon(Handle:timer, any:Client)
{
	EquipPlayerWeapon(Client, FindFunction_MyWeapon(Client, "me_fists"));
}

public ClientFunction_ItemWeightRemove(Client, const ItemWeight)
{
	new _carriedWeight = FindSendPropOffs("CNMRiH_Player", "_carriedWeight");
	new Weight = GetEntData(Client, _carriedWeight);
	
	SetEntData(Client, _carriedWeight, Weight - ItemWeight, 4, false);
}


public Shop_Menu_Respawn(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Respawn);
	new Price = GetConVarInt(sm_nmrih_itemshop_price_respawn);
	new Price2 = GetConVarInt(sm_nmrih_itemshop_price_respawn_other);
	decl String:TitleFormat[256], String:Line1[128], String:Line2[128], String:Line3[128];
	Format(TitleFormat, 256, "◈Respawn◈\nCash : %d", ClientCash[Client]);
	Format(Line1, 128, "Respawn on start point - %dc", Price);
	Format(Line2, 128, "Respawn near players - %dc", Price);
	Format(Line3, 128, "Respawn other players - %dc", Price2);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "1", Line1);
	AddMenuItem(menu, "2", Line2);
	AddMenuItem(menu, "3", Line3);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Respawn(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Main(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				switch (StringToInt(sInfo))
				{
					case 1: Shop_Menu_Respawn_Instant(param1, false);
					case 2: Shop_Menu_Respawn_Instant(param1, true);
					case 3: Shop_Menu_Respawn_Colleague(param1);
				}
			}
		}
	}
}

public Shop_Menu_Respawn_Instant(Client, bool:Type)
{
	new Price = GetConVarInt(sm_nmrih_itemshop_price_respawn);
	new AlivePlayer = FindFunction_LiveColleague(Client);
	if(IsClientInGame(Client))
	{
		if(!IsPlayerAlive(Client))
		{
			if(ClientCash[Client] >= Price)
			{
				if(Type == false)
				{
					SystemFunction_RespawnStation(Client);
					
					DispatchSpawn(Client);
					SetEntProp(Client, Prop_Send, "m_iPlayerState", 0);
					SetEntProp(Client, Prop_Send, "m_iHideHUD", 2050);
					
					if(LastDeathPosition[Client][0] != 0.0)
					{
						TeleportEntity(Client, LastDeathPosition[Client], NULL_VECTOR, NULL_VECTOR);
					}
					
					ClientCash[Client] -= Price;
				}
				else
				{
					if(AlivePlayer != -1)
					{
						SystemFunction_RespawnStation(Client);
						
						DispatchSpawn(Client);
						SetEntProp(Client, Prop_Send, "m_iPlayerState", 0);
						SetEntProp(Client, Prop_Send, "m_iHideHUD", 2050);
						
						new Float:vTarget[3];
						GetClientAbsOrigin(AlivePlayer, vTarget);
						TeleportEntity(Client, vTarget, NULL_VECTOR, NULL_VECTOR);
						ClientCash[Client] -= Price;
					}
					else CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Can't find alive players");
				}
			}
			else CPrintToChat(Client, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[Client]);
		}
		else CPrintToChat(Client, "[\x04Item Shop\x01] %t.", "Failed at revive");
	}
}

public SystemFunction_RespawnStation(Client)
{
	RespawnStation[Client] = CreateEntityByName("info_player_nmrih");
	DispatchKeyValueVector(RespawnStation[Client], "Origin", LastDeathPosition[Client]);
	DispatchSpawn(RespawnStation[Client]);
	
	CreateTimer(5.0, SystemFunction_RespawnStation_Remove, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SystemFunction_RespawnStation_Remove(Handle:timer, any:Client)
{
	if(RespawnStation[Client] > 0)
	{
		decl String:EntityName[64];
		GetEntityClassname(RespawnStation[Client], EntityName, 64);
		if(StrEqual(EntityName, "info_player_nmrih"))
		{
			RemoveEdict(RespawnStation[Client]);
			RespawnStation[Client] = 0;
		}
	}
}

public Shop_Menu_Respawn_Colleague(Client)
{
	new Handle:menu = CreateMenu(Callback_Shop_Menu_Respawn_Colleague);
	decl String:TitleFormat[256], String:MenuCount[32], String:MenuFormat[128];
	Format(TitleFormat, 256, "◈Respawn other players◈\nCash : %d", ClientCash[Client]);
	SetMenuTitle(menu, TitleFormat);
	SetMenuExitButton(menu, true);
	for(new i=1; i<=8; i++)
	{
		if(IsClientInGame(i) && !IsPlayerAlive(i))
		{
			Format(MenuCount, 128, "%d", i);
			Format(MenuFormat, 128, "%N", i);
			AddMenuItem(menu, MenuCount, MenuFormat);
		}
	}
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, Client, MENU_TIME_FOREVER);
}

public Callback_Shop_Menu_Respawn_Colleague(Handle:hHandle, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(hHandle);
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				Shop_Menu_Respawn(param1);
			}
		}

		case MenuAction_Select:
		{
			if(!IsClientInGame(param1))
			{
				return;
			}
			if(action == MenuAction_Select)
			{				
				new String:sInfo[32];
				GetMenuItem(hHandle, param2, sInfo, sizeof(sInfo));
				
				new TargetPlayer = StringToInt(sInfo);
				new Price = GetConVarInt(sm_nmrih_itemshop_price_respawn_other);
				
				if(TargetPlayer > 0 && TargetPlayer <= 8)
				{
					if(ClientCash[param1] >= Price)
					{
						ClientCash[param1] -= Price;
						Shop_Menu_Respawn_Colleague_Function(TargetPlayer);
						new String:name1[32];
						GetClientName(param1, name1, sizeof(name1));
						new String:name2[32];
						GetClientName(TargetPlayer, name2, sizeof(name2));
						CPrintToChatAll("[\x04Item Shop\x01] %t", "Respawned a player", name1, name2);
					}
					else
					{
						CPrintToChat(param1, "[\x04Item Shop\x01] %t", "Need more cash", Price - ClientCash[param1]);
					}
				}
			}
		}
	}
}

public Shop_Menu_Respawn_Colleague_Function(Client)
{
	new AlivePlayer = FindFunction_LiveColleague(Client);
	if(IsClientInGame(Client))
	{
		if(!IsPlayerAlive(Client))
		{
			SystemFunction_RespawnStation(Client);
			
			DispatchSpawn(Client);
			SetEntProp(Client, Prop_Send, "m_iPlayerState", 0);
			SetEntProp(Client, Prop_Send, "m_iHideHUD", 2050);
			
			if(AlivePlayer != -1)
			{
				new Float:vTarget[3];
				GetClientAbsOrigin(AlivePlayer, vTarget);
				TeleportEntity(Client, vTarget, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				if(LastDeathPosition[Client][0] != 0.0)
				{
					TeleportEntity(Client, LastDeathPosition[Client], NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}

stock FindFunction_LiveColleague(Client)
{
	for(new i=1; i<=8; i++)
	{
		if(i != Client && IsClientInGame(i) && IsPlayerAlive(i))
		{
			return i;
		}
	}
	
	return -1;
}

stock FindFunction_ItemPrice(const String:Name[])
{
	new Price;
	new Float:Sell_Ratio = GetConVarFloat(sm_nmrih_itemshop_sell_ratio);
	
	for(new i=0; i<=MELEE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Melee[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Melee[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=PISTOL_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Pistol[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Pistol[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=RIFLE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Rifle[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Rifle[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=SNIPER_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Sniper[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Sniper[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=SHOTGUN_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Shotgun[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Shotgun[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=EXPLOSIVE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Explosive[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Explosive[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	for(new i=0; i<=TOOLS_MAX-2; i++)
	{
		if(StrEqual(Name, Weapon_Tools[i][0]))
		{
			Price = RoundToCeil(StringToFloat(Weapon_Tools[i][2]) * Sell_Ratio);
			if(Price < 1) Price = 1;
			return Price;
		}
	}
	
	return -1;
}

stock FindFunction_ItemWeight(const String:Name[])
{
	new Weight;
	
	for(new i=0; i<=MELEE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Melee[i][0]))
		{
			Weight = StringToInt(Weapon_Melee[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=PISTOL_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Pistol[i][0]))
		{
			Weight = StringToInt(Weapon_Pistol[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=RIFLE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Rifle[i][0]))
		{
			Weight = StringToInt(Weapon_Rifle[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=SNIPER_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Sniper[i][0]))
		{
			Weight = StringToInt(Weapon_Sniper[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=SHOTGUN_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Shotgun[i][0]))
		{
			Weight = StringToInt(Weapon_Shotgun[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=EXPLOSIVE_MAX-1; i++)
	{
		if(StrEqual(Name, Weapon_Explosive[i][0]))
		{
			Weight = StringToInt(Weapon_Explosive[i][3]);
			return Weight;
		}
	}
	
	for(new i=0; i<=TOOLS_MAX-2; i++)
	{
		if(StrEqual(Name, Weapon_Tools[i][0]))
		{
			Weight = StringToInt(Weapon_Tools[i][3]);
			return Weight;
		}
	}
	
	return 0;
}

stock FindFunction_MyWeapon(Client, const String:WeaponName[])
{
	new OffsetData = FindSendPropOffs("CNMRiH_Player", "m_hMyWeapons");
	if(OffsetData != -1)
	{
		for(new i=0; i<=192; i+=4)
		{
			new MemberData = GetEntDataEnt2(Client, OffsetData + i);
			if(MemberData > 0)
			{
				decl String:Name[64];
				GetEntityClassname(MemberData, Name, 64);
				if(StrEqual(WeaponName, Name)) return MemberData;
			}
		}
	}
	
	return -1;
}
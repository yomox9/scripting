#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Health display",
	author = "CactusPie",
	description = "Allows to check your own health.",
	version = "1.0",
	url = "http://cactuspie.eu/"
}

public OnPluginStart()
{
    PrintToServer("Health display by CactusPie has been loaded.");
}

public OnPlayerRunCmd()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && (IN_RELOAD & GetClientButtons(i)))
		{
			new health = GetClientHealth(i);
			if(health >= 66.666)
			{
				SetHudTextParams(0.01, 0.01, 0.1, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, 50, "Health: Green");
			}
			else if(health >= 33.333)
			{
				SetHudTextParams(0.01, 0.01, 0.1, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, 50, "Health: Orange");
			}
			else
			{
				SetHudTextParams(0.01, 0.01, 0.1, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, 50, "Health: Red");
			}
		}
	}
}
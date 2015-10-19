#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <system2>

#pragma semicolon 1

#define MAX_CRONS 120

#define CRON_MIN 0
#define CRON_HOUR 1
#define CRON_DAY 2
#define CRON_MONTH 3
#define CRON_WEEK 4

new Handle:c_logging;

new bool:cron_times[MAX_CRONS][5][60];
new String:cron_style[MAX_CRONS][10];
new String:cron_command[MAX_CRONS][2024];

new cron_count;
new bool:logging;

public Plugin:myinfo =
{
	name = "Cronjobs01",
	author = "Popoklopsi/ modified yomox9",
	version = "1.1",
	description = "A cronjob01 Plugin for Sourcemod",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnPluginStart()
{
	CreateConVar("crontab_version01", "1.1", "Crontab01 by Popoklopsi", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	c_logging = CreateConVar("crontab_logging01", "1", "Logging Crontab01 executions and outputs", FCVAR_PLUGIN);
	
	loadCrons();
	
	CreateTimer(60.0, doJobs, _, TIMER_REPEAT);
	
	RegServerCmd("cronjobs_reload01", reloadCrons, "Reload the Crontab01");
	
	AutoExecConfig(true, "cronjobs01", "");
}

public OnConfigsExecuted()
{
	logging = GetConVarBool(c_logging);
}

public Action:reloadCrons(args)
{
	for (new i=0; i < cron_count; i++)
	{
		for (new x=0; x < 60; x++)
		{
			for (new y=0; y < 5; y++)
				cron_times[i][y][x] = false;
		}
	}
	
	cron_count = 0;
		
	loadCrons();
}

public loadCrons()
{
	if (FileExists("cfg/cronjobs01.txt"))
	{
		decl String:fileLine[2700];
		decl String:splited[2024];
		
		new Handle:file = OpenFile("cfg/cronjobs01.txt", "rb");

		while(ReadFileLine(file, fileLine, sizeof(fileLine)))
		{
			new split; 
			new error = false;
			
			ReplaceString(fileLine, sizeof(fileLine), "\n", "");
			
			if (!StrEqual(fileLine, "\0") && strlen(fileLine) > 10 && (fileLine[0] != '/' || fileLine[1] != '/'))
			{
				for (new i=0; i <= 5; i++)
				{
					split = SplitString(fileLine, " ", splited, sizeof(splited));
					
					if (split == -1)
					{
						LogError("Couln't Split Line %s!", fileLine);
						
						error = true;
						
						break;
					}
					
					ReplaceStringEx(fileLine, sizeof(fileLine), splited, "");
					ReplaceStringEx(fileLine, sizeof(fileLine), " ", "");
					
					if (i < 5)
					{
						if (!parseArgument(splited, i))
						{	
							error = true;
							
							break;
						}
						
						if (i == CRON_WEEK && cron_times[cron_count][CRON_WEEK][7])
							cron_times[cron_count][CRON_WEEK][0] = true;
					}
					else
						Format(cron_style[cron_count], sizeof(cron_style[]), splited);
				}
				
				if (!error)
				{
					Format(cron_command[cron_count++], sizeof(cron_command[]), fileLine);
					
					LogMessage("CronJob01 '%s' successfully added!", fileLine);
				}
				else
				{
					for (new x=0; x < 60; x++)
					{
						for (new y=0; y < 5; y++)
							cron_times[cron_count][y][x] = false;
					}
			
					LogError("CronJob01 '%s' couldn't added!", fileLine);
				}
			}
		}
	}
}

public bool:parseArgument(String:nline[], argument)
{
	decl String:line[256];
	new String:exploded[128][10];
	
	new min;
	new max;
	
	strcopy(line, sizeof(line), nline);
	
	if (argument == CRON_MIN)
	{
		min = 0;
		max = 60;
	}
	
	else if (argument == CRON_HOUR)
	{
		min = 0;
		max = 24;
	}
	
	else if (argument == CRON_DAY)
	{
		min = 1;
		max = 32;
		
		cron_times[cron_count][CRON_DAY][max] = false;
	}
	
	else if (argument == CRON_MONTH)
	{
		min = 1;
		max = 13;
	}
	
	else if (argument == CRON_WEEK)
	{
		min = 0;
		max = 8;
		
		cron_times[cron_count][CRON_WEEK][max] = false;
	}
	else
		return false;
	
	new found = ExplodeString(line, ",", exploded, sizeof(exploded), sizeof(exploded[]));

	if (found > 0)
	{
		for (new i=0; i < found; i++)
		{
			if (!StrEqual(exploded[i], "") && !StrEqual(exploded[i], "\0"))
			{
				if (StrContains(exploded[i], "*/") > -1)
				{
					ReplaceString(exploded[i], sizeof(exploded[]), "*/", "");
					
					new number = StringToInt(exploded[i]);
					
					if (number > 0)
					{
						for (new j=min; j < max; j++)
						{
							if (j % number == 0)
								cron_times[cron_count][argument][j] = true;
						}								
					}
					else
					{
						LogError("Use */ not with 0!");
						
						return false;
					}
				}
				else if (StrContains(exploded[i], "-") > -1)
				{
					new String:buffer[3][3];
					
					new founded = ExplodeString(exploded[i], "-", buffer, sizeof(buffer), sizeof(buffer[]));
					
					if (founded > 1)
					{
						new number1 = StringToInt(buffer[0]);
						new number2 = StringToInt(buffer[1]);

						if (number1 <= 0)
						{
							if (StrEqual(buffer[0], "0") || StrEqual(buffer[0], "00"))
								number1 = 0;
								
							else
							{
								LogError("Couldn't Parse Number %s!", buffer[0]);
								
								return false;
							}
						}
						
						if (number1 >= min && number2 > number1 && number2 < max)
						{
							for (new j=number1; j <= number2; j++)
								cron_times[cron_count][argument][j] = true;
						}
						else
						{
							LogError("Incorrect Format in Argument %i: '%s'", argument, exploded[i]);
							
							return false;
						}
					}
					else
					{
						LogError("'%s' is INVALID!", exploded[i]);
						
						return false;
					}
				}
				else if (StrEqual(exploded[i], "*"))
				{
					for (new j=min; j < max; j++)
						cron_times[cron_count][argument][j] = true;
						
					if (argument == CRON_WEEK || argument == CRON_DAY)
						cron_times[cron_count][argument][max] = true;
				}
				else
				{
					new number = StringToInt(exploded[i]);
					
					if (number <= 0)
					{
						if (StrEqual(exploded[i], "0") || StrEqual(exploded[i], "00"))
							number = 0;
							
						else
						{
							LogError("Couldn't Parse Number %s!", exploded[i]);
							
							return false;
						}
					}
					
					if (number >= min && number < max)
						cron_times[cron_count][argument][number] = true;
						
					else
					{
						LogError("Incorrect Format in Argument %i: '%s'", argument, exploded[i]);
						
						return false;
					}
				}
			}
			else
			{
				LogError("Couldn't Split String '%s'!", line);
				
				return false;
			}
		}
	}
	else
	{
		LogError("Couldn't Split String '%s'!", line);
		
		return false;
	}
	
	return true;
}

public Action:doJobs(Handle:timer, any:data)
{
	decl String:buffer[10];
	decl String:output[2048];
	
	new bool:execute;
	
	FormatTime(buffer, sizeof(buffer), "%M");
	new minute = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%H");
	new hour = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%d");
	new day = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%m");
	new month = StringToInt(buffer);
	
	FormatTime(buffer, sizeof(buffer), "%w");
	new week = StringToInt(buffer);

	for (new i=0; i < cron_count; i++)
	{
		execute = false;
		
		if (cron_times[i][CRON_WEEK][8])
		{
			if (cron_times[i][CRON_MIN][minute] && cron_times[i][CRON_HOUR][hour] && cron_times[i][CRON_DAY][day] && cron_times[i][CRON_MONTH][month])
				execute = true;
		}
		else
		{
			if (cron_times[i][CRON_DAY][32])
			{
				if (cron_times[i][CRON_MIN][minute] && cron_times[i][CRON_HOUR][hour] && cron_times[i][CRON_MONTH][month] && cron_times[i][CRON_WEEK][week])
					execute = true;
			}
			else
			{
				if (cron_times[i][CRON_MIN][minute] && cron_times[i][CRON_HOUR][hour] && ((cron_times[i][CRON_DAY][day] && cron_times[i][CRON_MONTH][month]) || (cron_times[i][CRON_MONTH][month] && cron_times[i][CRON_WEEK][week])))
					execute = true;
			}
		}
		
		if (execute)
		{
			if (StrEqual(cron_style[i], "console"))
			{
				if (logging)
				{
					ServerCommandEx(output, sizeof(output), cron_command[i]);
					
					LogMessage("Executed Crontab01 Console Command: %s", cron_command[i]);
					LogMessage("Crontab01 Output is: %s", output);
				}
				else
					ServerCommand(cron_command[i]);
			}
			else if (StrEqual(cron_style[i], "player"))
			{
				for (new client=1; client <= MaxClients; client++)
				{
					if (IsClientAuthorized(client))
						FakeClientCommandEx(client, cron_command[i]);
				}
				
				if (logging)
					LogMessage("Executed Crontab01 Player Command: %s", cron_command[i]);
			}
			else if (StrEqual(cron_style[i], "system"))
			{
				if (LibraryExists("system2"))
					RunThreadCommand(CommandRun, cron_command[i]);
				else
					LogError("Couldn't run system command! Doesn't found system2 Extension!");
			}
		}
	}
}

public CommandRun(const String:command[], const String:output[], Cmd_Return:status)
{
	if (logging)
	{
		LogMessage("Executed Crontab01 System Command: %s", command);
		LogMessage("Crontab01 Output is: %s", output);
	}
}
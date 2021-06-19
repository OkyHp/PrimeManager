#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <PrimeManager>
#include <csgo_colors>

public Plugin myinfo =
{
	name		= "[PM] Block Command",
	author		= "OkyHp",
	version		= "1.0.0",
	url			= "OkyHek#2441, https://prime.napas.cc/"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErr_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		strcopy(szError, iErr_max, "This plugin works only on CS:GO!");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar Convar;
	(Convar = CreateConVar(
		"sm_pm_block_commands",	"",
		"Block commands for non prime players. Example: \"sm_ws;sm_vip\""
	)).AddChangeHook(ChangeCvar_CommandsList);
	ChangeCvar_CommandsList(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "PM_BlockCommand");
	LoadTranslations("PM_BlockCommand.phrases");
}

void ChangeCvar_CommandsList(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	char szBuffer[128];

	strcopy(szBuffer, sizeof(szBuffer), oldValue);
	HookCommands(szBuffer, false);

	Convar.GetString(szBuffer, sizeof(szBuffer));
	HookCommands(szBuffer, true);
}

void HookCommands(char[] szCommands, bool bType)
{
	if (szCommands[0])
	{
		int iPos;
		do {
			iPos = FindCharInString(szCommands, ';', true);
			if (iPos != -1)
			{
				szCommands[iPos] = 0;
			}

			if (szCommands[iPos+1])
			{
				if (bType)
				{
					AddCommandListener(CommandHandler, szCommands[iPos+1]);
				}
				else
				{
					RemoveCommandListener(CommandHandler, szCommands[iPos+1]);
				}
			}
		} while (iPos != -1);
	}
}

Action CommandHandler(int iClient, const char[] szCommand, int iArgc)
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		PrimeState eState = PM_GetClientPrimeStatus(iClient);
		if (eState == NonPrimeAccount || eState == NotLoaded)
		{
			CGOPrintToChat(iClient, "%t", (eState == NonPrimeAccount ? "NeedPrimeForUseCommand" : "PrimeDataNotLoaded"));
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

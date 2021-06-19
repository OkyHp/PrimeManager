#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <SteamWorks>
#include <PrimeManager>

#define API_URL "https://prime.napas.cc/request"

int			g_iPlayerAccountID[MAXPLAYERS+1];
PrimeState	g_ePlayerPrime[MAXPLAYERS+1];
float		g_fTimer;
char		g_sApiKey[64];
ArrayList	g_hRetryList,
			g_hPrimeUsers;
Handle		g_hGlobalForward_OnClientPreDataPrimeLoad,
			g_hGlobalForward_OnClientDataPrimeLoaded,
			g_hGlobalForward_OnClientDataPrimeLoadedPost;

public Plugin myinfo =
{
	name		= "Prime Manager",
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

	CreateNative("PM_GetClientPrimeStatus", Native_PM_GetClientPrimeStatus);
	RegPluginLibrary("PrimeManager");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hGlobalForward_OnClientPreDataPrimeLoad		= CreateGlobalForward("PM_OnClientPreDataPrimeLoad", ET_Hook, Param_Cell, Param_Cell);
	g_hGlobalForward_OnClientDataPrimeLoaded		= CreateGlobalForward("PM_OnClientDataPrimeLoaded", ET_Hook, Param_Cell, Param_Cell, Param_CellByRef);
	g_hGlobalForward_OnClientDataPrimeLoadedPost	= CreateGlobalForward("PM_OnClientDataPrimeLoadedPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	HookEvent("player_disconnect", EventPlayerDisconnect);

	ConVar Convar;
	(Convar = CreateConVar(
		"sm_pm_api_key",	"", 
		"API Key (https://prime.napas.cc/). Format: XXXXX-XXXXX-XXXXX-XXXXX"
	)).AddChangeHook(ChangeCvar_ApiKey);
	ChangeCvar_ApiKey(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar(
		"sm_pm_fail_request_interval",	"30", 
		"Interval in seconds to retry request, in case of failure",
		_, true, 15.0, true, 120.0
	)).AddChangeHook(ChangeCvar_FailRequestInterval);
	ChangeCvar_FailRequestInterval(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "PrimeManager");

	g_hRetryList = new ArrayList();
	g_hPrimeUsers = new ArrayList();
}

public void OnMapStart()
{
	CreateTimer(g_fTimer, Timer_Repeat, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void ChangeCvar_ApiKey(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	Convar.GetString(g_sApiKey, sizeof(g_sApiKey));
}

void ChangeCvar_FailRequestInterval(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_fTimer = Convar.FloatValue;
}

Action CallForward_OnClientPreDataPrimeLoad(int iClient, int iAccountID)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForward_OnClientPreDataPrimeLoad);
	Call_PushCell(iClient);
	Call_PushCell(iAccountID);
	Call_Finish(Result);
	return Result;
}

Action CallForward_OnClientDataPrimeLoaded(int iClient, int iAccountID, PrimeState &ePrime)
{
	Action Result = Plugin_Continue;
	Call_StartForward(g_hGlobalForward_OnClientDataPrimeLoaded);
	Call_PushCell(iClient);
	Call_PushCell(iAccountID);
	Call_PushCellRef(ePrime);
	Call_Finish(Result);
	return Result;
}

void CallForward_OnClientDataPrimeLoadedPost(int iClient, int iAccountID, PrimeState ePrime)
{
	Call_StartForward(g_hGlobalForward_OnClientDataPrimeLoadedPost);
	Call_PushCell(iClient);
	Call_PushCell(iAccountID);
	Call_PushCell(ePrime);
	Call_Finish();
}

// PrimeState PM_GetClientPrimeStatus(int iClient);
int Native_PM_GetClientPrimeStatus(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if (iClient < 1 || iClient > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "[PM] Invalid client index '%i'.", iClient);
		return 0;
	}

	return view_as<int>(g_ePlayerPrime[iClient]);
}

public void OnClientAuthorized(int iClient)
{
	if (!IsFakeClient(iClient) && !IsClientSourceTV(iClient))
	{
		g_iPlayerAccountID[iClient] = GetSteamAccountID(iClient, true);
		
		if (g_iPlayerAccountID[iClient])
		{	
			if (g_hPrimeUsers.FindValue(g_iPlayerAccountID[iClient]) != -1)
			{
				g_ePlayerPrime[iClient] = PrimeAccount;
				return;
			}
			
			Action aResult = CallForward_OnClientPreDataPrimeLoad(iClient, g_iPlayerAccountID[iClient]);
			if (aResult == Plugin_Continue)
			{
				g_ePlayerPrime[iClient] = NotLoaded;
				SendHttpQuery(iClient, g_iPlayerAccountID[iClient]);
			}
			else
			{
				g_ePlayerPrime[iClient] = IgnoredPlayer;
			}
		}
	}
}

void EventPlayerDisconnect(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iBuff = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iBuff && g_iPlayerAccountID[iBuff])
	{
		iBuff = g_hPrimeUsers.FindValue(g_iPlayerAccountID[iBuff]);
		if (iBuff != -1)
		{
			g_hPrimeUsers.Erase(0);
		}
	}
}

void SendHttpQuery(int iClient, int iAccountID)
{
	char szAccountID[32];
	FormatEx(szAccountID, sizeof(szAccountID), "%i", iAccountID);
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, API_URL);

	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "key", 		g_sApiKey);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "accountid", 	szAccountID);
	SteamWorks_SetHTTPCallbacks(hRequest, HTTPRequestComplete);
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(iClient));

	SteamWorks_SendHTTPRequest(hRequest);
}

public void HTTPRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any iUserID)
{
	delete hRequest;

	switch (eStatusCode)
	{
		case 200, 204:
		{
			int iClient = GetClientOfUserId(iUserID);
			if (iClient)
			{
				g_ePlayerPrime[iClient] = (eStatusCode == k_EHTTPStatusCode200OK ? PrimeAccount : NonPrimeAccount);

				PrimeState ePlayerPrime = g_ePlayerPrime[iClient];
				Action aResult = CallForward_OnClientDataPrimeLoaded(iClient, g_iPlayerAccountID[iClient], ePlayerPrime);
				
				if (aResult == Plugin_Continue)
				{
					if (g_ePlayerPrime[iClient] == PrimeAccount)
					{
						if (g_hPrimeUsers.FindValue(g_iPlayerAccountID[iClient]) != -1)
						{
							LogError("Dublicate: %i - %N", g_iPlayerAccountID[iClient], iClient);
							return;
						}

						g_hPrimeUsers.Push(g_iPlayerAccountID[iClient]);
					}
				}
				else
				{
					g_ePlayerPrime[iClient] = ePlayerPrime;
				}

				CallForward_OnClientDataPrimeLoadedPost(iClient, g_iPlayerAccountID[iClient], g_ePlayerPrime[iClient]);
			}
		}
		case 400: LogError("Response: Invalid request parameters");
		case 403: LogError("Response: Invalid or missing API key");
		case 408, 503:
		{
			int iClient = GetClientOfUserId(iUserID);
			if (iClient && g_hRetryList.FindValue(iUserID) == -1)
			{
				g_hRetryList.Push(iUserID);
			}
		}
		case 500: LogError("Response: Internal error, contact developer (https://prime.napas.cc/)");
	}
}

Action Timer_Repeat(Handle hTimer)
{
	int iCount = g_hRetryList.Length;
	while(iCount--)
	{
		int iClient = GetClientOfUserId(g_hRetryList.Get(0));
		g_hRetryList.Erase(0);

		if (iClient && g_iPlayerAccountID[iClient])
		{
			SendHttpQuery(iClient, g_iPlayerAccountID[iClient]);
		}
	}
	return Plugin_Continue;
}
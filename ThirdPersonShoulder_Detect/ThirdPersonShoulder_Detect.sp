#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2.2"

public Plugin:myinfo =
{
	name = "ThirdPersonShoulder_Detect",
	author = "MasterMind420 & Lux",
	description = "Detects thirdpersonshoulder command for other plugins to use",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2529779"
};

static String:sVote[MAXPLAYERS+1][16];

static bool:bVersus = false;
static bool:bThirdPerson[MAXPLAYERS+1] = false;
static bool:bThirdPersonFix[MAXPLAYERS+1] = false;
static bool:bMapTransition[MAXPLAYERS+1] = false;

static Handle:hCvar_GameMode = INVALID_HANDLE;
new Handle:g_hOnThirdPersonChanged = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_hOnThirdPersonChanged = CreateGlobalForward("TP_OnThirdPersonChanged", ET_Event, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("ThirdPersonShoulder_Detect_Version", PLUGIN_VERSION, "Version Of Plugin", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	HookEvent("player_team", eTeamChange);
	HookEvent("player_death", ePlayerDeath);
	HookEvent("map_transition", eMapTransition);
	HookEvent("survivor_rescued", eSurvivorRescued);
	HookEvent("player_disconnect", ePlayerDisconnect);

	
	hCvar_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(hCvar_GameMode, eConvarChanged);
	
	AddCommandListener(CallVote, "callvote");
	
	CreateTimer(0.25, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapStart()
{
	CvarsChanged();
}

public eConvarChanged(Handle:hCvar, const String:sOldVal[], const String:sNewVal[])
{
	CvarsChanged();
}

CvarsChanged()
{
	static String:sGamemode[32];
	GetConVarString(hCvar_GameMode, sGamemode, sizeof(sGamemode));
	bVersus = StrEqual("versus", sGamemode, false);
}

public Action:tThirdPersonCheck(Handle:hTimer)
{
	static i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i))
			continue;
		
		QueryClientConVar(i, "c_thirdpersonshoulder", QueryClientConVarCallback);
	}
}

public QueryClientConVarCallback(QueryCookie:sCookie, iClient, ConVarQueryResult:sResult, const String:sCvarName[], const String:sCvarValue[])
{
	Call_StartForward(g_hOnThirdPersonChanged);
	Call_PushCell(iClient);
	
	if(bVersus)
	{
		Call_PushCell(false);
		Call_Finish();
		return;
	}
	
	//THIRDPERSON
	if(!StrEqual(sCvarValue, "0"))
	{
		if(bThirdPersonFix[iClient])
		{
			bThirdPerson[iClient] = false;
		}
		else
			bThirdPerson[iClient] = true;
	}
	//FIRSTPERSON
	else
	{
		bThirdPerson[iClient] = false;
		bThirdPersonFix[iClient] = false;
	}
	
	Call_PushCell(bThirdPerson[iClient]);
	Call_Finish();
}

public Action:CallVote(iClient, const String:sCommand[], iArg)
{
	GetCmdArg(1, sVote[iClient], sizeof(sVote[]));
	
	if(sVote[iClient][0] != 'r' || sVote[iClient][0] != 'c')
		return Plugin_Continue;
	
	if(StrEqual(sVote[iClient], "restartgame", false) || StrEqual(sVote[iClient], "changemission", false) || StrEqual(sVote[iClient], "returntolobby", false))
	{
		static i;
		for(i = 1; i <= MaxClients; i++)
		{
			if(!IsValidClient(i) || IsFakeClient(i))
				continue;
			
			bMapTransition[i] = true;
		}
	}
	return Plugin_Continue;
}

public ePlayerDeath(Handle:hEvent, const String:sMame[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public eSurvivorRescued(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	bThirdPersonFix[iClient] = true;
}

public eTeamChange(Handle:hEvent, const String:sMame[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(iClient) || IsFakeClient(iClient))
		return;
	
	if(bMapTransition[iClient])
	{
		bMapTransition[iClient] = false;
		bThirdPersonFix[iClient] = false;
	}
	else
		bThirdPersonFix[iClient] = true;
}

public eMapTransition(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	static i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i))
			continue;
		
		bMapTransition[i] = true;
	}
}

public ePlayerDisconnect(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient < 1)
		return;
	
	bThirdPerson[iClient] = false;
	bThirdPersonFix[iClient] = false;
	bMapTransition[iClient] = false;
}


static bool:IsValidClient(iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}
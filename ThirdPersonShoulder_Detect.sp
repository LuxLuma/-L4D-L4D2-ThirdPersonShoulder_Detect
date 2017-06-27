#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


public Plugin:myinfo =
{
	name = "ThirdPersonShoulder_Detect",
	author = "MasterMind420 & Lux",
	description = "Detects thirdpersonshoulder command for other plugins to use",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2529779"
};

static bool:bVersus = false;
static bool:bThirdPerson[MAXPLAYERS+1];
static bool:bThirdPersonFix[MAXPLAYERS+1];
static bool:bMapTransition[MAXPLAYERS+1];

static Handle:hCvar_GameMode = INVALID_HANDLE;
static Handle:g_hOnThirdPersonChanged = INVALID_HANDLE;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_hOnThirdPersonChanged = CreateGlobalForward("TP_OnThirdPersonChanged", ET_Event, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateTimer(0.25, tThirdPersonCheck, INVALID_HANDLE, TIMER_REPEAT);
	HookEvent("player_team", eTeamChange);
	HookEvent("player_death", ePlayerDeath);
	HookEvent("map_transition", eMapTransition);
	HookEvent("survivor_rescued", eSurvivorRescued);
	
	hCvar_GameMode = FindConVar("mp_gamemode");
	HookConVarChange(hCvar_GameMode, eConvarChanged);
	
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
	if (!StrEqual(sCvarValue, "0"))
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

public ePlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
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

public eTeamChange(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
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

static bool:IsValidClient(iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}
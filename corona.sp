#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <warden>
#include <overlays>
bool coronali[MAXPLAYERS], OyunOynaniyor = false; 
Handle CoronaTimer[MAXPLAYERS] = null;
ConVar CoronaSaniye = null, CoronaDamage = null;
#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
public Plugin myinfo =  { name = "", author = "phiso", description = "", version = "2.0", url = "phiso#3331" };
public void OnMapStart()
{
	char mapismi[512];
	GetCurrentMap(mapismi, sizeof(mapismi));
	if (StrContains(mapismi, "jb_", false) != 0 && StrContains(mapismi, "jail_", false) != 0 && StrContains(mapismi, "ba_jail", false) != 0)
	{
		SetFailState("[CORONA] Bu plugin sadece ve sadece jailbreak modunda calismaktadir.");
	}
	else
	{
		AddFileToDownloadsTable("sound/Plugin_Merkezi/Corona/merhaba_v1.mp3");
		PrecacheSound("Plugin_Merkezi/Corona/merhaba_v1.mp3");
		AddFileToDownloadsTable("sound/Plugin_Merkezi/Corona/ciglik.mp3");
		PrecacheSound("Plugin_Merkezi/Corona/ciglik.mp3");
		AddFileToDownloadsTable("materials/Plugin_Merkezi/Corona/coronaoldun.vmt");
		AddFileToDownloadsTable("materials/Plugin_Merkezi/Corona/coronaoldun.vtf");
	}	
}
public void OnPluginStart()
{
	RegConsoleCmd("sm_corona", CoronaBaslat);
	RegConsoleCmd("sm_coronadur", CoronaSifirla);
	
	HookEvent("player_death", Oyuncu_Oldugunde);
	HookEvent("round_end", ElBasladiBitti);
	HookEvent("round_start", ElBasladiBitti);
	
	CoronaSaniye = CreateConVar("corona_vurma_saniye", "0.7", "Kaç saniyede bir canı gitsin");
	CoronaDamage = CreateConVar("corona_hasar", "3", "Kaç canı gitsin?");
	
	AutoExecConfig(true, "Plugin_Merkezi_Corona", "Plugin_Merkezi");
}
public Action CoronaBaslat(int client, int args)
{
	if (warden_iswarden(client) || (GetAdminFlag(GetUserAdmin(client), Admin_Slay)))
	{
		int CoronaSecilen = RastgeleKisi();
		OyunOynaniyor = true;
		YerdekiSilahlariSil();
		PrintToChatAll("[SM] \x05Corona Olan Kişi \x02%N \x07KAÇINN!!!!!!", CoronaSecilen);
		char coronaname[32];
		GetClientName(CoronaSecilen, coronaname, sizeof(coronaname));
		PrintCenterTextAll("Corona olan kişi: %s KAÇINNNN !!!!", coronaname);
		EmitSoundToClient(CoronaSecilen, "Plugin_Merkezi/Corona/ciglik.mp3");
		ShowOverlay(CoronaSecilen, "Plugin_Merkezi/Corona/coronaoldun", 2.5);
		EmitSoundToAll("Plugin_Merkezi/Corona/merhaba_v1.mp3");
		SetEntPropFloat(CoronaSecilen, Prop_Data, "m_flLaggedMovementValue", 1.2);
		Give_Effect(CoronaSecilen, { 255, 0, 0, 120 } );
		EkranTitreme(CoronaSecilen, 5.0, 9000.0, 4.0, 40.0);
		SetEntityRenderColor(CoronaSecilen, 0, 255, 0, 255);
		coronali[CoronaSecilen] = true;
		CoronaTimer[CoronaSecilen] = CreateTimer(CoronaSaniye.FloatValue, CoronaVur, CoronaSecilen, TIMER_REPEAT);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SilahlariSil(i);
			}
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x05Bu komuta erişiminiz yok.");
	}
}
public Action Oyuncu_Oldugunde(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (OyunOynaniyor)
	{
		delete CoronaTimer[client];
		char Kazanan_Ismi[32];
		int T_Sayisi;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			{
				GetClientName(i, Kazanan_Ismi, sizeof(Kazanan_Ismi));
				T_Sayisi++;
			}
		}
		if (T_Sayisi == 1)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						coronali[i] = false;
						delete CoronaTimer[i];
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
						SetEntityRenderColor(i, 255, 255, 255, 255);
						SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
						OyunOynaniyor = false;
						PrintToChat(i, "[SM] \x05Oyunu \x0B%s \x05Kazandı!", Kazanan_Ismi);
					}
					StopSound(i, SNDCHAN_AUTO, "Plugin_Merkezi/Corona/merhaba_v1.mp3");
				}	
			}	
		}
	}
}
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (!coronali[victim] && coronali[attacker])
		{
			coronali[victim] = true;
			CoronaTimer[victim] = CreateTimer(CoronaSaniye.FloatValue, CoronaVur, victim, TIMER_REPEAT);
			EmitSoundToClient(victim, "Plugin_Merkezi/Corona/ciglik.mp3");
			PrintToChat(victim, "[SM] \x07Corona \x05oldun. \x0B:C");
			ShowOverlay(victim, "Plugin_Merkezi/Corona/coronaoldun", 2.5);
			SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 1.2);
			Give_Effect(victim, { 255, 0, 0, 120 } );
			EkranTitreme(victim, 5.0, 9000.0, 4.0, 40.0);
			SetEntityRenderColor(victim, 0, 255, 0, 255);
			damage = 0.0;
		}	
	}
}
public Action CoronaVur(Handle Timer, int client)
{
	if (coronali[client])
	{
		int health = GetClientHealth(client) - CoronaDamage.IntValue;
		if(health <= 0)
		{
			ForcePlayerSuicide(client);
			return;
		}
		SetEntityHealth(client, health);
	}	
}
public Action CoronaSifirla(int client, int args)
{
	if (warden_iswarden(client) || (GetAdminFlag(GetUserAdmin(client), Admin_Slay)))
	{
		if (OyunOynaniyor)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						coronali[i] = false;
						delete CoronaTimer[i];
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
						SetEntityRenderColor(i, 255, 255, 255, 255);
						SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
						PrintToChat(i, "[SM] \x05Oyun Sıfırlandı!");
						OyunOynaniyor = false;
					}
					StopSound(i, SNDCHAN_AUTO, "Plugin_Merkezi/Corona/merhaba_v1.mp3");
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] \x05Şuan bir oyun oynanmıyor.");
		}		
	}
	else
	{
		ReplyToCommand(client, "[SM] \x05Bu komuta erişimiz yok.");
	}
}
public Action ElBasladiBitti(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			coronali[i] = false;
			delete CoronaTimer[i];
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			StopSound(i, SNDCHAN_AUTO, "Plugin_Merkezi/Corona/merhaba_v1.mp3");
			OyunOynaniyor = false;	
		}
	}
}void EkranTitreme(int client, float Amplitude, float Radius, float Duration, float Frequency){float ClientOrigin[3];int Ent = CreateEntityByName("env_shake");if (DispatchSpawn(Ent)){DispatchKeyValueFloat(Ent, "amplitude", Amplitude);DispatchKeyValueFloat(Ent, "radius", Radius);DispatchKeyValueFloat(Ent, "duration", Duration);DispatchKeyValueFloat(Ent, "frequency", Frequency);SetVariantString("spawnflags 8");AcceptEntityInput(Ent, "AddOutput");AcceptEntityInput(Ent, "StartShake", client);GetClientAbsOrigin(client, ClientOrigin);TeleportEntity(Ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR);}}stock int RastgeleKisi() { int[] clients = new int[MaxClients]; int clientCount; for (int i = 1; i <= MaxClients; i++) { if (IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T) && (IsPlayerAlive(i))) { clients[clientCount++] = i; } } return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; }void Give_Effect(int client, int Renk[4]) { int clients[1]; clients[0] = client; Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0); Protobuf pb = UserMessageToProtobuf(message); pb.SetInt("duration", 200); pb.SetInt("hold_time", 40); pb.SetInt("flags", 17); pb.SetColor("clr", Renk); EndMessage(); } void YerdekiSilahlariSil(){int g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");int maxent = GetMaxEntities();char weapon[64];for (int i = MaxClients; i < maxent; i++){if (IsValidEdict(i) && IsValidEntity(i)){GetEdictClassname(i, weapon, sizeof(weapon)); if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, g_WeaponParent) == -1)RemoveEdict(i);}}}void SilahlariSil(int client){for(int j = 0; j < 5; j++){int weapon = GetPlayerWeaponSlot(client, j);if(weapon != -1){RemovePlayerItem(client, weapon);RemoveEdict(weapon);GivePlayerItem(client, "weapon_knife");}}}bool IsValidClient(int iClient){ if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) { return false; } else { return true; } }

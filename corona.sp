#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <warden>
#include <overlays>
bool coronali[MAXPLAYERS], OyunOynaniyor;
Handle CoronaTimer[MAXPLAYERS] = null;
ConVar CoronaSaniye = null, CoronaDamage = null, Test = null;
#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
public Plugin myinfo =  { name = "", author = "phiso, ByDexter", description = "", version = "1.1", url = "phiso#3331" };
public void OnMapStart()
{
	char mapismi[128];
	GetCurrentMap(mapismi, sizeof(mapismi));
	if (StrContains(mapismi, "jb_", false) != 0 || StrContains(mapismi, "jail_", false) != 0 || StrContains(mapismi, "ba_", false) != 0)
	{
		SetFailState("[CORONA] Sadece Jailbreak haritalarinda calisir!");
	}
	PrecacheSoundAnyDownload("Plugin_Merkezi/Corona/merhaba_v1.mp3");
	PrecacheSoundAnyDownload("Plugin_Merkezi/Corona/ciglik.mp3");
	PreCache("Plugin_Merkezi/Corona/coronaoldun");
}
public void OnPluginStart()
{
	RegConsoleCmd("sm_corona", CoronaBaslat);
	HookEvent("player_death", Oyuncu_Oldugunde);
	HookEvent("round_end", ElBasladiBitti);
	HookEvent("round_start", ElBasladiBitti);
	Test = CreateConVar("sm_flag", "f", "Corona komutunu kullanabilecek yetki bayrağı");
	CoronaSaniye = CreateConVar("corona_vurma_saniye", "0.7", "Kaç saniyede bir canı gitsin", FCVAR_NOTIFY, true, 0.1);
	CoronaDamage = CreateConVar("corona_hasar", "3", "Kaç canı gitsin?", FCVAR_NOTIFY, true, 1.0);
	AutoExecConfig(true, "Corona", "PluginMerkezi");
}
public Action CoronaBaslat(int client, int args)
{
	char Flag[8];
	Test.GetString(Flag, sizeof(Flag));
	if (warden_iswarden(client) || CheckAdminFlag(client, Flag) || client == 0)
	{
		if (!OyunOynaniyor)
		{
			PrintToChatAll("[SM] \x10%N \x01tarafından \x0ECorona \x01başlatıldı!", client);
			int CoronaSecilen = RastgeleKisi();
			OyunOynaniyor = true;
			YerdekiSilahlariSil();
			PrintToChatAll("[SM] \x01Corona Olan Kişi \x10%N \x07KAÇINN!!!!!!", CoronaSecilen);
			char coronaname[MAX_NAME_LENGTH];
			GetClientName(CoronaSecilen, coronaname, sizeof(coronaname));
			PrintCenterTextAll("Corona olan kişi: %s KAÇINNNN !!!!", coronaname);
			EmitSoundToClient(CoronaSecilen, "Plugin_Merkezi/Corona/ciglik.mp3");
			ShowOverlay(CoronaSecilen, "Plugin_Merkezi/Corona/coronaoldun", 2.5);
			EmitSoundToAll("Plugin_Merkezi/Corona/merhaba_v1.mp3");
			SetEntPropFloat(CoronaSecilen, Prop_Data, "m_flLaggedMovementValue", 1.2);
			Give_Effect(CoronaSecilen, { 255, 0, 0, 120 } );
			SetEntityRenderColor(CoronaSecilen, 0, 255, 0, 255);
			coronali[CoronaSecilen] = true;
			CoronaTimer[CoronaSecilen] = CreateTimer(CoronaSaniye.FloatValue, CoronaVur, CoronaSecilen, TIMER_REPEAT);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T)
				{
					SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
					SilahlariSil(i);
				}
			}
			return Plugin_Handled;
		}
		else
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
					}
					StopSound(i, SNDCHAN_AUTO, "Plugin_Merkezi/Corona/merhaba_v1.mp3");
				}
			}
			OyunOynaniyor = false;
			PrintToChatAll("[SM] \x10%N \x01tarafından \x0ECorona \x01sona erdi!", client);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Bu komuta erişiminiz yok.");
		return Plugin_Handled;
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
		if (health <= 0)
		{
			ForcePlayerSuicide(client);
			return;
		}
		SetEntityHealth(client, health);
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
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			StopSound(i, SNDCHAN_AUTO, "Plugin_Merkezi/Corona/merhaba_v1.mp3");
			OyunOynaniyor = false;
		}
	}
} stock bool CheckAdminFlag(int client, const char[] flags) { int iCount = 0; char sflagNeed[22][8], sflagFormat[64]; bool bEntitled = false; Format(sflagFormat, sizeof(sflagFormat), flags); ReplaceString(sflagFormat, sizeof(sflagFormat), " ", ""); iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[])); for (int i = 0; i < iCount; i++) { if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT)) { bEntitled = true; break; } } return bEntitled; } stock void PreCache(char[] sOverlay) { char sBuffer[256]; Format(sBuffer, sizeof(sBuffer), "%s.vmt", sOverlay); PrecacheDecal(sBuffer, true); Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sOverlay); AddFileToDownloadsTable(sBuffer); Format(sBuffer, sizeof(sBuffer), "%s.vtf", sOverlay); PrecacheDecal(sBuffer, true); Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", sOverlay); AddFileToDownloadsTable(sBuffer); } stock void PrecacheSoundAnyDownload(const char[] sSound) { char sBuffer[256]; PrecacheSound(sSound); Format(sBuffer, sizeof(sBuffer), "sound/%s", sSound); AddFileToDownloadsTable(sBuffer); } stock int RastgeleKisi() { int[] clients = new int[MaxClients]; int clientCount; for (int i = 1; i <= MaxClients; i++) { if (IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T) && (IsPlayerAlive(i))) { clients[clientCount++] = i; } } return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; } stock void Give_Effect(int client, int Renk[4]) { int clients[1]; clients[0] = client; Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0); Protobuf pb = UserMessageToProtobuf(message); pb.SetInt("duration", 200); pb.SetInt("hold_time", 40); pb.SetInt("flags", 17); pb.SetColor("clr", Renk); EndMessage(); } stock void YerdekiSilahlariSil() { int g_WeaponParent = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity"); int maxent = GetMaxEntities(); char weapon[64]; for (int i = MaxClients; i < maxent; i++) { if (IsValidEdict(i) && IsValidEntity(i)) { GetEdictClassname(i, weapon, sizeof(weapon)); if ((StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1) && GetEntDataEnt2(i, g_WeaponParent) == -1)RemoveEdict(i); } } } stock void SilahlariSil(int client) { for (int j = 0; j < 12; j++) { int weapon = GetPlayerWeaponSlot(client, j); if (weapon != -1) { RemovePlayerItem(client, weapon); RemoveEdict(weapon); GivePlayerItem(client, "weapon_knife"); } } } bool IsValidClient(int iClient) { if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) { return false; } else { return true; } } 
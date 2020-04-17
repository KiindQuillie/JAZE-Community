#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#tryinclude <soundscapehook>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

bool gB_MusicDisabled[MAXPLAYERS+1];
Handle gH_SoundCookie_Music = null;

bool gB_Nightcore = false;

public Plugin myinfo =
{
	name = "[CS:GO] On/off sounds",
	author = "Afro",
	description = "Sound menu",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	gH_SoundCookie_Music = RegClientCookie("sm_sound_stopmusic", "Stop all map music", CookieAccess_Protected);

	RegConsoleCmd("sm_sound", Command_Sound, "Opens the sound menu");
	RegConsoleCmd("sm_stopmusic", Command_Sound, "Opens the sound menu");
	RegConsoleCmd("sm_music", Command_Sound, "Opens the sound menu");
	RegAdminCmd("sm_nightcore", Command_Nightcore, ADMFLAG_RCON, "NIGHTCORE.");

	AddAmbientSoundHook(AmbientSoundHook);
}

public void OnMapStart()
{
	gB_Nightcore = false;
}

public void OnClientCookiesCached(int client)
{
	char[] sMusicCookie = new char[4];
	GetClientCookie(client, gH_SoundCookie_Music, sMusicCookie, 4);

	if(strlen(sMusicCookie) == 0)
	{
		SetClientCookie(client, gH_SoundCookie_Music, "0");
		gB_MusicDisabled[client] = false;
	}

	else
	{
		gB_MusicDisabled[client] = view_as<bool>(StringToInt(sMusicCookie));
	}
}

public Action Command_Sound(int client, int args)
{
	if(client == 0 || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}

	return OpenSoundMenu(client);
}

public Action Command_Nightcore(int client, int args)
{
	gB_Nightcore = !gB_Nightcore;

	ShowActivity(client, "Nightcore %s", gB_Nightcore? "on":"off");

	return Plugin_Handled;
}

public Action OpenSoundMenu(int client)
{
	if(!AreClientCookiesCached(client))
	{
		PrintToChat(client, "[Sounds] Что-то пошло не так, попробуйте снова.");

		return Plugin_Handled;
	}

	Menu m = new Menu(MenuHandler_SoundMenu);
	m.SetTitle("Звуки карты:");

	char[] sFormat = new char[32];
	FormatEx(sFormat, 32, "[%s] Вкл/выкл", gB_MusicDisabled[client]? "x":" ");
	m.AddItem("mapmusic", sFormat);

	m.ExitButton = true;

	m.Display(client, 20);

	return Plugin_Handled;
}

public int MenuHandler_SoundMenu(Menu m, MenuAction a, int p1, int p2)
{
	if(a == MenuAction_Select)
	{
		char[] sInfo = new char[16];
		m.GetItem(p2, sInfo, 16);

		if(StrEqual(sInfo, "mapmusic"))
		{
			gB_MusicDisabled[p1] = !gB_MusicDisabled[p1];
			SetClientCookie(p1, gH_SoundCookie_Music, gB_MusicDisabled[p1]? "1":"0");

			PrintToChat(p1, " \x04[Sounds]\x01 Звуки карты %s\x01.", gB_MusicDisabled[p1]? "\x02выключены":"\x05включены");

			if(gB_MusicDisabled[p1])
			{
				ClientCommand(p1, "snd_playsounds Music.StopAllExceptMusic");
			}
		}

		OpenSoundMenu(p1);
	}

	else if(a == MenuAction_End)
	{
		delete m;
	}

	return 0;
}

public Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(gB_MusicDisabled[i] && IsClientConnected(i) && IsClientInGame(i))
		{
			ClientCommand(i, "snd_playsounds Music.StopAllExceptMusic");
		}
	}

	if(gB_Nightcore)
	{
		pitch = 255;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action SoundscapeUpdateForPlayer(int entity, int client)
{
	if(gB_MusicDisabled[client] && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

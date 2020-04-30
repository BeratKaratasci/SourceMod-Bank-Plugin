#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Vortéx!"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <store>
#include <multicolors>

Database h_dbConnection = null;
bool parayatirevent[MAXPLAYERS + 1] = false;
bool paracekevent[MAXPLAYERS + 1] = false;
bool kredicekevent[MAXPLAYERS + 1] = false;
int para[MAXPLAYERS + 1] = {0, ...};
int borc[MAXPLAYERS + 1] = {0, ...};

public Plugin myinfo = 
{
	name = "Banka",
	author = PLUGIN_AUTHOR,
	description = "Oyuncular bankaya kredi yatırıp/çekebilirler. Ayrıca bankadan kredi çekerek taksitle ödeme imkanıda vardır.",
	version = PLUGIN_VERSION,
	url = "turkmodders.com"
};

public void OnPluginStart()
{
	dbConnect();
	RegConsoleCmd("sm_banka", banka);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public void OnClientPutInServer(int client)
{
	CreateTimer(60.0, TimerAdd, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerAdd(Handle timer, client)
{
		if(IsClientInGame(client))
		{
			if(borc[client] > 0)
			{
				int odenecek = borc[client] * 0.025;
				borc[client] -= odenecek;
				Store_SetClientCredits(client, odenecek - Store_GetClientCredits(client));
				CPrintToChat(client, "{darkred}[TurkModders] {orange}%i TL {green}borcunuz ödenmiştir. {lime}Teşekkür ederiz!", odenecek);
			}
			
			if(para[client] > 0)
			{
				int verilecek = para[client] + 1;
				para[client] += verilecek;
			}
			
			dbSaveClientData(client);
			dbGetClientData(client);
		}
}

public Action banka(int client, int args) {
	bankamenu(client);
}

public void OnClientPostAdminCheck(int client) {

    dbGetClientData(client);
}


public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public void OnClientDisconnect(int client)
{
    dbSaveClientData(client);
}

public Action bankamenu(int client)
{
    Handle menu = CreateMenu(MenuCallBack);
    SetMenuTitle(menu, "★ Banka Sistemi ★");
    char opcionmenu[124];

    Format(opcionmenu, 124, "✦ Banka Hesabınızdaki Mevcut Kredi: %i", para[client]);
    AddMenuItem(menu, "option1", opcionmenu);
    
    Format(opcionmenu, 124, "✦ Kredi Borcunuz: %i\nBorcunuzun dakikada bir %%0.25'i market kredinizden otomatik çekilir.", borc[client]);
    AddMenuItem(menu, "option6", opcionmenu);

    Format(opcionmenu, 124, "✦ Para Yatır\n Yatırdığınız para dakikada bir banka içerisinde 1 artarak faizlenir.");
    AddMenuItem(menu, "option0", opcionmenu);

    Format(opcionmenu, 124, "✦ Para Çek");
    AddMenuItem(menu, "option2", opcionmenu);

    Format(opcionmenu, 124, "✦ Kredi Çek");
    AddMenuItem(menu, "option3", opcionmenu);

    SetMenuExitBackButton(menu, true);
    SetMenuPagination(menu, MENU_NO_PAGINATION);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuCallBack(Handle menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select )
    {
        char info[32];

        GetMenuItem(menu, itemNum, info, sizeof(info));
        if ( strcmp(info,"option1") == 0 )
        {
			bankamenu(client);
        }
        else if ( strcmp(info,"option6") == 0 )
        {
			bankamenu(client);
        }
        else if ( strcmp(info,"option0") == 0 )
        {
			parayatir(client);
        }
        else if ( strcmp(info,"option2") == 0 )
        {
			paracek(client);
        }
        else if ( strcmp(info,"option3") == 0 )
        {
			kredicek(client);
        }
    }
}

public Action parayatir(int client)
{
    Handle menu = CreateMenu(MenuCallBack2);
    SetMenuTitle(menu, "★ Banka Sistemi ★");
    char opcionmenu[124];

    Format(opcionmenu, 124, "✦ Banka Hesabınızdaki Mevcut Kredi: %i", para[client]);
    AddMenuItem(menu, "option1", opcionmenu);

    Format(opcionmenu, 124, "✦ Para yatırmak için aşağıdaki 'PARA YATIR' seçeneğine basınız.");
    AddMenuItem(menu, "option0", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ Daha sonra sohbete yatırmak istediğiniz tutarı giriniz.");
    AddMenuItem(menu, "option2", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ PARA YATIR");
    AddMenuItem(menu, "option3", opcionmenu);

    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuCallBack2(Handle menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select )
    {
        char info[32];

        GetMenuItem(menu, itemNum, info, sizeof(info));
        if ( strcmp(info,"option1") == 0 )
        {
			parayatir(client);
        }
        else if ( strcmp(info,"option0") == 0 )
        {
			parayatir(client);
        }
        else if ( strcmp(info,"option2") == 0 )
        {
			parayatir(client);
        }
        else if ( strcmp(info,"option3") == 0 )
        {
			parayatirevent[client] = true;
        }
    }
}

public Action paracek(int client)
{
    Handle menu = CreateMenu(MenuCallBack3);
    SetMenuTitle(menu, "★ Banka Sistemi ★");
    char opcionmenu[124];

    Format(opcionmenu, 124, "✦ Banka Hesabınızdaki Mevcut Kredi: %i", para[client]);
    AddMenuItem(menu, "option1", opcionmenu);

    Format(opcionmenu, 124, "✦ Para çekmek için aşağıdaki 'PARA ÇEK' seçeneğine basınız.");
    AddMenuItem(menu, "option0", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ Daha sonra sohbete çekmek istediğiniz tutarı giriniz.");
    AddMenuItem(menu, "option2", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ PARA ÇEK");
    AddMenuItem(menu, "option3", opcionmenu);

    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuCallBack3(Handle menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select )
    {
        char info[32];

        GetMenuItem(menu, itemNum, info, sizeof(info));
        if ( strcmp(info,"option1") == 0 )
        {
			paracek(client);
        }
        else if ( strcmp(info,"option0") == 0 )
        {
			paracek(client);
        }
        else if ( strcmp(info,"option2") == 0 )
        {
			paracek(client);
        }
        else if ( strcmp(info,"option3") == 0 )
        {
			paracekevent[client] = true;
        }
    }
}

public Action kredicek(int client)
{
    Handle menu = CreateMenu(MenuCallBack4);
    SetMenuTitle(menu, "★ Banka Sistemi ★");
    char opcionmenu[124];

    Format(opcionmenu, 124, "✦ Banka Hesabınızdaki Mevcut Kredi: %i", para[client]);
    AddMenuItem(menu, "option1", opcionmenu);

    Format(opcionmenu, 124, "✦ Kredi çekmek için aşağıdaki 'KREDİ ÇEK' seçeneğine basınız.");
    AddMenuItem(menu, "option0", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ Daha sonra sohbete çekmek istediğiniz tutarı giriniz.");
    AddMenuItem(menu, "option2", opcionmenu, ITEMDRAW_DISABLED);
    
	Format(opcionmenu, 124, "✦ Çekilen kredinizin borcu market kredinizden her 1 dakikada bir %%0.25'i olarak tahsil edilir.");
    AddMenuItem(menu, "option5", opcionmenu, ITEMDRAW_DISABLED);

    Format(opcionmenu, 124, "✦ KREDİ ÇEK");
    AddMenuItem(menu, "option3", opcionmenu);

    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuCallBack4(Handle menu, MenuAction:action, client, itemNum)
{
    if ( action == MenuAction_Select )
    {
        char info[32];

        GetMenuItem(menu, itemNum, info, sizeof(info));
        if ( strcmp(info,"option1") == 0 )
        {
			kredicek(client);
        }
        else if ( strcmp(info,"option0") == 0 )
        {
			kredicek(client);
        }
        else if ( strcmp(info,"option2") == 0 )
        {
			kredicek(client);
        }
        else if ( strcmp(info,"option5") == 0 )
        {
			kredicek(client);
        }
        else if ( strcmp(info,"option3") == 0 )
        {
			kredicekevent[client] = true;
        }
    }
}

public Action Command_Say(int client, const char[] command, argc)
{
	if(parayatirevent[client])
	{
		if(client != 0 && IsClientInGame(client))
		{
			if(!BaseComm_IsClientGagged(client)) //if not gagged continue
			{
				char text[256];
				GetCmdArg(1, text, sizeof(text));
				int miktar = StringToInt(text);
				int kredisi = Store_GetClientCredits(client);
				if(miktar > kredisi)
				{
					CPrintToChat(client, "{darkred}[TurkModders] {lightred}Geçersiz kredi miktarı girdiniz! {green}Bu kadar krediye sahip değilsiniz.");
					return Plugin_Handled;
				}
				else
				{
					Store_SetClientCredits(client, Store_GetClientCredits(client) - miktar);
					para[client] += miktar;
					dbSaveClientData(client);
					CPrintToChat(client, "{darkred}[TurkModders] {green}Banka hesabınıza {orange}%i miktarında {green}market kredisi başarıyla yatırıldı!", miktar);
				}
			}
			else
			{
				return Plugin_Handled;
			}
		}
		parayatirevent[client] = false;
	}
	/////////////////////////////////////////////////////////////
	else if(paracekevent[client])
	{
		if(client != 0 && IsClientInGame(client))
		{
			if(!BaseComm_IsClientGagged(client)) //if not gagged continue
			{
				char text[256];
				GetCmdArg(1, text, sizeof(text));
				int miktar = StringToInt(text);
				if(miktar > para[client])
				{
					CPrintToChat(client, "{darkred}[TurkModders] {lightred}Geçersiz kredi miktarı girdiniz! {green}Bu kadar kredi hesabınızda bulunamadı.");
					return Plugin_Handled;
				}
				else
				{
					para[client] -= miktar;
					Store_SetClientCredits(client, Store_GetClientCredits(client) + miktar);
					dbSaveClientData(client);
					CPrintToChat(client, "{darkred}[TurkModders] {green}Banka hesabınızdan {orange}%i miktarında {green}market kredisi başarıyla çekildi!", miktar);
				}
			}
			else
			{
				return Plugin_Handled;
			}
		}
		paracekevent[client] = false;		
	}
	/////////////////////////////////////////////////////////////
	else if(kredicekevent[client])
	{
		if(client != 0 && IsClientInGame(client))
		{
			if(!BaseComm_IsClientGagged(client)) //if not gagged continue
			{
				char text[256];
				GetCmdArg(1, text, sizeof(text));
				int miktar = StringToInt(text);
				if(miktar > 30000)
				{
					CPrintToChat(client, "{darkred}[TurkModders] {orange}Maximum 30.000 kredi {lightred}çekebilirsiniz.");
					return Plugin_Handled;
				}
				if(borc[client] > 0)
				{
					CPrintToChat(client, "{darkred}[TurkModders] {orange}Borcunuzu ödemeden {green}kredi {lightred}çekemezsiniz.");
					return Plugin_Handled;
				}
				borc[client] += miktar;
				Store_SetClientCredits(client, Store_GetClientCredits(client) + miktar);
				dbSaveClientData(client);
				CPrintToChat(client, "{darkred}[TurkModders] {lime}Tebrikler, {green}kredi çekildi! {orange}Oyunda bulunduğunuz her 1 dakika borcunuzun %%0.25'i ödenecek.");
			}
			else
			{
				return Plugin_Handled;
			}
		}
		kredicekevent[client] = false;		
	}	
	return Plugin_Continue;
}

//////////// DB ///////////////
public void dbConnect() {

  if (SQL_CheckConfig("vortex-banka")) {
    Database.Connect(dbConnectCallback, "vortex-banka");
  } else {
    h_dbConnection = null;
    LogError("BANKA :: Database'ye baglanamadi!");
  }
}

public void dbConnectCallback(Database dbConn, const char[] error, any data) {

  if (dbConn != null) {
    h_dbConnection = dbConn;
    dbCreateTables();
  } else {
    h_dbConnection = null;
    LogError("BANKA :: %s", error);
  }
}

public void dbCreateTables() {

  char query[512];

  Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `banka_emre` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `name` VARCHAR(255) NOT NULL, `steamid` VARCHAR(18) NOT NULL, `para` INT UNSIGNED NOT NULL DEFAULT 0, `borc` INT UNSIGNED NOT NULL DEFAULT 0, `created_at` TIMESTAMP NULL, `updated_at` TIMESTAMP NULL, PRIMARY KEY (`id`), UNIQUE(`steamid`)) ENGINE = InnoDB;");
  h_dbConnection.Query(dbCreateTablesCallback, query);
}

public void dbCreateTablesCallback(Database dbConn, DBResultSet results, const char[] error, any data) {

  if (results == null) {
    h_dbConnection = null;
    LogError("BANKA :: %s", error);
  }
}

public void dbGetClientData(int client) {

  if (!IsValidClient(client) || h_dbConnection == null)
    return;

  char query[512];
  char steamId[18];

  GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId));

  Format(query, sizeof(query), "SELECT para, borc FROM banka_emre WHERE steamid = '%s'", steamId);
  h_dbConnection.Query(dbGetClientDataCallback, query, client);
}

public void dbGetClientDataCallback(Database dbConn, DBResultSet results, const char[] error, int client) {

  if (results.FetchRow()) {

    para[client] = results.FetchInt(0);
    borc[client] = results.FetchInt(1);

  } else {

    dbCreateNewClient(client);
  }
}

public void dbCreateNewClient(int client) {

  if (!IsValidClient(client) || h_dbConnection == null)
    return;

  char query[512];
  char steamId[18];
  char clientName[255];
  char escapedClientName[255];

  GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId));
  GetClientName(client, clientName, sizeof(clientName));

  h_dbConnection.Escape(clientName, escapedClientName, sizeof(escapedClientName));

  Format(query, sizeof(query), "INSERT INTO banka_emre (`name`, `steamid`, `para`, `borc`, `created_at`, `updated_at`) VALUES ('%s', '%s', '0', '0', NOW(), NOW())", escapedClientName, steamId);
  h_dbConnection.Query(dbNothingCallback, query, client);
  para[client] = 0;
  borc[client] = 0;
}

public void dbSaveClientData(int client) {

  if (IsValidClient(client, false) && h_dbConnection != null) {

    char query[512];
    char steamId[18];
    char clientName[255];
    char escapedClientName[255];

    GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId));
    GetClientName(client, clientName, sizeof(clientName));

    h_dbConnection.Escape(clientName, escapedClientName, sizeof(escapedClientName));

    Format(query, sizeof(query), "UPDATE `banka_emre` SET `name`= '%s', `para`= %i, `borc`= %i, `updated_at` = NOW() WHERE steamid = '%s'", escapedClientName, para[client], borc[client], steamId);
    h_dbConnection.Query(dbNothingCallback, query, client);

  }
}

public void dbNothingCallback(Database dbConn, DBResultSet results, const char[] error, int client) {

  if (results == null) {

      LogError("BANKA :: %s", error);
  }
}

bool IsValidClient(int client, bool connected = true) {

  return (client > 0 && client <= MaxClients && (connected  == false || IsClientConnected(client))  && IsClientInGame(client) && !IsFakeClient(client));
}
//////////// DB ///////////////

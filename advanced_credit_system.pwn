/*
	* Author: Kristijan Stipić
	* Date: 29.07.2013.

	_____________________________________
	rataKredita(const glavnica, const Float:kamatna_stopa, const period)
	Glavnica - Iznos koji igrač želi dignuti
	Kamatna stopa - Kamatna stopa kredita koji se gleda sa glavnicom
	Period - Ukoliko ovo koristite na RP serveru, savjetujem vam da ovo gledate na način 'Kroz koliko payday-ova će igrač otplatiti kredit', npr. 5 payday-ova i na taj iznos se računa rata svakog kredita
	Funkcija vrača vrijednost rate kredita u INTEGER vrijednosti!

	podignutihKredita(playerid)
	playerid - ID igrača kojem želite provjeriti koliko ima podignutih kredita
	Funkcija vrača vrijednost INTEGER vrijednosti, broja koliko igrač ima podignutih kredita

	podigniKredit(playerid, const glavnica, const Float:kamatna_stopa = PREPORUCENA_KAMATNA_STOPA, const period)
	playerid - ID igrača kojem želite dati kredit
	Glavnica - Iznos kredita koji želite posuditi igraču
	kamatna_stopa - Iznos kamatne stope, ovo je napravljen kao optimalni argument, postoji način kako preskočiti ovaj argument i koristite preporucenu kamatnu stopu
	Period - Ukoliko ovo koristite na RP serveru, savjetujem vam da ovo gledate na način 'Kroz koliko payday-ova će igrač otplatiti kredit', npr. 5 payday-ova i na taj iznos se računa rata svakog kredita
	Funkcija ne vrača nikakvu vrijednost!

	dajRacun(playerid)
	playerid - ID igrača kojem želite naplatiti ratu kredita, ovu funkciju savjetujem da koristite (ukoliko imate RP server) na mjestu gdje igrač dobiva payday, odmah mu naplatite ukupan iznos dignutih kredita
	Funkcija ne vrača nikakvu vrijednost!
*/

#if defined _kredit_included
	#endinput
#endif
#define _kredit_included

#if !defined _samp_included
	#error "Prvo include-aj a_samp.inc - tek onda include-aj kredit.inc"
#endif

#tryinclude "YSI\y_ini"
#tryinclude "YSI\y_hooks"

#define ENUMERATOR                     enum
#define __VERZIJA                      ("Beta 1.0")
#define INC_PREFIKS(::)                SL@Y_KREDITI_ // Ovo je prefiks koji se koristi samo kako bi vas osigurao o mogućim konfliktima imena naredbi i sl.
#define KREDITIRANJE                   ("Krediti/%s.ini") // Ne zaboravite kreirati u scriptfiles folderu novi folder pod imenom 'Krediti' u protivnom će vam crashati server
#define MAXIMALNO_KREDITA              (2) // Ovo morate paziti kako bi održali ekonomiju svog servera čitavom, savjet je najviše 3 kredita po igraču
#define PREPORUCENA_KAMATNA_STOPA      (8.6) // Moj savjet je da koristite između 5.0 i 10.0 u protivnom će igrač imati veliku kamatu

ENUMERATOR _@KREDIT@_
{
	bool:_KREDIT[MAXIMALNO_KREDITA], // Lista mjesta kredita kojeg je igrač podignuo
	_GLAVNICA[MAXIMALNO_KREDITA], // Lista glavnica posuđenog novca
	Float:_KAMATNA_STOPA[MAXIMALNO_KREDITA], // Lista kamatne stope svakog podignutog kredita
	_VRACENO[MAXIMALNO_KREDITA], // Lista vračenog novca za svaki podignuti kredit
	_RATA[MAXIMALNO_KREDITA], // Iznos svakog 'računa' za svaki podignuti kredit
	_PERIOD[MAXIMALNO_KREDITA] // Period za svaki dignuti kredit za koje će mu doći naplata
};

new
   __KREDIT[MAX_PLAYERS][_@KREDIT@_];
   

// Napomena: Neke varijable imaju dodane vrijednosti, primjer: _PERIOD ili __KREDIT, ova povlaka nije bzvz to je također kako bi vas sačuvao od mogućih konflikata sa ostalim skriptama...

stock rataKredita(const glavnica, const Float:kamatna_stopa, const period)
{
	new
	   Float:rata = (0), Float:kamata = (0);
	kamata = (glavnica*period)*(kamatna_stopa/100);
	rata = ((glavnica+kamata)/period);
	return floatround(rata);
}

stock podignutihKredita(playerid)
{
	new
	    iterator = (0), brojac = (0);
	while(iterator < MAXIMALNO_KREDITA)
	{
	    if(__KREDIT[playerid][_KREDIT][iterator] == true) ++ brojac;
	    ++ iterator;
	}
	return (brojac);
}

stock podigniKredit(playerid, const glavnica, const Float:kamatna_stopa = PREPORUCENA_KAMATNA_STOPA, const period)
{
	if(glavnica <= 0 || kamatna_stopa <= 0 || kamatna_stopa > 20.0 || period <= 2) return \
																						print("#GRESKA ID:1! KREDIT NIJE VALJAN!");
	new
	   ITERATOR_KREDITA = (0), ID_KREDITA = (-1), IME_IGRACA[MAX_PLAYER_NAME] = "\0", Float:kamata = (glavnica*period)*(kamatna_stopa/100);
    GetPlayerName(playerid, IME_IGRACA, MAX_PLAYER_NAME);
	while(ITERATOR_KREDITA < MAXIMALNO_KREDITA)
	{
	    if(__KREDIT[playerid][_KREDIT][ITERATOR_KREDITA] == false)
	    {
			ID_KREDITA = (ITERATOR_KREDITA);
			break;
	    }
	    ++ ITERATOR_KREDITA;
	}
	if(ID_KREDITA == -1) return \
							  printf("#GRESKA ID:2! IGRAC %s NE MOZE DOBITI KREDIT JER IH VEC IMA %d.", IME_IGRACA, MAXIMALNO_KREDITA);
	   
	// IGRAC SMIJE DOBITI KREDIT
    __KREDIT[playerid][_KREDIT][ID_KREDITA] = (true);
    __KREDIT[playerid][_GLAVNICA][ID_KREDITA] = (glavnica);
    __KREDIT[playerid][_KAMATNA_STOPA][ID_KREDITA] = (kamatna_stopa);
    __KREDIT[playerid][_VRACENO][ID_KREDITA] = (0);
    __KREDIT[playerid][_RATA][ID_KREDITA] = rataKredita(glavnica, kamatna_stopa, period);
    __KREDIT[playerid][_PERIOD][ID_KREDITA] = (period);
    GivePlayerMoney(playerid, glavnica);
    // IGRAC JE PODIGNUO KREDIT
    print("[========================[ NOVOSTI IZ BANKE ]========================]");
	printf("#IGRAC %s je podignuo kredit u iznosu od $%d.", IME_IGRACA, glavnica);
	printf("Igrac sada trenutno ima %d dignutih kredita.", podignutihKredita(playerid));
	printf("Igrac ce kredit otplatiti za %d payday-a", period);
	printf("Rata po svakom payday-u ovog kredita kostat ce ga $%d.", rataKredita(glavnica, kamatna_stopa, period));
	printf("Kamata ovog kredita ce ga kostati dodatnih $%d.", floatround(kamata));
	printf("ZAKLJUCNO: Igrac je posudio $%d, a ukupno ce vratiti $%d (kamata uracunata).", glavnica, floatround((glavnica+kamata)));
	print("[====================================================================]");
	INC_PREFIKS(::)updateKredit(playerid);
	return (false);
}

stock dajRacun(playerid)
{
	new
		iterator = (0), racun = (0), Float:provjera = (0.000), IME_IGRACA[MAX_PLAYER_NAME] = "\0";
    GetPlayerName(playerid, IME_IGRACA, MAX_PLAYER_NAME);

	// PRIKUPLJANJE UKUPNE SUME RACUNA ZA KREDITE!
	while(iterator < MAXIMALNO_KREDITA)
	{
	    if(__KREDIT[playerid][_KREDIT][iterator] == true)
	    {
			 __KREDIT[playerid][_VRACENO][iterator] += (__KREDIT[playerid][_RATA][iterator]);
			 racun += (__KREDIT[playerid][_RATA][iterator]);
	    }
	    ++ iterator;
	}
	
	// NAPLATA RACUNA ZA KREDIT
	GivePlayerMoney(playerid, - racun);
	
	// ISKLJUCIVANJE KREDITA AKO JE NEKI UPRAVO OTPLATIO
	iterator = (0);
	while(iterator < MAXIMALNO_KREDITA)
	{
        provjera = (__KREDIT[playerid][_GLAVNICA][iterator]+(__KREDIT[playerid][_GLAVNICA][iterator]*__KREDIT[playerid][_PERIOD][iterator])*(__KREDIT[playerid][_KAMATNA_STOPA][iterator]/100));
	    if(__KREDIT[playerid][_KREDIT][iterator] == true && __KREDIT[playerid][_VRACENO][iterator] >= provjera)
	    {
	        __KREDIT[playerid][_KREDIT][iterator] = (false);
	        __KREDIT[playerid][_GLAVNICA][iterator] = (0);
    		__KREDIT[playerid][_KAMATNA_STOPA][iterator] = (0.0000);
    		__KREDIT[playerid][_VRACENO][iterator] = (0);
    		__KREDIT[playerid][_RATA][iterator] = (0);
    		__KREDIT[playerid][_PERIOD][iterator] = (0);
	        print("[========================[ NOVOSTI IZ BANKE ]========================]");
			printf("#IGRAC %s je upravo otplatio kredit kojeg je digao prije %d payday-a", IME_IGRACA, __KREDIT[playerid][_PERIOD][iterator]);
			print("[====================================================================]");
	    }
	    provjera = (0.000);
	    ++ iterator;
	}
	INC_PREFIKS(::)updateKredit(playerid);
}

stock INC_PREFIKS(::)updateKredit(playerid)
{
    new
	   Data[64] = "\0", IME_IGRACA[MAX_PLAYER_NAME] = "\0";
    GetPlayerName(playerid, IME_IGRACA, MAX_PLAYER_NAME);
    format(Data, (sizeof Data), KREDITIRANJE, IME_IGRACA);
    if(fexist(Data))
	{
	    new INI:KREDIT_ = INI_Open(Data);
    	for(new DIGNUTIH_KREDITA = (0), string[MAX_PLAYER_NAME+5] = "\0"; DIGNUTIH_KREDITA < MAXIMALNO_KREDITA; ++ DIGNUTIH_KREDITA)
    	{
     		format(string, (sizeof string), "DIGNUTI_KREDIT_%d", DIGNUTIH_KREDITA+1);
       		INI_WriteBool(KREDIT_, string, __KREDIT[playerid][_KREDIT][DIGNUTIH_KREDITA]);

	        format(string, (sizeof string), "GLAVNICA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_GLAVNICA][DIGNUTIH_KREDITA]);

	        format(string, (sizeof string), "KAMATNA_STOPA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteFloat(KREDIT_, string, __KREDIT[playerid][_KAMATNA_STOPA][DIGNUTIH_KREDITA]);

	        format(string, (sizeof string), "VRACENO_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_VRACENO][DIGNUTIH_KREDITA]);

	        format(string, (sizeof string), "RATA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_RATA][DIGNUTIH_KREDITA]);

	        format(string, (sizeof string), "PERIOD_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_PERIOD][DIGNUTIH_KREDITA]);
    	}
    	INI_Close(KREDIT_);
	}
}

stock INC_PREFIKS(::)enumReset(playerid)
{
    for(new iterator = (0); iterator < MAXIMALNO_KREDITA; ++ iterator)
   	{
    	__KREDIT[playerid][_KREDIT][iterator] = (false);
     	__KREDIT[playerid][_GLAVNICA][iterator] = (0);
      	__KREDIT[playerid][_KAMATNA_STOPA][iterator] = (0.000);
        __KREDIT[playerid][_VRACENO][iterator] = (0);
        __KREDIT[playerid][_RATA][iterator] = (0);
        __KREDIT[playerid][_PERIOD][iterator] = (0);
    }
	return (true);
}

hook INC_PREFIKS(::)OnPlayerConnect(playerid)
{
	new
	   Data[64] = "\0", IME_IGRACA[MAX_PLAYER_NAME] = "\0";
    GetPlayerName(playerid, IME_IGRACA, MAX_PLAYER_NAME);
    format(Data, (sizeof Data), KREDITIRANJE, IME_IGRACA);
    INC_PREFIKS(::)enumReset(playerid);
    if(fexist(Data)) // Učitaj kredite
    {
         INI_ParseFile(Data, "ucitavanjeKredita", .bExtra = true, .extra = playerid);
	}
	else if(!fexist(Data)) // Kreiraj prostor za kredite igrača
	{
	    new INI:KREDIT_ = INI_Open(Data);
    	for(new DIGNUTIH_KREDITA = (0), string[MAX_PLAYER_NAME+5] = "\0"; DIGNUTIH_KREDITA < MAXIMALNO_KREDITA; ++ DIGNUTIH_KREDITA)
    	{
     		format(string, (sizeof string), "DIGNUTI_KREDIT_%d", DIGNUTIH_KREDITA+1);
       		INI_WriteBool(KREDIT_, string, __KREDIT[playerid][_KREDIT][DIGNUTIH_KREDITA]);
    	        
	        format(string, (sizeof string), "GLAVNICA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_GLAVNICA][DIGNUTIH_KREDITA]);
    	        
	        format(string, (sizeof string), "KAMATNA_STOPA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteFloat(KREDIT_, string, __KREDIT[playerid][_KAMATNA_STOPA][DIGNUTIH_KREDITA]);
    	        
	        format(string, (sizeof string), "VRACENO_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_VRACENO][DIGNUTIH_KREDITA]);
    	        
	        format(string, (sizeof string), "RATA_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_RATA][DIGNUTIH_KREDITA]);
    	        
	        format(string, (sizeof string), "PERIOD_KREDITA_%d", DIGNUTIH_KREDITA+1);
	        INI_WriteInt(KREDIT_, string, __KREDIT[playerid][_PERIOD][DIGNUTIH_KREDITA]);
    	}
    	INI_Close(KREDIT_);
	}
	return (true);
}

forward ucitavanjeKredita(playerid, name[], value[]);
public ucitavanjeKredita(playerid, name[], value[])
{
	for(new DIGNUTIH_KREDITA = (0), string[MAX_PLAYER_NAME+5] = "\0"; DIGNUTIH_KREDITA < MAXIMALNO_KREDITA; ++ DIGNUTIH_KREDITA)
	{
     	format(string, (sizeof string), "DIGNUTI_KREDIT_%d", DIGNUTIH_KREDITA+1);
       	INI_Bool(string, __KREDIT[playerid][_KREDIT][DIGNUTIH_KREDITA]);

	    format(string, (sizeof string), "GLAVNICA_KREDITA_%d", DIGNUTIH_KREDITA+1);
        INI_Int(string, __KREDIT[playerid][_GLAVNICA][DIGNUTIH_KREDITA]);

        format(string, (sizeof string), "KAMATNA_STOPA_KREDITA_%d", DIGNUTIH_KREDITA+1);
        INI_Float(string, __KREDIT[playerid][_KAMATNA_STOPA][DIGNUTIH_KREDITA]);

		format(string, (sizeof string), "VRACENO_KREDITA_%d", DIGNUTIH_KREDITA+1);
  		INI_Int(string, __KREDIT[playerid][_VRACENO][DIGNUTIH_KREDITA]);

		format(string, (sizeof string), "RATA_KREDITA_%d", DIGNUTIH_KREDITA+1);
  		INI_Int(string, __KREDIT[playerid][_RATA][DIGNUTIH_KREDITA]);

		format(string, (sizeof string), "PERIOD_KREDITA_%d", DIGNUTIH_KREDITA+1);
  		INI_Int(string, __KREDIT[playerid][_PERIOD][DIGNUTIH_KREDITA]);
    }
	return (true);
}

hook INC_PREFIKS(::)OnGameModeInit()
{
	print("[===============[ KREDITNI SUSTAV JE USPJESNO UCITAN ]===============]");
	printf("VERZIJA: %s", __VERZIJA);
	print("[====================================================================]");
	return (true);
}
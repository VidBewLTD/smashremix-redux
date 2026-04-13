// MIDI.asm (Fray)
if !{defined __MIDI__} {
define __MIDI__()

// This file extends the music table and defines macros for including new MIDI files.
// It also extends the instrument table and defines macros for including new instruments.
// For converting MIDI files, it's recommended to use GE Editor.
// Tools > Extra Tools > MIDI Tools > Convert Midi to GE Format and Loop

include "OS.asm"

scope MIDI {
    read32 MUSIC_TABLE, "../roms/original.z64", 0x3D768
    variable MUSIC_TABLE_END(MUSIC_TABLE + 0x17C)   // variable containing the current end of the music table
    constant MIDI_BANK(0x3000000)                   // defines the start of the additional MIDI bank
    global variable MIDI_BANK_END(MIDI_BANK)        // variable containing the current end of the MIDI bank
    // These 2 variables will be used in FGM.asm to calculate the correct RAM offset for numerous pointers
    variable midi_count(0x2F)                       // variable containing total number of MIDIs
    variable largest_midi(0)                        // variable containing the largest MIDI size

    variable game_count(0)                          // variable counting the number of games represented by midis

    // @ Description
    // moves the Dream Land midi to our new MIDI bank to clear space for expanding MUSIC_TABLE
    macro move_dream_land_midi() {
        pushvar origin, base

        // define a new offset for the Dream Land MIDI
        origin  MUSIC_TABLE + 0x4
        dw      MIDI_BANK_END - MUSIC_TABLE

        // remove the previous Dream Land MIDI
        origin  MUSIC_TABLE_END
        fill    0x1F40, 0x00

        // insert the Dream Land MIDI and update MIDI_BANK_END
        origin  MIDI_BANK_END
        insert  MIDI_Dream_Land, "../roms/original.z64", MUSIC_TABLE + 0x17C, 0x1F40
        global variable MIDI_BANK_END(origin())

        pullvar base, origin
    }

    // @ Description
    // Defines a game so we can associate midis with games
    // @ Arguments
    // name - name/id
    // title - game title for display
    macro add_game(name, title) {
        evaluate n(game_count)

        global define GAME_{name}({n})
        game_{n}_title:; db {title}, 0x0

        global variable game_count(game_count + 0x1)
    }

    // @ Description
    // adds a MIDI to our new MIDI bank, and the music table
    // @ Arguments
    // file_name - Name of MIDI file
    // random_te - (bool) Default value for Tournament profile
    // random_ne - (bool) Default value for Netplay profile
    // can_toggle - (bool) indicates if this should be toggleable
    // has_title - (bool) indicates if this track has a title string
    // track_title - Name of track
    // track_game - Name of game of origin for track (from add_game)
    // order - Order of the track
    macro insert_midi(file_name, random_te, random_ne, can_toggle, has_title, track_title, track_game, order) {
        pushvar origin, base

        // defines
        define path_MIDI_{file_name}(../src/music/{file_name}.bin)
        evaluate offset_MIDI_{file_name}(MIDI_BANK_END)
        evaluate MIDI_{file_name}_ID((MUSIC_TABLE_END - MUSIC_TABLE) / 0x8)

        global variable midi_count({MIDI_{file_name}_ID} + 0x1)
        global define MIDI_{MIDI_{file_name}_ID}_TE({random_te})
        global define MIDI_{MIDI_{file_name}_ID}_NE({random_ne})
        global define MIDI_{MIDI_{file_name}_ID}_TOGGLE({can_toggle})
        global define MIDI_{MIDI_{file_name}_ID}_TITLE({has_title})
        global define MIDI_{MIDI_{file_name}_ID}_FILE_NAME({file_name})
        global define MIDI_{MIDI_{file_name}_ID}_NAME({track_title})
        global define MIDI_{MIDI_{file_name}_ID}_GAME({track_game})
        global define MIDI_{MIDI_{file_name}_ID}_ORDER({order})
        global define id.{file_name}({MIDI_{file_name}_ID})

        // print message
        print "Added MIDI_{file_name}({path_MIDI_{file_name}}): ", {MIDI_{MIDI_{file_name}_ID}_NAME}, "\n"
        print "ROM Offset: 0x"; OS.print_hex({offset_MIDI_{file_name}}); print "\n"
        print "MIDI_{file_name}_ID: 0x"; OS.print_hex({MIDI_{file_name}_ID}); print "\n"
        print "Sound Test Music ID: ", midi_count, "\n\n"

        // add the new midi to the music table and update MUSIC_TABLE_END
        origin  MUSIC_TABLE_END
        dw      origin_MIDI_{file_name} - MUSIC_TABLE
        dw      MIDI_{file_name}.size
        global variable MUSIC_TABLE_END(origin())

        // insert the MIDI file and update MIDI_BANK_END
        origin  MIDI_BANK_END
        constant origin_MIDI_{file_name}(origin())
        insert  MIDI_{file_name}, "{path_MIDI_{file_name}}"
        OS.align(4)
        global variable MIDI_BANK_END(origin())

        // set the number of songs in MUSIC_TABLE
        origin  MUSIC_TABLE + 0x2
        dh      midi_count

        // update largest MIDI size
        if MIDI_{file_name}.size > largest_midi {
            global variable largest_midi(MIDI_{file_name}.size)
        }

        pullvar base, origin
    }

    // same as insert_midi but from external paths
    macro insert_external_midi(midi_id, file_name, random_te, random_ne, can_toggle, has_title, track_title, track_game, order) {
        pushvar origin, base

        // defines
        define path_MIDI_{midi_id}({file_name}.bin)
        evaluate offset_MIDI_{midi_id}(MIDI_BANK_END)
        evaluate MIDI_{midi_id}_ID((MUSIC_TABLE_END - MUSIC_TABLE) / 0x8)

        global variable midi_count({MIDI_{midi_id}_ID} + 0x1)
        global define MIDI_{MIDI_{midi_id}_ID}_TE({random_te})
        global define MIDI_{MIDI_{midi_id}_ID}_NE({random_ne})
        global define MIDI_{MIDI_{midi_id}_ID}_TOGGLE({can_toggle})
        global define MIDI_{MIDI_{midi_id}_ID}_TITLE({has_title})
        global define MIDI_{MIDI_{midi_id}_ID}_FILE_NAME({midi_id})
        global define MIDI_{MIDI_{midi_id}_ID}_NAME({track_title})
        global define MIDI_{MIDI_{midi_id}_ID}_GAME({track_game})
        global define MIDI_{MIDI_{midi_id}_ID}_ORDER({order})
        global define id.{midi_id}({MIDI_{midi_id}_ID})

        // print message
        print "Added MIDI_{midi_id}({path_MIDI_{midi_id}}): ", {MIDI_{MIDI_{midi_id}_ID}_NAME}, "\n"
        print "ROM Offset: 0x"; OS.print_hex({offset_MIDI_{midi_id}}); print "\n"
        print "MIDI_{midi_id}_ID: 0x"; OS.print_hex({MIDI_{midi_id}_ID}); print "\n"
        print "Sound Test Music ID: ", midi_count, "\n\n"

        // add the new midi to the music table and update MUSIC_TABLE_END
        origin  MUSIC_TABLE_END
        dw      origin_MIDI_{midi_id} - MUSIC_TABLE
        dw      MIDI_{midi_id}.size
        global variable MUSIC_TABLE_END(origin())

        // insert the MIDI file and update MIDI_BANK_END
        origin  MIDI_BANK_END
        constant origin_MIDI_{midi_id}(origin())
        insert  MIDI_{midi_id}, "{path_MIDI_{midi_id}}"
        OS.align(4)
        global variable MIDI_BANK_END(origin())

        // set the number of songs in MUSIC_TABLE
        origin  MUSIC_TABLE + 0x2
        dh      midi_count

        // update largest MIDI size
        if MIDI_{midi_id}.size > largest_midi {
            global variable largest_midi(MIDI_{midi_id}.size)
        }

        pullvar base, origin
    }

    // @ Description
    // adds a toggleable MIDI to our new MIDI bank, and the music table
    // file_name - Name of MIDI file
    // random_te - Default value for Tournament profile
    // random_ne - Default value for Netplay profile
    // track_title - Name of track
    // track_game - Game of origin for track
    macro insert_midi(file_name, random_te, random_ne, track_title, track_game, order) {
        insert_midi({file_name}, {random_te}, {random_ne}, OS.TRUE, OS.TRUE, {track_title}, {track_game}, {order})
    }

    // @ Description
    // adds an extra, unnamed MIDI to our new MIDI bank, and the music table
    // file_name - Name of MIDI file
    macro insert_extra_midi(file_name) {
        insert_midi({file_name}, OS.FALSE, OS.FALSE, OS.FALSE, OS.FALSE, -1, -1, -1)
    }

    // @ Description
    // adds an extra, named MIDI to our new MIDI bank, and the music table
    // file_name - Name of MIDI file
    macro insert_named_extra_midi(file_name, track_title, track_game, order) {
        insert_midi({file_name}, OS.FALSE, OS.FALSE, OS.FALSE, OS.TRUE, {track_title}, {track_game}, {order})
    }

    // define new MIDI bank
    print "=============================== MIDI FILES =============================== \n"
    // print music table offset
    evaluate music_table_offset(MUSIC_TABLE)
    print "Music Table: 0x"; OS.print_hex({music_table_offset}); print "\n"

    // move dream land midi
    move_dream_land_midi()

    // define games
    add_game(smb, "Super Mario Bros.")
    add_game(smb2, "Super Mario Bros. 2")
    add_game(smb3, "Super Mario Bros. 3")
    add_game(sml, "Super Mario Land")
    add_game(smw, "Super Mario World")
    add_game(sm64, "Super Mario 64")
    add_game(b3313, "B3313")
    add_game(sunshine, "Super Mario Sunshine")
    add_game(nsmb, "New Super Mario Bros.")
    add_game(drm, "Dr. Mario")
    add_game(drm64, "Dr. Mario 64")
    add_game(smk, "Super Mario Kart")
    add_game(smkr, "Super Mario Kart R")
    add_game(mk64, "Mario Kart 64")
    add_game(mkds, "Mario Kart DS")
    add_game(marioparty, "Mario Party")
    add_game(marioparty2, "Mario Party 2")
    add_game(mariogolf, "Mario Golf")
    add_game(mariotennis, "Mario Tennis")
    add_game(smrpg, "Super Mario RPG: Legend of the Seven Stars")
    add_game(papermario, "Paper Mario")
    add_game(mariohoops, "Mario Hoops 3-on-3")
    add_game(talentstudio, "Mario Artist: Talent Studio")
    add_game(marioluigi_bis, "Mario and Luigi: Bowser's Inside Story")
    add_game(ddrmm, "Dance Dance Revolution: Mario Mix")
    add_game(yoshis_island, "Super Mario World 2: Yoshi's Island")
    add_game(yoshis_story, "Yoshi's Story")
    add_game(yoshis_island_ds, "Yoshi's Island DS")
    add_game(warioland, "Wario Land: Super Mario Land 3")
    add_game(warioland2, "Wario Land II")
    add_game(warioshake, "Wario Land - Shake It!")
    add_game(warioworld, "Wario World")
    add_game(warioware, "WarioWare, Inc.: Mega Microgame$!")
    add_game(wwtouched, "WarioWare: Touched!")
    add_game(dkarc, "Donkey Kong/Donkey Kong Jr.")
    add_game(dkjr, "Donkey Kong Jr.")
    add_game(dkl, "Donkey Kong Land")
    add_game(dkc, "Donkey Kong Country")
    add_game(dkc2, "Donkey Kong Country 2: Diddy's Kong Quest")
    add_game(dk64, "Donkey Kong 64")
    add_game(dkr, "Diddy Kong Racing")
    add_game(zelda, "The Legend of Zelda")
    add_game(zelda2, "Zelda II: The Adventure of Link")
    add_game(lttp, "The Legend of Zelda: A Link to the Past")
    add_game(awakening, "The Legend of Zelda: Link's Awakening")
    add_game(ocarina, "The Legend of Zelda: Ocarina of Time")
    add_game(majora, "The Legend of Zelda: Majora's Mask")
    add_game(skyward, "The Legend of Zelda: Skyward Sword")
    add_game(metroid, "Metroid")
    add_game(supermetroid, "Super Metroid")
    add_game(metroidprime3, "Metroid Prime 3: Corruption")
    add_game(starfox, "Star Fox")
    add_game(starfox2, "Star Fox 2")
    add_game(starfox64, "Star Fox 64")
    add_game(starfox0, "Star Fox Zero")
    add_game(pokemonred, "Pokemon Red & Blue")
    add_game(pokemongold, "Pokemon Gold & Silver")
    add_game(pokemonruby, "Pokemon Ruby & Sapphire")
    add_game(pokemondiamond, "Pokemon Diamond & Pearl")
    add_game(stadium, "Pokemon Stadium")
    add_game(stadium2, "Pokemon Stadium 2")
    add_game(heypika, "Hey You, Pikachu!")
    add_game(kirbydreamland, "Kirby's Dream Land")
    add_game(kirbyadventure, "Kirby's Adventure")
    add_game(kirbysuperstar, "Kirby Super Star")
    add_game(kirby64, "Kirby 64: The Crystal Shards")
    add_game(kirbyair, "Kirby Air Ride")
    add_game(kirbyreturn, "Kirby's Return to Dream Land")
    add_game(kirbytripledx, "Kirby Triple Deluxe")
    add_game(fzero, "F-Zero")
    add_game(fzero_x, "F-Zero X")
    add_game(fzero_gx, "F-Zero GX")
    add_game(earthbound, "EarthBound")
    add_game(earthboundb, "EarthBound Beginnings")
    add_game(mother3, "Mother 3")
    add_game(ssb, "Super Smash Bros.")
    add_game(ssbr, "Smash Remix")
    add_game(brawl, "Super Smash Bros. Brawl")
    add_game(melee, "Super Smash Bros. Melee")
    add_game(animal_crossing, "Animal Crossing")
    add_game(acww, "Animal Crossing: Wild World")
    add_game(acnewleaf, "Animal Crossing: New Leaf")
    add_game(machrider, "Mach Rider")
    add_game(mischiefmakers, "Mischief Makers")
    add_game(conker, "Conker's Bad Fur Day")
    add_game(banjokazooie, "Banjo-Kazooie")
    add_game(banjo2, "Banjo-Tooie")
    add_game(pd, "Perfect Dark")
    add_game(jetforce, "Jet Force Gemini")
    add_game(goldeneye, "GoldenEye 007")
    add_game(mlb, "Major League Baseball Featuring Ken Griffey Jr.")
    add_game(nbajam, "NBA Jam")
    add_game(mvc, "Marvel vs. Capcom")
    add_game(mvc2, "Marvel vs. Capcom 2")
    add_game(toh, "Tower of Heaven")
    add_game(persona, "Revelations: Persona")
    add_game(persona5, "Persona 5")
    add_game(fire_emblem, "Fire Emblem")
    add_game(fe6, "Fire Emblem: The Binding Blade")
    add_game(fe_gaiden, "Fire Emblem Gaiden")
    add_game(xenoblade, "Xenoblade Chronicles")
    add_game(sonic1, "Sonic the Hedgehog")
    add_game(sonic2, "Sonic the Hedgehog 2")
    add_game(soniccd, "Sonic CD")
    add_game(sonic3, "Sonic the Hedgehog 3")
    add_game(sonicfighters, "Sonic the Fighters")
    add_game(sonicr, "Sonic R")
    add_game(sonicadventure, "Sonic Adventure")
    add_game(sonicadventure2, "Sonic Adventure 2")
    add_game(rhfever, "Rhythm Heaven Fever")
    add_game(chrono, "Chrono Trigger")
    add_game(xenogears, "Xenogears")
    add_game(dragonking, "Dragon King: The Fighting Game")
    add_game(castlevania, "Castlevania")
    add_game(castlevania_2, "Castlevania II: Simon's Quest")
    add_game(castlevania_bloodlines, "Castlevania: Bloodlines")
    add_game(castlevania_sotn, "Castlevania: Symphony of the Night")
    add_game(castlevania_dos, "Castlevania: Dawn of Sorrow")
    add_game(castlevania_rob, "Castlevania: Rondo of Blood")
    add_game(isoccer, "International Superstar Soccer 64")
    add_game(goemon, "Ganbare Goemon")
    add_game(mysticalninja, "Mystical Ninja Starring Goemon")
    add_game(gga, "Goemon's Great Adventure")
    add_game(goepachisuro, "Ganbare Goemon Pachisuro")
    add_game(waverace, "Wave Race 64")
    add_game(quest64, "Quest 64")
    add_game(ogrebattle64, "Ogre Battle 64: Person of Lordly Caliber")
    add_game(ff4, "Final Fantasy IV")
    add_game(ff5, "Final Fantasy V")
    add_game(jackbros, "Jack Bros.")
    add_game(smtif, "Shin Megami Tensei If...")
    add_game(smtiv, "Shin Megami Tensei IV")
    add_game(smtv, "Shin Megami Tensei V")
    add_game(shantae, "Shantae")
    add_game(blastcorps, "Blast Corps")
    add_game(megamanbc, "Megaman: Battle & Chase")
    add_game(megamanscr, "Mega Man Soccer")
    add_game(doom, "DOOM")
    add_game(doom2, "DOOM II: Hell on Earth")
    add_game(dukenukem3d, "Duke Nukem 3D")
    add_game(cavestory, "Cave Story")
    add_game(sbk, "Snowboard Kids")
    add_game(sbk2, "Snowboard Kids 2")
    add_game(2hu6, "Touhou 6: Embodiment of Scarlet Devil")
    add_game(crash, "Crash Bandicoot")
    add_game(crash2, "Crash Bandicoot 2: Cortex Strikes Back")
    add_game(crash3, "Crash Bandicoot: Warped")
    add_game(crash_xs, "Crash Bandicoot: The Huge Adventure")
    add_game(ctr, "Crash Team Racing")
    add_game(dinoplanet, "Dinosaur Planet")
    add_game(marathon2, "Marathon 2: Durandal")
    add_game(ut99, "Unreal Tournament")
    add_game(shovelknight, "Shovel Knight")
    add_game(undertale, "Undertale")
    add_game(deltarune, "Deltarune")
    add_game(snp, "Sin and Punishment")
    add_game(bomberman, "Bomberman 64")
    add_game(bombermanhero, "Bomberman Hero")
    add_game(bombermands, "Bomberman DS")
    add_game(kidicarus, "Kid Icarus")
    add_game(silversurfer, "Silver Surfer")
    add_game(balloonfight, "Balloon Fight")
    add_game(paneldepon, "Panel de Pon")
    add_game(crashbash, "Crash Bash")
    add_game(dream, "Dream: Land of Giants")
    add_game(srr, "Smash Remix Redux")
    add_game(gs, "Golden Sun")
    add_game(geocities, "geocities.com")
    add_game(maomao, "Mao Mao 64")
    add_game(cotl, "Cult of the Lamb")
    add_game(pizzatower, "Pizza Tower")
    add_game(playkids, "PlayKids")
    add_game(tjob, "Playkids: The Joy of Blood")
    add_game(da, "Deadly Arts")
    add_game(lm, "Luigi's Mansion")
    add_game(mickeyusa, "Mickey Speedway USA")
    add_game(ckn, "Chikn Nuggit")
    add_game(dfiles, "The Diamond Files")
    add_game(indigo, "Indigo")
    add_game(scs2, "Super Copper Story 2")
    add_game(megamanx, "Mega Man X")
    add_game(copper, "Upcoming Super Copper Game")
    OS.align(4)

    // insert custom midi files
    insert_midi(GANONDORF_BATTLE, OS.TRUE, OS.TRUE, "Ganondorf Battle", ocarina, 155)
    insert_midi(CORNERIA, OS.TRUE, OS.TRUE, "Corneria", starfox, 76)
    insert_midi(KOKIRI_FOREST, OS.TRUE, OS.TRUE, "Kokiri Forest", ocarina, 194)
    insert_midi(DR_MARIO, OS.TRUE, OS.TRUE, "Fever", drm, 122)
    insert_midi(GAME_CORNER, OS.TRUE, OS.TRUE, "Game Corner", pokemongold, 152)
    insert_midi(SMASHVILLE, OS.TRUE, OS.TRUE, "Town Hall and Tom Nook's Store", acww, 347)
    insert_midi(STONECARVING_CITY, OS.TRUE, OS.TRUE, "Stonecarving City", warioshake, 324)
    insert_midi(FIRST_DESTINATION, OS.TRUE, OS.TRUE, "Final Destination (Melee)", melee, 131)
    insert_midi(COOLCOOLMOUNTAIN, OS.TRUE, OS.TRUE, "Snow Mountain", sm64, 307)
    insert_midi(GODDESSBALLAD, OS.TRUE, OS.TRUE, "Ballad of the Goddess", skyward, 13)
    insert_midi(SARIA, OS.TRUE, OS.TRUE, "Saria's Song", ocarina, 294)
    insert_midi(TOWEROFHEAVEN, OS.TRUE, OS.TRUE, "Luna Ascension", toh, 208)
    insert_midi(FOD, OS.TRUE, OS.TRUE, "Gourmet Race (Melee)", kirbysuperstar, 164)
    insert_midi(MUDA, OS.TRUE, OS.TRUE, "Muda Kingdom", sml, 235)
    insert_midi(MEMENTOS, OS.TRUE, OS.TRUE, "Last Surprise", persona5, 200)
    insert_midi(SPIRAL_MOUNTAIN, OS.TRUE, OS.TRUE, "Spiral Mountain (Ultimate)", banjokazooie, 313)
    insert_midi(N64, OS.TRUE, OS.TRUE, "Water Land", sm64, 371)
    insert_midi(MUTE_CITY, OS.TRUE, OS.TRUE, "Mute City (Brawl)", fzero, 241)
    insert_midi(BATTLEFIELD, OS.TRUE, OS.TRUE, "Battlefield", brawl, 29)
    insert_midi(MADMONSTER, OS.TRUE, OS.TRUE, "Mad Monster Mansion", banjokazooie, 213)
    insert_extra_midi(GANON_VICTORY)
    insert_extra_midi(YOUNGLINK_VICTORY)
    insert_extra_midi(FALCO_VICTORY)
    insert_extra_midi(DRMARIO_VICTORY)
    insert_midi(MELEE_MENU, OS.TRUE, OS.TRUE, "Melee Menu", melee, 223)
    insert_midi(GREEN_GREENS, OS.TRUE, OS.TRUE, "Green Greens", kirbydreamland, 169)
    insert_midi(NORFAIR, OS.TRUE, OS.TRUE, "Brinstar Depths", metroid, 52)
    insert_midi(BOWSERBOSS, OS.TRUE, OS.TRUE, "Koopa's Theme", sm64, 198)
    insert_midi(POKEMON_STADIUM, OS.TRUE, OS.TRUE, "Trainer Battle", pokemonred, 348)
    insert_midi(BOWSERROAD, OS.TRUE, OS.TRUE, "Koopa's Road", sm64, 196)
    insert_midi(BOWSERFINAL, OS.TRUE, OS.TRUE, "Ultimate Koopa", sm64, 355)
    insert_midi(SMB3OVERWORLD, OS.TRUE, OS.TRUE, "Super Mario Bros. 3 (Melee)", smb3, 329)
    insert_midi(DELFINO, OS.TRUE, OS.TRUE, "Delfino Plaza", sunshine, 94)
    insert_midi(VS_KLUNGO, OS.TRUE, OS.TRUE, "Vs. Klungo", banjo2, 365)
    insert_midi(BIG_BLUE, OS.TRUE, OS.TRUE, "Big Blue", fzero, 34)
    insert_extra_midi(DSAMUS_VICTORY)
    insert_midi(ONETT, OS.TRUE, OS.TRUE, "Onett", earthbound, 251)
    insert_midi(ZEBES_LANDING, OS.TRUE, OS.TRUE, "Upper Brinstar", supermetroid, 360)
    insert_midi(FROSTY_VILLAGE, OS.TRUE, OS.TRUE, "Frosty Village", dkr, 145)
    insert_midi(EASTON_KINGDOM, OS.TRUE, OS.TRUE, "Easton Kingdom", sml, 111)
    insert_midi(WING_CAP, OS.TRUE, OS.TRUE, "Powerful Mario", sm64, 273)
    insert_midi(RBY_GYMLEADER, OS.TRUE, OS.TRUE, "Gym Leader Battle", pokemonred, 174)
    insert_midi(KITCHEN_ISLAND, OS.TRUE, OS.TRUE, "Wario Land", warioland, 369)
    insert_midi(GLACIAL, OS.TRUE, OS.TRUE, "River Stage", mvc2, 286)
    insert_midi(DK_RAP, OS.TRUE, OS.TRUE, "DK Rap", dk64, 98)
    insert_extra_midi(WARIO_VICTORY)
    insert_midi(MACHRIDER, OS.TRUE, OS.TRUE, "Mach Rider (Melee)", machrider, 211)
    insert_midi(POKEFLOATS, OS.TRUE, OS.TRUE, "Red & Blue Medley", pokemonred, 281)
    insert_midi(GERUDO_VALLEY, OS.TRUE, OS.TRUE, "Gerudo Valley", ocarina, 156)
    insert_midi(POP_STAR, OS.TRUE, OS.TRUE, "Pop Star", kirby64, 271)
    insert_midi(STAR_WOLF, OS.TRUE, OS.TRUE, "Star Wolf", starfox64, 319)
    insert_midi(STARRING_WARIO, OS.TRUE, OS.TRUE, "Starring Wario!", ddrmm, 321)
    insert_extra_midi(LUCAS_VICTORY)
    insert_midi(POKEMON_CHAMPION, OS.TRUE, OS.TRUE, "Champion Battle", pokemonred, 62)
    insert_midi(ANIMAL_CROSSING, OS.TRUE, OS.TRUE, "Title Theme (Wild World)", acww, 343)
    insert_midi(HYRULE_TEMPLE, OS.TRUE, OS.TRUE, "Temple Theme (Melee)", zelda2, 336)
    insert_midi(POLLYANNA, OS.TRUE, OS.TRUE, "Pollyanna (Melee)", earthboundb, 270)
    insert_midi(SAMBA_DE_COMBO, OS.TRUE, OS.TRUE, "Samba de Combo", mother3, 293)
    insert_midi(PORKY_MEDLEY, OS.TRUE, OS.TRUE, "Master Porky Medley", mother3, 221)
    insert_midi(UNFOUNDED_REVENGE, OS.TRUE, OS.TRUE, "Unfounded Revenge (Brawl)", mother3, 359)
    insert_midi(THE_DAYS_WHEN_MY_MOTHER_WAS_THERE, OS.TRUE, OS.TRUE, "The Days When My Mother Was There", persona5, 338)
    insert_midi(BRAWL, OS.TRUE, OS.TRUE, "Brawl Menu", brawl, 51)
    insert_midi(NBA_JAM, OS.TRUE, OS.TRUE, "NBA Jam Medley", nbajam, 243)
    insert_midi(KENGJR, OS.TRUE, OS.TRUE, "Call Me Jr.", mlb, 59)
    insert_midi(CLOCKTOWER, OS.TRUE, OS.TRUE, "Clock Tower", mvc2, 69)
    insert_midi(BEIN_FRIENDS, OS.TRUE, OS.TRUE, "Bein' Friends", earthboundb, 31)
    insert_midi(KK_RIDER, OS.TRUE, OS.TRUE, "Go K.K. Rider!", animal_crossing, 159)
    insert_midi(SNAKEY_CHANTEY, OS.TRUE, OS.TRUE, "Snakey Chantey", dkc2, 305)
    insert_midi(TAZMILY, OS.TRUE, OS.TRUE, "Mom's Hometown", mother3, 232)
    insert_midi(FLAT_ZONE, OS.TRUE, OS.TRUE, "Flat Zone", melee, 133)
    insert_midi(FLAT_ZONE_2, OS.TRUE, OS.TRUE, "Flat Zone II", brawl, 134)
    insert_midi(YOSHI_GOLF, OS.TRUE, OS.TRUE, "Yoshi's Island (Mario Golf)", mariogolf, 379)
    insert_midi(FINALTEMPLE, OS.TRUE, OS.TRUE, "Great Temple/Dark Link", zelda2, 167)
    insert_midi(OBSTACLE, OS.TRUE, OS.TRUE, "Obstacle Course", yoshis_island, 246)
    insert_midi(EVEN_DRIER_GUYS, OS.TRUE, OS.TRUE, "Even Drier Guys", mother3, 119)
    insert_midi(FZERO_MEDLEY, OS.TRUE, OS.TRUE, "F-Zero Medley", fzero, 148)
    insert_midi(PEACH_CASTLE, OS.TRUE, OS.TRUE, "Princess Peach's Castle (Melee)", smb, 274)
    insert_midi(BANJO_MAIN, OS.TRUE, OS.TRUE, "Main Title (Banjo-Kazooie)", banjokazooie, 217)
    insert_extra_midi(BOWSER_VICTORY)
    insert_midi(MULTIMAN, OS.TRUE, OS.TRUE, "Multi-Man Melee", melee, 236)
    insert_midi(TABUU, OS.TRUE, OS.TRUE, "Boss Battle Song 2", brawl, 47)
    insert_midi(GANGPLANK, OS.TRUE, OS.TRUE, "Gang-Plank Galleon", dkc, 153)
    insert_midi(FD_BRAWL, OS.TRUE, OS.TRUE, "Final Destination (Brawl)", brawl, 130)
    insert_midi(ASTRAL_OBSERVATORY, OS.TRUE, OS.TRUE, "Astral Observatory", majora, 9)
    insert_midi(ARIA_OF_THE_SOUL, OS.TRUE, OS.TRUE, "Aria of the Soul", persona, 7)
    insert_midi(PAPER_MARIO_BATTLE, OS.TRUE, OS.TRUE, "Battle Fanfare", papermario, 23)
    insert_midi(KING_OF_THE_KOOPAS, OS.TRUE, OS.TRUE, "King of the Koopas", papermario, 192)
    insert_midi(MRPATCH, OS.TRUE, OS.TRUE, "Mr. Patch", banjo2, 234)
    insert_midi(SKERRIES, OS.TRUE, OS.TRUE, "Skerries", blastcorps, 302)
    insert_midi(BEWARE_THE_FORESTS_MUSHROOMS, OS.TRUE, OS.TRUE, "Beware the Forest's Mushrooms", smrpg, 32)
    insert_midi(FIGHT_AGAINST_BOWSER, OS.TRUE, OS.TRUE, "Fight Against Bowser", smrpg, 123)
    insert_midi(DKR_BOSS, OS.TRUE, OS.TRUE, "Boss Challenges", dkr, 48)
    insert_midi(CRESCENT_ISLAND, OS.TRUE, OS.TRUE, "Crescent Island", dkr, 82)
    insert_extra_midi(CONKER_VICTORY)
    insert_midi(RITH_ESSA, OS.TRUE, OS.TRUE, "Rith Essa", jetforce, 285)
    insert_midi(TARGET_TEST, OS.TRUE, OS.TRUE, "Targets!", melee, 333)
    insert_midi(VENOM, OS.TRUE, OS.TRUE, "Venom", starfox, 362)
    insert_midi(SURPRISE_ATTACK, OS.TRUE, OS.TRUE, "Surprise Attack", starfox2, 331)
    insert_midi(BK_FINALBATTLE, OS.TRUE, OS.TRUE, "Final Battle (Banjo-Kazooie)", banjokazooie, 128)
    insert_extra_midi(MEWTWO_VICTORY)
    insert_midi(OLE, OS.TRUE, OS.TRUE, "Ole!", conker, 250)
    insert_midi(WINDY, OS.TRUE, OS.TRUE, "Windy and Co.", conker, 376)
    insert_midi(STARFOX_MEDLEY, OS.TRUE, OS.TRUE, "Star Fox Medley (Melee)", starfox, 318)
    insert_midi(DATADYNE, OS.TRUE, OS.TRUE, "dataDyne Central: Defection", pd, 88)
    insert_midi(INVESTIGATION_X, OS.TRUE, OS.TRUE, "dataDyne Central: Investigation X", pd, 89)
    insert_midi(CRADLE, OS.TRUE, OS.TRUE, "Antenna Cradle", goldeneye, 5)
    insert_midi(MM_TITLE, OS.TRUE, OS.TRUE, "Opening Title (Mischief Makers)", mischiefmakers, 254)
    insert_midi(ESPERANCE, OS.TRUE, OS.TRUE, "Esperance", mischiefmakers, 117)
    insert_midi(SLOPRANO, OS.TRUE, OS.TRUE, "Sloprano", conker, 304)
    insert_extra_midi(WOLF_VICTORY)
    insert_midi(NSMB, OS.TRUE, OS.TRUE, "Overworld Theme", nsmb, 261)
    insert_midi(JUNGLEJAPES, OS.TRUE, OS.TRUE, "Jungle Japes (Melee)", dkc, 186)
    insert_midi(FOREST_INTERLUDE, OS.TRUE, OS.TRUE, "Forest Interlude", dkc2, 138)
    insert_midi(TOADS_TURNPIKE, OS.TRUE, OS.TRUE, "Toad's Turnpike", mk64, 344)
    insert_midi(GB_MEDLEY, OS.TRUE, OS.TRUE, "Game Boy Medley", ssbr, 151)
    insert_midi(BUBBLY, OS.TRUE, OS.TRUE, "Bubbly Clouds", kirbydreamland, 55)
    insert_midi(ROADTOCERULEANCITY, OS.TRUE, OS.TRUE, "Road to Cerulean City", pokemonred, 287)
    insert_midi(LEVEL1_WARIO, OS.TRUE, OS.TRUE, "Stage 1 (Wario Land)", warioland, 315)
    insert_midi(MABE, OS.TRUE, OS.TRUE, "Mabe Village", awakening, 210)
    insert_midi(REST, OS.TRUE, OS.TRUE, "Rest Area", ssbr, 283)
    insert_midi(FE_MEDLEY, OS.TRUE, OS.TRUE, "Fire Emblem Medley", fire_emblem, 132)
    insert_midi(YOSHI_TALE, OS.TRUE, OS.TRUE, "Yoshi's Tale", yoshis_story, 381)
    insert_midi(FLOWER_GARDEN, OS.TRUE, OS.TRUE, "Flower Garden", yoshis_island, 135)
    insert_midi(WILDLANDS, OS.TRUE, OS.FALSE, "Wildlands", yoshis_island_ds, 374)
    insert_midi(VS_MARX, OS.FALSE, OS.TRUE, "Vs. Marx", kirbysuperstar, 366)
    insert_extra_midi(MARTH_VICTORY)
    insert_midi(SS_AQUA, OS.TRUE, OS.TRUE, "S.S. Aqua", pokemongold, 292)
    insert_midi(METAL_BATTLE, OS.TRUE, OS.TRUE, "Metal Battle", melee, 228)
    insert_midi(SLIDER, OS.TRUE, OS.TRUE, "Slider", sm64, 303)
    insert_midi(MULTIMAN2, OS.TRUE, OS.TRUE, "Multi-Man Melee 2", melee, 237)
    insert_midi(FIRE_EMBLEM, OS.TRUE, OS.TRUE, "Together We Ride (Melee)", fire_emblem, 346)
    insert_midi(KANTO_WILD_BATTLE, OS.TRUE, OS.TRUE, "Kanto Wild Pokemon Battle", pokemongold, 190)
    insert_midi(SMB2OVERWORLD, OS.TRUE, OS.TRUE, "Super Mario Bros. 2 Overworld", smb2, 328)
    insert_midi(PIRATELAND, OS.TRUE, OS.TRUE, "Pirate Land", marioparty2, 267)
    insert_midi(TROPICALISLAND, OS.TRUE, OS.TRUE, "Yoshi's Tropical Island", marioparty, 382)
    insert_midi(FLYINGBATTERY, OS.TRUE, OS.TRUE, "Flying Battery", sonic3, 136)
    insert_midi(OPEN_YOUR_HEART, OS.TRUE, OS.TRUE, "Open Your Heart", sonicadventure, 252)
    insert_midi(SONIC2_BOSS, OS.TRUE, OS.TRUE, "Sonic 2 Boss", sonic2, 308)
    insert_extra_midi(SONIC_VICTORY)
    insert_midi(CASINO_NIGHT, OS.TRUE, OS.TRUE, "Casino Night Zone", sonic2, 61)
    insert_midi(MONKEY_WATCH, OS.TRUE, OS.TRUE, "Monkey Watch", rhfever, 233)
    insert_midi(SONIC2_SPECIAL, OS.TRUE, OS.TRUE, "Sonic 2 Special Stage", sonic2, 309)
    insert_midi(SONICCD_SPECIAL, OS.TRUE, OS.TRUE, "Sonic CD Special Stage", soniccd, 310)
    insert_midi(GIANTWING, OS.TRUE, OS.TRUE, "Giant Wing", sonicfighters, 158)
    insert_midi(EMERALDHILL, OS.TRUE, OS.TRUE, "Emerald Hill Zone", sonic2, 115)
    insert_midi(LIVE_AND_LEARN, OS.TRUE, OS.TRUE, "Live and Learn", sonicadventure2, 206)
    insert_midi(STARDUST, OS.TRUE, OS.TRUE, "Stardust Speedway B Mix", soniccd, 320)
    insert_midi(GREEN_HILL_ZONE, OS.TRUE, OS.TRUE, "Green Hill Zone", sonic1, 170)
    insert_midi(CHEMICAL_PLANT, OS.TRUE, OS.TRUE, "Chemical Plant Zone", sonic2, 64)
    insert_midi(BABY_BOWSER, OS.TRUE, OS.TRUE, "Baby Bowser", yoshis_island, 12)
    insert_midi(WIDE_UNDERWATER, OS.TRUE, OS.TRUE, "Ocean Medley", marioparty, 248)
    insert_midi(METALLIC_MADNESS, OS.TRUE, OS.TRUE, "Metallic Madness", soniccd, 229)
    insert_midi(EVERYTHING, OS.TRUE, OS.TRUE, "Everything (Super Sonic)", sonicfighters, 120)
    insert_midi(ROCKSOLID, OS.TRUE, OS.TRUE, "Rock Solid", conker, 288)
    insert_midi(RAINBOWROAD, OS.TRUE, OS.TRUE, "Rainbow Road", mk64, 279)
    insert_midi(MK64_CREDITS, OS.TRUE, OS.TRUE, "Victory Lap", mk64, 363)
    insert_midi(RACEWAYS, OS.TRUE, OS.TRUE, "Raceways", mk64, 277)
    insert_midi(LINKS_AWAKENING_MEDLEY, OS.TRUE, OS.TRUE, "Link's Awakening Medley", awakening, 203)
    insert_midi(CORRIDORS_OF_TIME, OS.TRUE, OS.TRUE, "Corridors of Time", chrono, 77)
    insert_midi(KIRBY_64_BOSS, OS.TRUE, OS.TRUE, "Kirby 64 Boss", kirby64, 193)
    insert_midi(WALUIGI_PINBALL, OS.TRUE, OS.TRUE, "Waluigi Pinball", mkds, 368)
    insert_extra_midi(MARINA_VICTORY)
    insert_extra_midi(SHEIK_VICTORY)
    insert_extra_midi(DEDEDE_VICTORY)
    insert_midi(SMB2_MEDLEY, OS.TRUE, OS.TRUE, "Super Mario Bros. 2 Medley", smb2, 327)
    insert_midi(SMW_TITLECREDITS, OS.TRUE, OS.TRUE, "Super Mario World Title/Credits", smw, 330)
    insert_midi(DRAGONKING, OS.TRUE, OS.TRUE, "Dragon King", dragonking, 109)
    insert_midi(DEDEDE, OS.TRUE, OS.TRUE, "King Dedede's Theme", kirbydreamland, 191)
    insert_midi(DRACULAS_CASTLE, OS.TRUE, OS.TRUE, "Dracula's Castle", castlevania_sotn, 107)
    insert_midi(IRON_BLUE_INTENTION, OS.TRUE, OS.TRUE, "Iron-Blue Intention", castlevania_bloodlines, 184)
    insert_midi(DRACULAS_TEARS, OS.TRUE, OS.TRUE, "Dracula's Tears", castlevania_dos, 108)
    insert_midi(WARIOWARE, OS.TRUE, OS.TRUE, "WarioWare, Inc.", warioware, 370)
    insert_midi(BLOODY_TEARS, OS.TRUE, OS.TRUE, "Bloody Tears", castlevania_2, 38)
    insert_midi(FROZEN_HILLSIDE, OS.TRUE, OS.TRUE, "Frozen Hillside", kirbyair, 146)
    insert_midi(MK_REVENGE, OS.TRUE, OS.TRUE, "Meta Knight's Revenge", kirbysuperstar, 227)
    insert_midi(SOCCER_MENU, OS.TRUE, OS.TRUE, "Main Menu (ISS64)", isoccer, 215)
    insert_midi(TROUBLE_MAKER, OS.TRUE, OS.TRUE, "Trouble Maker", mischiefmakers, 351)
    insert_midi(MAIN_MENU2, OS.TRUE, OS.TRUE, "Menu 2 (Melee)", melee, 226)
    insert_midi(WL2_PERFECT, OS.TRUE, OS.TRUE, "Perfect!", warioland2, 264)
    insert_midi(CONTROL, OS.TRUE, OS.TRUE, "Control Center", goldeneye, 75)
    insert_midi(OEDO_EDO, OS.TRUE, OS.TRUE, "Edo Castle Medley", goemon, 113)
    insert_midi(BIS_THEGRANDFINALE, OS.TRUE, OS.TRUE, "In The Final", marioluigi_bis, 182)
    insert_extra_midi(GOEMON_VICTORY)
    insert_midi(MAJORA_MIDBOSS, OS.TRUE, OS.TRUE, "Middle Boss Battle", majora, 231)
    insert_midi(WATCH_THEME, OS.TRUE, OS.TRUE, "Q Watch (Pause Menu)", goldeneye, 275)
    insert_midi(KAI_HIGHWAY, OS.TRUE, OS.TRUE, "Kai Highway", mysticalninja, 188)
    insert_midi(SMW_ATHLETIC, OS.TRUE, OS.TRUE, "Athletic Theme", smw, 10)
    insert_midi(CRATERIA_MAIN, OS.TRUE, OS.TRUE, "Crateria Surface", supermetroid, 80)
    insert_midi(SNES_RAINBOW, OS.TRUE, OS.TRUE, "Rainbow Road (SNES)", smk, 280)
    insert_midi(BRAWL_OOT, OS.TRUE, OS.TRUE, "Ocarina of Time Medley", ocarina, 247)
    insert_midi(BOSS_E, OS.TRUE, OS.TRUE, "Boss E", starfox64, 49)
    insert_midi(MARINE_FORTRESS, OS.TRUE, OS.TRUE, "Marine Fortress", waverace, 219)
    insert_midi(TWILIGHT_CITY, OS.TRUE, OS.TRUE, "Twilight City", waverace, 353)
    insert_midi(SOUTHERNISLAND, OS.TRUE, OS.TRUE, "Southern Island/Main Theme", waverace, 311)
    insert_midi(QUEST64_BATTLE, OS.TRUE, OS.TRUE, "Battle Theme (Quest 64)", quest64, 25)
    insert_midi(MUSICAL_CASTLE, OS.TRUE, OS.TRUE, "Gorgeous Musical Castle", mysticalninja, 162)
    insert_midi(DECISIVE, OS.TRUE, OS.TRUE, "Decisive", ogrebattle64, 92)
    insert_midi(BATTLEFIELDV2, OS.TRUE, OS.TRUE, "Battlefield Ver. 2", brawl, 30)
    insert_midi(BOB, OS.TRUE, OS.TRUE, "Main Theme (Super Mario 64)", sm64, 216)
    insert_midi(AREA6, OS.TRUE, OS.TRUE, "Area 6", starfox64, 6)
    insert_midi(HILLTOPCHASE, OS.TRUE, OS.TRUE, "Hilltop Chase", kirbysuperstar, 176)
    insert_midi(STATUS, OS.TRUE, OS.TRUE, "Status", mariotennis, 322)
    insert_midi(FF4BOSS, OS.TRUE, OS.TRUE, "Boss Encounter", ff4, 50)
    insert_midi(GRIMREAPERSCAVERN, OS.TRUE, OS.TRUE, "Grim Reaper's Cavern", jackbros, 173)
    insert_midi(WORLD_OF_ENVY, OS.TRUE, OS.TRUE, "Shitto Kai / World of Envy", smtif, 299)
    insert_midi(SHANTAEMEDLEY, OS.TRUE, OS.TRUE, "Day/Night Traveling", shantae, 90)
    insert_midi(BURNINGTOWN, OS.TRUE, OS.TRUE, "Burning Town", shantae, 57)
    insert_midi(SHANTAEBOSS, OS.TRUE, OS.TRUE, "Boss Battle (Shantae)", shantae, 45)
    insert_midi(FORTRESS_BOSS, OS.TRUE, OS.TRUE, "Fortress Boss", smw, 139)
    insert_midi(HORROR_LAND, OS.TRUE, OS.TRUE, "Horror Land", marioparty2, 178)
    insert_midi(AC_TITLE, OS.TRUE, OS.TRUE, "Animal Crossing Theme", animal_crossing, 4)
    insert_midi(DARKWORLD, OS.TRUE, OS.TRUE, "Dark World", lttp, 87)
    insert_midi(FILESELECT_SM64, OS.TRUE, OS.TRUE, "File Select", sm64, 125)
    insert_midi(ITSATRAP_SM64, OS.TRUE, OS.TRUE, "File Select (Alternate)", sm64, 126)
    insert_extra_midi(BANJO_VICTORY)
    insert_midi(BLASTCORPS_MENU, OS.TRUE, OS.TRUE, "Menu (Blast Corps)", blastcorps, 225)
    insert_midi(FRAPPE_SNOWLAND, OS.TRUE, OS.TRUE, "Frappe Snowland/Sherbet Land", mk64, 143)
    insert_midi(SMRPG_BATTLE, OS.TRUE, OS.TRUE, "Fight Against Monsters", smrpg, 124)
    insert_midi(TRAVELING, OS.TRUE, OS.TRUE, "Traveling", goepachisuro, 349)
    insert_midi(CHILL, OS.TRUE, OS.TRUE, "Chill", drm, 65)
    insert_midi(ROLL, OS.TRUE, OS.TRUE, "Roll's Theme", megamanbc, 289)
    insert_midi(STICKERBRUSH_SYMPHONY, OS.TRUE, OS.TRUE, "Stickerbrush Symphony", dkc2, 323)
    insert_midi(DOOM1, OS.TRUE, OS.TRUE, "DOOM Medley", doom, 104)
    insert_midi(RUNNING_FROM_EVIL, OS.TRUE, OS.TRUE, "Running From Evil", doom2, 291)
     insert_midi(CONKER_THE_KING, OS.TRUE, OS.TRUE, "Conker the King (Reprise)", conker, 74)
    insert_midi(GRABBAG, OS.TRUE, OS.TRUE, "Grabbag", dukenukem3d, 166)
    insert_midi(WITHMILASDIVINEPROTECTION, OS.TRUE, OS.TRUE, "With Mila's Divine Protection", fe_gaiden, 377)
    insert_midi(DKCTITLE, OS.TRUE, OS.TRUE, "Opening (Donkey Kong)", dkc, 253)
    insert_midi(PLANTATION, OS.TRUE, OS.TRUE, "Plantation", cavestory, 268)
    insert_midi(BATTLE_GOLD_SILVER, OS.TRUE, OS.TRUE, "Gold & Silver Medley", pokemongold, 160)
    insert_midi(BIG_BOO, OS.TRUE, OS.TRUE, "Haunted House", sm64, 175)
    insert_extra_midi(DKING_VICTORY)
    insert_midi(7AM, OS.TRUE, OS.TRUE, "7AM", animal_crossing, 1)
    insert_midi(DKROPTIONS, OS.TRUE, OS.TRUE, "Options (Diddy Kong Racing)", dkr, 255)
    insert_midi(GALLERY, OS.TRUE, OS.TRUE, "Gallery", ssbr, 150)
    insert_midi(QUEQUE, OS.TRUE, OS.TRUE, "Que Que", drm64, 276)
    insert_midi(MK64MENU, OS.TRUE, OS.TRUE, "Setup and Kart Select", mk64, 296)
    insert_midi(GOLDENROD_CITY, OS.TRUE, OS.TRUE, "Goldenrod City", pokemongold, 161)
    insert_midi(CLOCKTOWN, OS.TRUE, OS.TRUE, "Clock Town", majora, 70)
    insert_midi(BUMPERCROPBUMP, OS.TRUE, OS.TRUE, "Bumper Crop Bump", kirby64, 56)
    insert_midi(VSRIDLEY, OS.TRUE, OS.TRUE, "Vs. Ridley", supermetroid, 367)
    insert_midi(GANONMEDLEY, OS.TRUE, OS.TRUE, "Ganon Battle Medley", zelda, 154)
    insert_midi(FUGUE, OS.TRUE, OS.TRUE, "Little Fugue", ssbr, 205)
    insert_midi(NUTTY_NOON, OS.TRUE, OS.TRUE, "Nutty Noon", kirbyreturn, 245)
    insert_midi(GHOSTGULPING, OS.TRUE, OS.TRUE, "Ghost Gulping", papermario, 157)
    insert_midi(SMB2BOSS, OS.TRUE, OS.TRUE, "Super Mario Bros. 2 Boss", smb2, 326)
    insert_midi(FZERO_CLIMBUP, OS.TRUE, OS.TRUE, "Climb Up! And Get the Last Chance!", fzero_x, 68)
    insert_midi(JFG_SELECT, OS.TRUE, OS.TRUE, "Character Select (Jet Force Gemini)", jetforce, 63)
    insert_midi(YOSHI_SKA, OS.TRUE, OS.TRUE, "Yoshi's Song", yoshis_story, 380)
    insert_midi(BOARD_SHOP, OS.TRUE, OS.TRUE, "Board Shop", sbk, 41)
    insert_midi(FLANDRES_THEME, OS.TRUE, OS.TRUE, "U.N. Owen Was Her?", 2hu6, 354)
    insert_midi(NIGHTMARE, OS.TRUE, OS.TRUE, "Final Boss (Nightmare's Battle)", kirbyadventure, 129)
    insert_midi(THE_ALOOF_SOLDIER, OS.TRUE, OS.TRUE, "The Aloof Soldier", gga, 337)
    insert_midi(WENDYS_HOUSE, OS.TRUE, OS.TRUE, "Wendy's House", sbk2, 372)
    insert_midi(DANGEROUS_FOE, OS.TRUE, OS.TRUE, "Battle Against a Dangerous Foe", earthboundb, 18)
    insert_midi(BIG_SNOWMAN, OS.TRUE, OS.TRUE, "Big Snowman", sbk, 36)
    insert_midi(PIKA_CUP, OS.TRUE, OS.TRUE, "Pika Cup Battles 1-3", stadium, 266)
    insert_midi(ASHLEYS_THEME, OS.TRUE, OS.TRUE, "Ashley's Theme", wwtouched, 8)
    insert_midi(SILVER_MOUNTAIN, OS.TRUE, OS.TRUE, "Silver Mountain", sbk, 300)
    insert_midi(WIZPIG, OS.TRUE, OS.TRUE, "Wizpig Challenge", dkr, 378)
    insert_midi(TALENTSTUDIO, OS.TRUE, OS.TRUE, "Talent Studio Medley", talentstudio, 332)
    insert_midi(BATTLE_C1, OS.TRUE, OS.TRUE, "Battle C1", smtiv, 22)
    insert_midi(PLAY_A_MINIGAME, OS.TRUE, OS.TRUE, "Play a Mini-Game!", marioparty, 269)
    insert_midi(CREDITS_BRAWL, OS.TRUE, OS.TRUE, "Credits (Brawl)", ssb, 81)
    insert_extra_midi(CRASH_VICTORY)
    insert_midi(PD_PAUSE, OS.TRUE, OS.TRUE, "Pause Menu (Perfect Dark)", pd, 263)
    insert_extra_midi(PEACH_VICTORY)
    insert_midi(PORKY, OS.TRUE, OS.TRUE, "Porky Means Business!", earthbound, 272)
    insert_midi(UNDERGROUND, OS.TRUE, OS.TRUE, "Underground Theme", smb, 356)
    insert_midi(UNDERGROUND_HURRY, OS.TRUE, OS.TRUE, "Underground Theme (Hurry Up!)", smb, 357)
    insert_midi(CRASH3, OS.TRUE, OS.TRUE, "Time Twister", crash3, 341)
    insert_midi(NSANITYBEACH, OS.TRUE, OS.TRUE, "N. Sanity Beach", crash, 242)
    insert_midi(CTR_MENU, OS.TRUE, OS.TRUE, "Crash Team Racing Menu", ctr, 79)
    insert_midi(DISCOVERYFALLS, OS.TRUE, OS.TRUE, "Discovery Falls", dinoplanet, 97)
    insert_midi(CRASHBONUS, OS.TRUE, OS.TRUE, "Bonus (CB:THA)", crash_xs, 42)
    insert_midi(DK_MEDLEY, OS.TRUE, OS.TRUE, "Donkey Kong Medley", dkarc, 102)
    insert_midi(SM64STAFF, OS.TRUE, OS.TRUE, "Staff Roll (Super Mario 64)", sm64, 314)
    insert_midi(BIG_BRIDGE, OS.TRUE, OS.TRUE, "Clash on the Big Bridge", ff5, 66)
    insert_midi(HOGWILD, OS.TRUE, OS.TRUE, "Hog Wild", crash, 177)
    insert_midi(MARATHON, OS.TRUE, OS.TRUE, "Marathon 2 Title Theme", marathon2, 218)
    insert_midi(FORGONE, OS.TRUE, OS.TRUE, "Foregone Destruction", ut99, 137)
    insert_midi(MORRIGAN, OS.TRUE, OS.TRUE, "Theme of Morrigan", mvc, 340)
    insert_midi(ELADARD, OS.TRUE, OS.TRUE, "Eladard", starfox2, 114)
    insert_midi(MADMAZEMAUL, OS.TRUE, OS.TRUE, "Mad Maze Maul", dk64, 212)
    insert_midi(ORANGSPRINT, OS.TRUE, OS.TRUE, "OrangSprint", dk64, 259)
    insert_midi(DRAKE_LAKE, OS.TRUE, OS.TRUE, "Drake Lake", waverace, 110)
    insert_midi(BUBBLEGUM_KK, OS.TRUE, OS.TRUE, "Bubblegum K.K.", acnewleaf, 54)
    insert_midi(FZEROX_MEDLEY, OS.TRUE, OS.TRUE, "F-Zero X Medley", fzero_x, 149)
    insert_midi(FREEZE, OS.TRUE, OS.TRUE, "Freeze!", papermario, 144)
    insert_midi(TITANIA, OS.TRUE, OS.TRUE, "Titania", starfox, 342)
    insert_midi(THEATER, OS.TRUE, OS.TRUE, "Theater", kirby64, 339)
    insert_midi(ENEMYCARD, OS.TRUE, OS.TRUE, "Enemy Card Index", kirby64, 116)
    insert_midi(SHEVAT, OS.TRUE, OS.TRUE, "Shevat, the Wind is Calling", xenogears, 298)
    insert_midi(CORTEX, OS.TRUE, OS.TRUE, "Dr. Neo Cortex", crash2, 106)
    insert_midi(WILY_FIELD, OS.TRUE, OS.TRUE, "Wily's Field", megamanscr, 375)
    insert_midi(SMS_BOSS, OS.TRUE, OS.TRUE, "Boss Battle (Sunshine)", sunshine, 46)
    insert_midi(COBALT, OS.TRUE, OS.TRUE, "Cobalt Coast", heypika, 71)
    insert_midi(VS_DSAMUS, OS.TRUE, OS.TRUE, "Vs. Dark Samus", metroidprime3, 364)
    insert_midi(STRIKE_THE_EARTH, OS.TRUE, OS.TRUE, "Strike the Earth!", shovelknight, 325)
    insert_midi(VAMPIREKILLER, OS.TRUE, OS.TRUE, "Vampire Killer", castlevania, 361)
    insert_midi(KOOPA_BROS, OS.TRUE, OS.TRUE, "Attack of the Koopa Bros.", papermario, 11)
    insert_midi(REDIAL, OS.TRUE, OS.TRUE, "Redial", bombermanhero, 282)
    insert_midi(AGAVE, OS.TRUE, OS.TRUE, "Agave", snp, 2)
    insert_midi(RAIDBLUE, OS.TRUE, OS.TRUE, "Raid Blue", snp, 278)
    insert_midi(RISKNECK, OS.TRUE, OS.TRUE, "Risk One's Neck", snp, 284)
    insert_midi(SHERBETLAND, OS.TRUE, OS.TRUE, "Sherbet Land", mariohoops, 297)
    insert_midi(DEATH_MOUNTAIN, OS.TRUE, OS.TRUE, "Dark Mountain Forest", lttp, 86)
    insert_midi(BATTLE_AMONG_FRIENDS, OS.TRUE, OS.TRUE, "Battle Among Friends", kirby64, 21)
    insert_midi(BUTTER_BUILDING, OS.TRUE, OS.TRUE, "Butter Building", kirbyadventure, 58)
    insert_midi(MURASAKI, OS.TRUE, OS.TRUE, "Murasaki Forest", mother3, 239)
    insert_midi(SKYWORLD, OS.TRUE, OS.TRUE, "Overworld (Kid Icarus)", kidicarus, 260)
    insert_midi(FE6_MEDLEY, OS.TRUE, OS.TRUE, "Binding Blade Medley", fe6, 37)
    insert_midi(SNOWGO, OS.TRUE, OS.TRUE, "Snow Go", crash2, 306)
    insert_midi(FUTUREFRENZY, OS.TRUE, OS.TRUE, "Future Frenzy", crash3, 147)
    insert_extra_midi(LANKY_VICTORY)
    insert_midi(SILVERSURFER, OS.TRUE, OS.TRUE, "Level 1 (Silver Surfer)", silversurfer, 202)
    insert_midi(OPUS_13, OS.TRUE, OS.TRUE, "Opus 13", castlevania_rob, 258)
    insert_midi(FOURSIDE, OS.TRUE, OS.TRUE, "Fourside", earthbound, 141)
    insert_midi(BALLOONFIGHT, OS.TRUE, OS.TRUE, "Balloon Fight", balloonfight, 14)
    insert_midi(LIPS_THEME, OS.TRUE, OS.TRUE, "Lip's Theme", paneldepon, 204)
    insert_midi(CRASHBASH_LOADING, OS.TRUE, OS.TRUE, "Crash Bash Loading Screen", crashbash, 78)
    insert_midi(TREASURE_TROVE_COVE, OS.TRUE, OS.TRUE, "Treasure Trove Cove", banjokazooie, 350)
    insert_midi(STAGESELBM64, OS.TRUE, OS.TRUE, "Stage Select (Bomberman 64)", bomberman, 316)
    insert_midi(OLDKINGCOAL, OS.TRUE, OS.TRUE, "Old King Coal", banjo2, 249)
    insert_midi(SONIC_R, OS.TRUE, OS.TRUE, "Options (Sonic R)", sonicr, 257)
    insert_midi(GREENGARDEN, OS.TRUE, OS.TRUE, "Green Garden", bomberman, 168)
    insert_midi(BLUE_RESORT, OS.TRUE, OS.TRUE, "Blue Resort", bomberman, 40)
    insert_midi(LOST, OS.TRUE, OS.TRUE, "Lost", dream, 207)
    insert_midi(HORROR_MANOR, OS.TRUE, OS.TRUE, "Horror Manor", warioworld, 179)
    insert_midi(DREAMLANDBETA, OS.TRUE, OS.TRUE, "Gourmet Race (Alternate)", kirbysuperstar, 163)
    insert_midi(BLOOMING_VILLAIN, OS.TRUE, OS.TRUE, "Blooming Villain", persona5, 39)
    insert_midi(ALL_I_NEEDED_WAS_YOU, OS.TRUE, OS.TRUE, "All That I Needed (Was You)", earthboundb, 3)
    insert_midi(PIGGYGUYS, OS.TRUE, OS.TRUE, "Piggy Guys", mother3, 265)
    insert_midi(METAL_CAP, OS.TRUE, OS.TRUE, "Metallic Mario", sm64, 230)
    insert_midi(ELITE_FOUR, OS.TRUE, OS.TRUE, "Battle! Elite Four", pokemonruby, 28)
    insert_midi(TEMPLE_8BIT, OS.TRUE, OS.TRUE, "Temple Theme (8-bit)", zelda2, 335)
    insert_midi(CLICKCLOCKWOODS, OS.TRUE, OS.TRUE, "Click Clock Wood (Spring)", banjokazooie, 67)
    insert_midi(CARRINGTON, OS.TRUE, OS.TRUE, "Carrington Institute", pd, 60)
    insert_midi(KALOS, OS.TRUE, OS.TRUE, "Battle! Champion", pokemonruby, 26)
    insert_midi(CASTLEWALL, OS.TRUE, OS.TRUE, "Inside the Castle Walls", sm64, 183)
    insert_midi(I_BELIEVE_IN_YOU, OS.TRUE, OS.TRUE, "I Believe in You", earthboundb, 180)
    insert_midi(SHOWDOWN, OS.TRUE, OS.TRUE, "Gourmet Race (Piano)", kirbysuperstar, 165)
    insert_midi(DK_RAP_MELEE, OS.TRUE, OS.TRUE, "DK Rap (Melee)", dk64, 99)
    insert_midi(JUNGLEJAPES64, OS.TRUE, OS.TRUE, "Jungle Japes", dk64, 185)
    insert_midi(OLD_SPIRAL_MOUNTAIN, OS.TRUE, OS.TRUE, "Spiral Mountain", banjokazooie, 312)
    insert_midi(OLD_UNFOUNDED_REVENGE, OS.TRUE, OS.TRUE, "Unfounded Revenge", mother3, 358)
    insert_midi(KROOLS_ACID_PUNK, OS.TRUE, OS.TRUE, "K. Rool's Acid Punk", dkl, 187)
    insert_midi(CRUEL, OS.TRUE, OS.TRUE, "Cruel Multi-Man Mode", brawl, 83)
    insert_midi(FIRE_FIELD, OS.TRUE, OS.TRUE, "Feel Our Pain (Fire Field)", fzero_gx, 121)
    insert_midi(DCMC, OS.TRUE, OS.TRUE, "DCMC Performance", mother3, 91)
    insert_midi(NBA_JAM_TEAMSEL, OS.TRUE, OS.TRUE, "Team Select", nbajam, 334)
    insert_midi(NORFAIRMELEE, OS.TRUE, OS.TRUE, "Brinstar Depths (Melee)", metroid, 53)
    insert_midi(OLD_TOWEROFHEAVEN, OS.TRUE, OS.TRUE, "Luna Ascension", toh, 209)
    insert_midi(OLD_BEWARE_THE_FORESTS_MUSHROOMS, OS.TRUE, OS.TRUE, "Beware the Forest's Mushrooms (OG)", smrpg, 33)
    insert_midi(OLD_GREEN_HILL_ZONE, OS.TRUE, OS.TRUE, "Green Hill Zone (OG)", sonic1, 171)
    insert_midi(MASKEDDEDEDE, OS.TRUE, OS.TRUE, "Masked Dedede's Theme", kirbytripledx, 220)
    insert_midi(OLD_MUTE_CITY, OS.TRUE, OS.TRUE, "Mute City", fzero, 240)
    insert_midi(FORTUNA, OS.TRUE, OS.TRUE, "Fortuna", starfox0, 140)
    insert_midi(ROUTE209, OS.TRUE, OS.TRUE, "Route 209", pokemondiamond, 290)
    insert_midi(DANGEROUS_GUYS, OS.TRUE, OS.TRUE, "Dangerous Guys", mother3, 85)
    insert_midi(DK_JR_STAGE, OS.TRUE, OS.TRUE, "Donkey Kong Jr.", dkjr, 101)
    insert_midi(MULTIPLAYER_BATTLE, OS.TRUE, OS.TRUE, "Multiplayer Battle (Bomberman DS)", bombermands, 238)
    insert_midi(BATTLECYRUS, OS.TRUE, OS.TRUE, "Battle! Cyrus", pokemondiamond, 27)
    insert_midi(HUMANSDEMONSAND, OS.TRUE, OS.TRUE, "Battle - Humans, Demons, and...", smtv, 16)
    insert_midi(BASSDRIVE, OS.TRUE, OS.TRUE, "BassDrive.mid", smkr, 15)
    insert_midi(BIG_SHOT, OS.TRUE, OS.TRUE, "BIG SHOT", deltarune, 35)
    insert_midi(CRUMBLINGHALLS, OS.TRUE, OS.TRUE, "Crumbling Castle", b3313, 84)
    insert_midi(DEEPSWIMMING, OS.TRUE, OS.TRUE, "Deep Swimming", b3313, 93)
    insert_midi(DIREDIRELOSS, OS.TRUE, OS.TRUE, "Dire, Dire Loss/Wiggler's Fortress", b3313, 95)
    insert_midi(DIREDIREVICTORY, OS.TRUE, OS.TRUE, "Dire, Dire Victory", b3313, 96)
    insert_midi(DKCOURT, OS.TRUE, OS.TRUE, "Donkey Kong's Court", mariotennis, 103)
    insert_midi(DOWNTOWNCITY, OS.TRUE, OS.TRUE, "Downtown City", b3313, 105)
    insert_midi(E_FORT, OS.TRUE, OS.TRUE, "Eternal Fortress", b3313, 118)
    insert_midi(FILESELECT_B3313, OS.TRUE, OS.TRUE, "File Select (B3313)", b3313, 127)
    insert_midi(4THFLOOR, OS.TRUE, OS.TRUE, "Fourth Floor (Beta)", b3313, 142)
    insert_midi(GRIMGREENFOREST, OS.TRUE, OS.TRUE, "Grim Green Forest", b3313, 172)
    insert_midi(BOWSERAIRSHIP, OS.TRUE, OS.TRUE, "Negative Aura Koopa's Road", b3313, 244)
    insert_midi(BOWSERROOM, OS.TRUE, OS.TRUE, "Koopa's Room", b3313, 197)
    insert_midi(BOWSERPRISON, OS.TRUE, OS.TRUE, "Koopa's Prison", b3313, 195)
    insert_midi(LANCEBATTLE, OS.TRUE, OS.TRUE, "Lance Battle", stadium2, 199)
    insert_midi(MKDSMENU, OS.TRUE, OS.TRUE, "Single-Player Menu (MKDS)", mkds, 301)
    insert_midi(PARALLELLOBBY, OS.TRUE, OS.TRUE, "Parallel Lobby", b3313, 262)
    insert_midi(TOADSTOOLROOM, OS.TRUE, OS.TRUE, "Toadstool's Room", b3313, 345)
    insert_midi(WETTOWN, OS.TRUE, OS.TRUE, "Wet Dry Paradise/Wet Town", b3313, 373)
    insert_midi(YOUWILLKNOWOURNAMES, OS.TRUE, OS.TRUE, "You Will Know Our Names", xenoblade, 383)
    insert_extra_midi(OLD_FALCO_VICTORY)
    insert_midi(EATVIRI, OS.TRUE, OS.TRUE, "Eatviri", srr, 112)
    insert_extra_midi(HOMERUN)
    insert_midi(GSBATTLE, OS.TRUE, OS.TRUE, "Battle (Golden Sun)", gs, 17)
    insert_midi(DIAMONDTHEME, OS.TRUE, OS.TRUE, "MENACE TO SOCIETY", dfiles, 224)
    insert_extra_midi(DMARINA_VICTORY)
    insert_midi(LETS_BE_HEROES, OS.TRUE, OS.TRUE, "Let's Be Heroes", maomao, 201)
    insert_midi(FZGX_OPTIONS, OS.TRUE, OS.TRUE, "Options (F-ZERO GX)", fzero_gx, 256)
    insert_midi(X1_STAGESELECT, OS.TRUE, OS.TRUE, "Stage Select 1", megamanx, 317)
    insert_midi(X1_BOSS, OS.TRUE, OS.TRUE, "Maverick Boss Battle", megamanx, 222)
    insert_midi(DOCKYARD, OS.TRUE, OS.TRUE, "Dockyard", mickeyusa, 100)
    insert_midi(COLORADO, OS.TRUE, OS.TRUE, "Colorado", mickeyusa, 72)
    insert_midi(TRUEFINAL, OS.TRUE, OS.TRUE, "True Final Destination", srr, 352)
    insert_midi(LMBOSS, OS.TRUE, OS.TRUE, "Boss Battle (Luigi's Mansion)", lm, 44)
    insert_midi(MK64DESERT, OS.TRUE, OS.TRUE, "Kalimari Desert", mk64, 189)
    insert_extra_midi(UNKNOWN)
    insert_extra_midi(AUTISMO_VICTORY)
    insert_extra_midi(CHIKN_VICTORY)
    insert_extra_midi(WALUIGI_VICTORY)
    insert_midi(TJOB_BONUS, OS.TRUE, OS.TRUE, "Bonus Stage (TJOB)", tjob, 43)
    insert_midi(COMBO, OS.TRUE, OS.TRUE, "Combo Test", srr, 73)
    insert_midi(ILOVEIT, OS.TRUE, OS.TRUE, "I love It", srr, 181)
    insert_midi(LESHY, OS.TRUE, OS.TRUE, "Battle Against Leshy", cotl, 19)
    insert_extra_midi(REDUXVICTORY)
    insert_midi(COPPER_SELECT, OS.TRUE, OS.TRUE, "Select your Destination", copper, 295)
    insert_midi(DFILES_MENU, OS.TRUE, OS.TRUE, "Main Menu (Diamond Files)", dfiles, 214)
    insert_midi(BATTLE_FOR_LINES, OS.TRUE, OS.TRUE, "Battle for Lines", bomberman, 24)
    insert_midi(BATTLE_AGAINST_SIRIUS, OS.TRUE, OS.TRUE, "Battle Against Sirius", bomberman, 20)

    pushvar origin, base

    // Extend Sound Test Music numbers so we can test in game easier
    origin  0x1883BA
    dh      midi_count
    origin  0x188246
    dh      midi_count - 1
    origin  0x1883C2
    dh      midi_count - 1
    origin  0x1883CE
    dh      midi_count - 1

    pullvar base, origin

    // @ Description
    // Replaces the allocated space for loading music files with a fixed-size block in expansion ram.
    scope replace_midi_block_: {
        OS.patch_start(0x20304, 0x8001F704)
        // replaces a part of the memory allocation routine which calls subroutine 0x8001E5F4 to allocate a fixed-size block equivalent to the largest midi
        // instead of allocating a block of memory, we'll just set the address to midi_memory_block, which is our own fixed-size block that we allocated in expansion ram
        li      v0, midi_memory_block       // v0 = midi_memory_block, originally address of allocated block
        fill 0x8001F724 - pc()              // nop the original memory allocation
        OS.patch_end()
    }

    // @ Description
    // Modifies the routine that maps Sound Test screen choices to BGM IDs
    scope augment_sound_test_music_: {
        OS.patch_start(0x188530, 0x80132160)
        j       augment_sound_test_music_
        nop
        OS.patch_end()

        lui     t0, 0x8013                        // original line 1
        lw      t0, 0x4348(t0)                    // original line 2
        slti    a0, t0, 0x2D                      // check if this is one we added (so >= 0x2D)
        bnez    a0, _normal                       // if (original bgm_id) then skip to _normal
        nop
        // If we're here, then the music ID is > 0x2C which means it's
        // one we added. So we need to set up a1 as the extended music
        // table address and offset:
        li      a1, extended_music_map_table      // a1 = address of extended table
        addiu   t0, t0, -0x002D                   // t0 = slot in extended table
        sll     t1, t0, 0x2                       // t1 = offset for bgm_id in extended table
        addu    a1, a1, t1                        // a1 = adress for bgm_id
        lhu     a1, 0x0002(a1)                    // a1 = bgm_id
        jal     0x80020AB4                        // call play MIDI routine
        nop
        j       0x80132180                        // return
        nop

        _normal:
        j       0x80132168                        // continue with original line 3
        nop
    }

    extended_music_map_table:
    dw     0xA                                    // for some reason originally left of music test
    dw     0xB                                    // for some reason originally left of music test
    define n(0x2F)
    while {n} < midi_count {
        dw      {n}
        evaluate n({n}+1)
    }

    print "========================================================================== \n"

    print "=============================== INSTRUMENTS ============================== \n"

    // Constants and variables related to instruments
    read32 INST_CTL_TABLE, "../roms/original.z64", 0x3D75C                       // CTL_TABLE is the base for a lot of sound related offsets
    constant INST_CTL_TABLE_PC(0x800472D0)                                       // CTL_TABLE is loaded in RAM here
    read32 INST_BANK_MAP_OFFSET, "../roms/original.z64", INST_CTL_TABLE + 0x0004 // INST_BANK_MAP_OFFSET is the offset from CTL to the INST_BANK_MAP
    constant INST_BANK_MAP(INST_CTL_TABLE + INST_BANK_MAP_OFFSET)                // INST_BANK_MAP holds offsets to each instrument
    read32 INST_SAMPLE_DATA, "../roms/original.z64", 0x3D760                     // INST_SAMPLE_DATA is the raw sample data
    variable instrument_count(0x2A)                                              // variable containing the total number of added instruments
    variable current_instrument_sample_count(0)                                  // variable containing number of samples in the current instrument

    // @ Description
    // Adds an instrument sample to be used by the instrument created in the next add_instrument() call
    // name                        - Name of .aifc file of sample (and .bin of loop predictors file if present)
    // attack_time                 - (word) attack time
    // decay_time                  - (word) decay time
    // release_time                - (word) release time
    // attack_volume               - (byte) attack volume
    // decay_volume                - (byte) decay volume
    // vel_min                     - (byte) vel min
    // vel_max                     - (byte) vel max
    // key_min                     - (byte) key min
    // key_max                     - (byte) key max
    // key_base                    - (byte) key base
    // detune                      - (byte) detune
    // sample_pan                  - (byte) sample pan
    // sample_volume               - (byte) sample volume
    // loop_enabled                - (bool) if OS.FALSE, then loop is not enabled, if OS.TRUE then loop is enabled
    // loop_start                  - (word) loop start
    // loop_end                    - (word) loop end
    // loop_count                  - (word) loop count
    // loop_predictors_file_exists - (bool) if OS.TRUE, then loop predictors are in {name}.bin, if OS.FALSE then fill with 0
    macro add_instrument_sample(name, attack_time, decay_time, release_time, attack_volume, decay_volume, vel_min, vel_max, key_min, key_max, key_base, detune, sample_pan, sample_volume, loop_enabled, loop_start, loop_end, loop_count, loop_predictors_file_exists) {
        if current_instrument_sample_count == 0 {
            // increment instrument count
            global variable instrument_count(instrument_count + 1)
        }

        // increment current_instrument_sample_count
        global variable current_instrument_sample_count(current_instrument_sample_count + 1)
        evaluate inst_num(instrument_count)
        evaluate sample_num(current_instrument_sample_count)
        global define SAMPLE_NAME_{inst_num}_{sample_num}({name})
        // Sample length is 2 words too long
        read32 SAMPLE_LENGTH_{inst_num}_{sample_num}, "../src/music/instruments/{SAMPLE_NAME_{inst_num}_{sample_num}}.aifc", 0xF4

        attack_delay_params_{inst_num}_{sample_num}:
        dw      {attack_time}
        dw      {decay_time}
        dw      {release_time}
        db      {attack_volume}
        db      {decay_volume}
        dh      0x0000 // ?

        vel_key_params_{inst_num}_{sample_num}:
        db      {vel_min}
        db      {vel_max}
        db      {key_min}
        db      {key_max}
        db      {key_base}
        db      {detune}
        dh      0x0000 // ?

        instrument_block_{inst_num}_{sample_num}:
        dw      attack_delay_params_{inst_num}_{sample_num} - INST_CTL_TABLE_PC
        dw      vel_key_params_{inst_num}_{sample_num} - INST_CTL_TABLE_PC
        dw      pc() + 0x8 - INST_CTL_TABLE_PC

        db      {sample_pan}
        db      {sample_volume}
        dh      0x0000 // ?

        // insert raw data
        pushvar origin, base
        origin  MIDI_BANK_END
        // I believe loop predictors will be at the end of the file, so I intentionally read a specific length
        constant SAMPLE_RAW_{inst_num}_{sample_num}_origin(origin())
        insert SAMPLE_RAW_{inst_num}_{sample_num}, "../src/music/instruments/{SAMPLE_NAME_{inst_num}_{sample_num}}.aifc", 0x100, SAMPLE_LENGTH_{inst_num}_{sample_num} - 0x0008
        global variable MIDI_BANK_END(origin())
        pullvar base, origin

        dw      SAMPLE_RAW_{inst_num}_{sample_num}_origin - INST_SAMPLE_DATA // pointer to raw data
        dw      SAMPLE_LENGTH_{inst_num}_{sample_num} - 0x0008               // length of raw data
        dw      0x0000 // ?

        if {loop_enabled} == OS.TRUE {
            dw  loop_params_{inst_num}_{sample_num} - INST_CTL_TABLE_PC
        } else {
            dw  0x0000
        }

        dw      predictors_{inst_num}_{sample_num} - INST_CTL_TABLE_PC

        dw      0x0000

        if {loop_enabled} == OS.TRUE {
            loop_params_{inst_num}_{sample_num}:
            dw  {loop_start}
            dw  {loop_end}
            dw  {loop_count}
            // loop predictors - I believe they should be at the end of the .aifc file, but haven't been able to produce a valid one yet
            // ...but n64 sound tool produces them
            if {loop_predictors_file_exists} == OS.TRUE {
                insert "../src/music/instruments/{SAMPLE_NAME_{inst_num}_{sample_num}}.bin"
            } else {
                fill 0x20, 0x0
            }
            dw  0x0000
        }

        predictors_{inst_num}_{sample_num}:
        dw     0x00000002
        dw     0x00000004
        insert SAMPLE_PREDICTORS_{inst_num}_{sample_num}, "../src/music/instruments/{SAMPLE_NAME_{inst_num}_{sample_num}}.aifc", 0x70, 0x80
    }

    // @ Description
    // Adds an instrument consisting of all the instrument samples added since the last add_instrument() call
    // name       - Name of the instrument (for display purposes only)
    // volume     - (byte) volume
    // pan        - (byte) pan
    // priority   - (byte) priority
    // bend_range - (hw) bend range
    // trem_type  - (byte) trem type
    // trem_rate  - (byte) trem rate
    // trem_depth - (byte) trem depth
    // trem_delay - (byte) trem delay
    // vib_type   - (byte) vib type
    // vib_rate   - (byte) vib rate
    // vib_depth  - (byte) vib depth
    // vib_delay  - (byte) vid delay
    macro add_instrument(name, volume, pan, priority, bend_range, trem_type, trem_rate, trem_depth, trem_delay, vib_type, vib_rate, vib_depth, vib_delay) {
        evaluate inst_num(instrument_count)
        global define INST_NAME_{inst_num}({name})
        print "Added {INST_NAME_{inst_num}}\nINST_ID: 0x"; OS.print_hex({inst_num}); print " (", {inst_num},")\nSamples:\n"

        instrument_parameters_{inst_num}:
        db      {volume}
        db      {pan}
        db      {priority}
        db      0x00                               // Gets set to 1 when processed
        db      {trem_type}
        db      {trem_rate}
        db      {trem_depth}
        db      {trem_delay}
        db      {vib_type}
        db      {vib_rate}
        db      {vib_depth}
        db      {vib_delay}
        dh      {bend_range}                       // 0x0064 for most (2 semitones?)
        dh      current_instrument_sample_count

        // pointers to instrument blocks
        define n(1)
        while {n} <= current_instrument_sample_count {
            dw       instrument_block_{inst_num}_{n} - INST_CTL_TABLE_PC
            print " - {SAMPLE_NAME_{inst_num}_{n}}\n"
            evaluate n({n}+1)
        }

        // This is necessary so the next instrument doesn't get jarbled
        OS.align(16)

        // reset current_instrument_sample_count
        global variable current_instrument_sample_count(0)
    }

    // @ Description
    // Moves the instrument bank map so it can be extended
    macro move_instrument_bank_map() {
        evaluate inst_num(instrument_count)

        // Move INST_BANK_MAP so it can be extended
        moved_inst_bank_map:
        global variable moved_inst_bank_map_origin(origin())
        OS.move_segment(INST_BANK_MAP, 0xB8)

        // extend using instrument_count
        define n(0x2B)
        evaluate n({n})
        while {n} <= {inst_num} {
            dw       instrument_parameters_{n} - INST_CTL_TABLE_PC
            evaluate n({n}+1)
        }

        pushvar origin, base

        // Update instrument count
        origin moved_inst_bank_map_origin
        dh      instrument_count + 1

        // Update INST_BANK_MAP_OFFSET to point to new location
        origin INST_CTL_TABLE + 0x0004
        dw      moved_inst_bank_map - INST_CTL_TABLE_PC

        pullvar base, origin
    }

    // This is necessary so the first instrument doesn't get jarbled
    OS.align(16)

    // Add instrument samples, then call add_instrument
    // Add instrument samples, then call add_instrument
    // TODO: Rock out with this organ!
    add_instrument_sample(mk64-organ-1, 0x0, 0x0, 66 * 250, 0x7F, 0x7F, 0x0, 0x7F, 0,  44,  39, 0x0, 0x3F, 0x7E, OS.TRUE, 10513, 24407, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(mk64-organ-2, 0x0, 0x0, 66 * 250, 0x7F, 0x7F, 0x0, 0x7F, 45,  55,  39, 0x0, 0x3F, 0x7E, OS.TRUE, 7854, 16901, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(rock_organ_m3_0, 0x0, 0x0, 66 * 250, 0x7F, 0x7F, 0x0, 0x7F, 56,  78,  67, 0x0, 0x3F, 0x7E, OS.TRUE, 6027, 16305, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(rock_organ_m3_1, 0x0, 0x0, 66 * 250, 0x7F, 0x7F, 0x0, 0x7F, 79,  91,  79, 0x0, 0x3F, 0x7E, OS.TRUE, 3014, 8153, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(rock_organ_m3_2, 0x0, 0x0, 66 * 250, 0x7F, 0x7F, 0x0, 0x7F, 80,  103,  91, 0x0, 0x3F, 0x7E, OS.TRUE, 3014, 8153, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Rock Organ, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Make some cool omninus sounding music with this, or cool backing vocals
    add_instrument_sample(SRJV-Chr-1, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x0, 0x7F,  0, 44, 40, 0x0, 0x3F, 0x7E, OS.TRUE, 1747, 19376, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(SRJV-Chr-2, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x0, 0x7F,  45, 55, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 3563, 19419, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(choir_ahhs-0, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x0, 0x7F,  56, 73 , 65, 0x0, 0x3F, 0x7E, OS.TRUE, 3332, 27392, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(choir_oohs-0, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x00, 0x7F, 74, 87, 75, 0x0, 0x3F, 0x7E, OS.TRUE, 1577, 23930, 0xFFFFFFFF, OS.TRUE)
    add_instrument(Choir Aahs, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Make some cool omninus sounding music with this, or cool backing vocals
    add_instrument_sample(SRJV-Chr-2, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x0, 0x7F,  0, 45, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 3563, 19419, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(SRJV-Chr-3, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x0, 0x7F,  46, 58, 64, 0x0, 0x3F, 0x7E, OS.TRUE, 4679, 20227, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(choir_oohs-0, 0x0, 0x0, 66 * 1754, 0x7F, 0x7F, 0x00, 0x7F, 59, 87, 75, 0x0, 0x3F, 0x7E, OS.TRUE, 1577, 23930, 0xFFFFFFFF, OS.TRUE)
    add_instrument(Choir Oohs, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Do some tasty licks with this one, though preferably with the other one
    add_instrument_sample(slap_bass_alt-0, 0x0, 0x0, 30000, 0x7F, 0x7F, 0x00, 0x7F,  0,  59, 48, 0x0, 0x3F, 0x7E, OS.TRUE, 14767, 17457, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(slap_bass_alt-1, 0x0, 0x0, 30000, 0x7F, 0x7F, 0x00, 0x7F, 60,  71, 60, 0x0, 0x3F, 0x7E, OS.TRUE, 7384, 8729, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(slap_bass_alt-2, 0x0, 0x0, 30000, 0x7F, 0x7F, 0x00, 0x7F, 72,  84, 72, 0x0, 0x3F, 0x7E, OS.TRUE, 3692, 4365, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Slap Bass Stock Alt, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: for these samples, make sure values are correct (assuming we keep this instrument)
    add_instrument_sample(church_organ-1, 0x0, 0x0, 66 * 750, 0x7F, 0x7F, 0x0, 0x7F, 0,  71,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 9158, 29019, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(church_organ-2, 0x0, 0x0, 66 * 750, 0x7F, 0x7F, 0x0, 0x7F, 72, 127, 72, 0x0, 0x3F, 0x7E, OS.TRUE, 5681,  29819, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Church Organ, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // Great for making beach music or can be used for soft bass.
    add_instrument_sample(steel_drum-0, 0x0, 0x004C4B40, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  0,  67,  67, 0x0, 0x3F, 0x7E, OS.TRUE, 17025, 23941, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(steel_drum-1, 0x0, 0x004C4B40, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 68, 127,  73, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 0, 0, OS.FALSE)
    add_instrument(Steel Drum, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Make any song that uses this instrument super awesome
    add_instrument_sample(distortion_guitar-1, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 0,   42, 40, 0x0, 0x3F, 0x7E, OS.TRUE, 0x3383, 0x677A, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-2, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 43,  48, 46, 0x0, 0x3F, 0x7E, OS.TRUE, 0x3333, 0x6686, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-3, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 49,  53, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 0x3477, 0x684C, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-4, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 54,  56, 55, 0x0, 0x3F, 0x7E, OS.TRUE,  25728,  43833, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-5, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 57,  58, 57, 0x0, 0x3F, 0x7E, OS.TRUE,  18720,  32281, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-6, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 59,  63, 62, 0x0, 0x3F, 0x7E, OS.TRUE,  21316,  38963, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-7, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 64,  65, 64, 0x0, 0x3F, 0x7E, OS.TRUE,  19328,  33677, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-8, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 66,  70, 69, 0x0, 0x3F, 0x7E, OS.TRUE,  16440,  34582, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-9, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 71,  72, 71, 0x0, 0x3F, 0x7E, OS.TRUE,  18103,  34658, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-10, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 73, 77, 76, 0x0, 0x3F, 0x7E, OS.TRUE,  23267,  38174, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-11, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 78, 82, 81, 0x0, 0x3F, 0x7E, OS.TRUE,  23150,  41842, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-12, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 83, 94, 83, 0x0, 0x3F, 0x7E, OS.TRUE,  20992,  34624, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(distortion_guitar-13, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 95, 107, 95, 0x0, 0x3F, 0x7E, OS.TRUE, 6693,  14295, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Distortion Guitar, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x80, 0xF1, 0x64, 0x01)

    // Great for sexiness
    add_instrument_sample(saxophone-1, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F,  0,  51, 60, 0x0, 0x3F, 0x7E, OS.TRUE, 1433, 1555, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saxophone-2, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F, 52, 54, 64, 0x0, 0x3F, 0x7E, OS.TRUE, 1512, 1609, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saxophone-3, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F, 55, 57, 57, 0x0, 0x3F, 0x7E, OS.TRUE, 7430, 12812, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saxophone-4, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F, 58, 75, 64, 0x0, 0x3F, 0x7E, OS.TRUE, 8100, 8585, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saxophone-5, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F, 76, 88, 76, 0x0, 0x3F, 0x7E, OS.TRUE, 9527, 9866, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saxophone-6, 0x0, 0x001E8480, 66 * 300, 0x7F, 0x0, 0x00, 0x7F, 89, 101, 89, 0x0, 0x3F, 0x7E, OS.TRUE, 1365, 2602, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Tenor Saxophone, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Make any song that uses this instrument super awesome
    add_instrument_sample(marshall-1, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 0,  46,  45, 0x0, 0x3F, 0x7E, OS.TRUE, 20416, 35501, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(marshall-2, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 47, 49,  48, 0x0, 0x3F, 0x7E, OS.TRUE, 20480, 34605, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(marshall-3, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 50, 55,  53, 0x0, 0x3F, 0x7E, OS.TRUE, 19925, 34199, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-0, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 56,  59,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 39088, 66074, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-1, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 60, 64,  64, 0x0, 0x3F, 0x7E, OS.TRUE, 23395, 44703, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-2, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 65, 70,  69, 0x0, 0x3F, 0x7E, OS.TRUE, 14699, 27490, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-3, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 71, 74,  73, 0x0, 0x3F, 0x7E, OS.TRUE, 19841, 32444, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-4, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 75, 78,  77, 0x0, 0x3F, 0x7E, OS.TRUE, 18937, 31235, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(overdriven_guitar-5, 0x0, 0x002DC6C0, 66 * 350, 0x7F, 0x0, 0x0, 0x7F, 79, 100, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 10849, 18728, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Overdriven Guitar, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // This is our Piano that we all know right now. Can be used on classical, or etc..
    add_instrument_sample(jv_piano-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  44,  40, 0x0, 0x3F, 0x7E, OS.TRUE, 9059, 18754, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(jv_piano-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 45, 57,  52, 0x0, 0x3F, 0x7E, OS.TRUE, 6457, 13248, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(jv_piano-3, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 58, 70, 64,  0x0, 0x3F, 0x7E, OS.TRUE, 6140, 12336, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(jv_piano-4, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 71, 81, 76,  0x0, 0x3F, 0x7E, OS.TRUE, 6440, 12929, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(jv_piano-5, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 82, 100, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 9254, 13257, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(jv_piano-6, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 94, 112, 100, 0x0, 0x3F, 0x7E, OS.TRUE, 11103, 13872, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Piano, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Do some tasty licks with this one.
    add_instrument_sample(slap_bass-1, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 0,  39,  28, 0x0, 0x3F, 0x7E, OS.TRUE, 24607, 36249, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(slap_bass-2, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 40, 51, 40, 0x0, 0x3F, 0x7E, OS.TRUE, 9445,  21094, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(slap_bass-3, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 52, 64, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 9445,  21094, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Slap Bass, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Use if a big impact!
    add_instrument_sample(orchestral_hit-1, 0x0, 0x000F4240, 66 * 3000, 0x7F, 0x0, 0x0, 0x7F, 0,  127,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 12273, 18432, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Orchestral Hit, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Extending the Synth Brass sample even more.
    add_instrument_sample(synth_alt-1, 0x0, 0x0, 66 * 150, 0x7F, 0x7F, 0x0, 0x7F, 0,  127,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 2797, 4798, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Synth Alt, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: for NES type music and chiptune. Though Perfect Square PCM is louder and an actual square.
    add_instrument_sample(square_25-1, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F,  0,  45,  36, 0x0, 0x3F, 0x7E, OS.TRUE,  8474, 38310, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(square_25-2, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 46,  57,  48, 0x0, 0x3F, 0x7E, OS.TRUE, 10667, 28738, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(square_25-3, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 58,  69,  60, 0x0, 0x3F, 0x7E, OS.TRUE,  3933, 22004, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(square_25-4, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 70,  81,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  5321, 26994, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(square_25-5, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 82,  93,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 10505, 23112, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(square_25-6, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 94, 127,  96, 0x0, 0x3F, 0x7E, OS.TRUE,  5252, 11556, 0xFFFFFFFF, OS.FALSE)
    add_instrument(NES Square Wave 25P, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    add_instrument_sample(banjo_2_alt-0, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F,  0,  71, 60, 0x0, 0x3F, 0x7E, OS.TRUE, 8453, 11392, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(banjo_2_alt-1, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F, 72,  83, 72, 0x0, 0x3F, 0x7E, OS.TRUE, 4227, 5696, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(banjo_2_alt-2, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F, 84,  96, 84, 0x0, 0x3F, 0x7E, OS.TRUE, 2114, 2848, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Nylon Alt, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Make some synthy sounding tracks
    add_instrument_sample(sawtoothK64_1, 0x0, 0x0, 66 * 200, 0x7F, 0x7F, 0x00, 0x7F, 0, 71, 60, -15, 0x3F, 0x7E, OS.TRUE, 12440, 26687, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(sawtoothK64_2, 0x0, 0x0, 66 * 200, 0x7F, 0x7F, 0x00, 0x7F, 72, 83, 72, -5, 0x3F, 0x7E, OS.TRUE, 12808, 27679, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(sawtoothK64_3, 0x0, 0x0, 66 * 200, 0x7F, 0x7F, 0x00, 0x7F, 84, 127, 84, -10, 0x3F, 0x7E, OS.TRUE, 13329, 20767, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Sawtooth Kirby 64, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: For big moments with guitars
    add_instrument_sample(guitar_slide-0, 0x0, 0x0, 66 * 200, 0x7F, 0x7F, 0x00, 0x7F, 0, 71, 60, -15, 0x3F, 0x7E, OS.TRUE, 12440, 26687, 0xFFFFFFFF, OS.FALSE)
    add_instrument(MOTHER 3 Shogo Sakai Guitar Slide, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Member loop predictors? I member.
    add_instrument_sample(oot_acoustic-1, 0x0, 0x002191C0, 32700, 0x7F, 0x50, 0x0, 0x7F, 0,  66,  56, 0x0, 0x3F, 0x7E, OS.TRUE, 21110, 29276, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(oot_acoustic-2, 0x0, 0x002191C0, 32700, 0x7F, 0x50, 0x0, 0x7F, 67,  87,  75, 0x0, 0x3F, 0x7E, OS.TRUE, 16035, 19171, 0xFFFFFFFF, OS.TRUE)
    add_instrument(OOT Acoustic, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: For invoking lots of emotion
    add_instrument_sample(pizzicato_ffxi-1, 0x0, 0x004C4B40, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  0,  77,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(pizzicato_ffxi-2, 0x0, 0x004C4B40, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 78,  95,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(pizzicato_ffxi-3, 0x0, 0x004C4B40, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 96, 127,  96, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 0, 0, OS.FALSE)
    add_instrument(Pizzicato FFXI, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Rename to the "Jamie Jamieson"
    add_instrument_sample(jamisen-1, 0x0, 0x002625A0, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  0,  73,  79, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(jamisen-2, 0x0, 0x00249F00, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 74,  88,  91, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(jamisen-3, 0x0, 0x001B7740, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 89,  115,  103, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Shamisen, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Cry about the fact this takes up 1.1MB of ROM space
    add_instrument_sample(herewego,  0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  0,  0,  12, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0000, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  1,  1,  13, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0001, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  2,  2,  14, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0002, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  3,  3,  15, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0003, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  4,  4,  16, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0004, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  5,  5,  17, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0005, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  6,  6,  18, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0006, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  7,  7,  19, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0007, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  8,  8,  20, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0008, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  9,  9,  21, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0009, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 10, 10,  22, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0010, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 11, 11,  23, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0011, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 12, 12,  24, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0012, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 13, 13,  25, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0013, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 14, 14,  26, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0014, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 15, 15,  27, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0015, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 16, 16,  28, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0016, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 17, 17,  29, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0017, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 18, 18,  30, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0018, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 19, 19,  31, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0019, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 20, 20,  32, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0020, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 21, 21,  33, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0021, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 22, 22,  34, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0022, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 23, 23,  35, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0023, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 24, 24,  36, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0024, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 25, 25,  37, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0025, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 26, 26,  38, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0026, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 27, 27,  39, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0027, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 28, 28,  40, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0028, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 29, 29,  41, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0029, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 30, 30,  42, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0030, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 31, 31,  43, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0031, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 32, 32,  44, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0032, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 33, 33,  45, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0033, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 34, 34,  46, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0034, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 35, 35,  47, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0035, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 36, 36,  48, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0036, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 37, 37,  49, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0037, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 38, 38,  50, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0038, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 39, 39,  51, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0039, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 40, 40,  52, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0040, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 41, 41,  53, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0041, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 42, 42,  54, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0042, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 43, 43,  55, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0043, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 44, 44,  56, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0044, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 45, 45,  57, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0045, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 46, 46,  58, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0046, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 47, 47,  59, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0047, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 48, 48,  60, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0048, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 49, 49,  61, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0049, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 50, 50,  62, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0050, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 51, 51,  63, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0051, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 52, 52,  64, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0052, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 53, 53,  65, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0053, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 54, 54,  66, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0054, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 55, 55,  67, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0055, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 56, 56,  68, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0056, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 57, 57,  69, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0057, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 58, 58,  70, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0058, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 59, 59,  71, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0059, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 60, 60,  72, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0060, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 61, 61,  73, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0061, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 62, 62,  74, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0062, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 63, 63,  75, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0063, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 64, 64,  76, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0064, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 65, 65,  77, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0065, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 66, 66,  78, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0067, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 67, 67,  79, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0068, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 68, 68,  80, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0069, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 69, 69,  81, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0070, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 70, 70,  82, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0071, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 71, 71,  83, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0072, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 72, 72,  84, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0073, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 73, 73,  85, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0074, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 74, 74,  86, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0075, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 75, 75,  87, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0076, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 76, 76,  88, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0077, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 77, 77,  89, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0078, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 78, 78,  90, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0079, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 79, 79,  91, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0080, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 80, 80,  92, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0081, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 81, 81,  93, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0082, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 82, 82,  94, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0083, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 83, 83,  95, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(lyric0084, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 84, 84,  96, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(sfx1,      0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 85, 85,  97, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(sfx2,      0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 86, 86,  98, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(sfx3,      0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 87, 87,  99, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(sfx4,      0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 88, 88, 100, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(DK_Rap, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)


    // TODO: be ecstatic its only 357k
    add_instrument_sample(roll-1, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  24,  24,  36, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-2, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  25,  25,  37, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-3, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  26,  26,  38, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-4, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  27,  27,  39, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-5, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  28,  28,  40, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-6, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  29,  29,  41, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-7, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  30,  30,  42, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-8, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  31,  31,  43, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-9, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  32,  32,  44, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-10, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  33,  33,  45, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-11, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  34,  34,  46, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-12, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  35,  35,  47, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-13, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  36,  36,  48, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-14, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  37,  37,  49, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-15, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  38,  38,  50, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-16, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  39,  39,  51, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-17, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  40,  40,  52, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-18, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  41,  41,  53, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-19, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  42,  42,  54, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-20, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  43,  43,  55, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-21, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  44,  44,  56, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-22, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  45,  45,  57, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-23, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  46,  46,  58, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-24, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  47,  47,  59, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-25, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  48,  48,  60, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-26, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  49,  49,  61, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-27, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  50,  50,  62, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(roll-28, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  51,  51,  63, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Roll, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Eat Apples
    add_instrument_sample(yoshi1, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  0,  28,  36, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(yoshi2, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  29, 40,  48, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(yoshi3, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  41, 72,  60, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Yoshis, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Marimba on these fools.
    add_instrument_sample(marimba-0, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  0,  54,  72, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(marimba-1, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  55,  64,  55, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(marimba-2, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 65,  77,  67, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(marimba-3, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 78,  91,  79, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(marimba-4, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 89,  103, 91, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Marimba, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Use these samples for a single song and never touch them again
    add_instrument_sample(DFChant1, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 60,  60,  72, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(DFChant2, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 61,  61,  73, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(DFChant3, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 62,  62,  74, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(DFChant4, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 63,  75,  75, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(DF_Chants, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

	// TODO: Oook ookie ook hoo hoo haa hoa and hoo ookie ook hoo
    add_instrument_sample(Monkey01, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 44,  44,  62, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey02, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 45,  45,  63, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey03, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 46,  50,  64, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey04, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 56,  56,  80, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey05, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 57,  57,  81, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey06, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 58,  58,  77, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey07, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 59,  59,  71, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey08, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 60,  60,  72, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey09, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 61,  61,  72, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(Monkey10, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F, 62,  80,  74, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Monkey, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: send John 1 million dollars
    add_instrument_sample(sine-1, 14000, 0x0, 7530, 0x7F, 0x7F, 0x0, 0x7F,  0, 95, 84, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 948, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(sine-2, 14000, 0x0, 7530, 0x7F, 0x7F, 0x0, 0x7F,  96, 107, 96, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 1162, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(sine-3, 14000, 0x0, 7530, 0x7F, 0x7F, 0x0, 0x7F,  108, 120, 108, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 925, 0xFFFFFFFF, OS.TRUE)
    add_instrument(Sine Wave, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: add a lil bit of blbldlldldldding to some bomberman music or something idk
    add_instrument_sample(bass_harp, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  0,  53,  65, 0x0, 0x3F, 0x7E, OS.TRUE, 18640, 27174, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(harp-0, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  54,  63,  62, 0x0, 0x3F, 0x7E, OS.TRUE, 26427, 46666, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(harp-0_5, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  64,  69,  67, 0x0, 0x3F, 0x7E, OS.TRUE, 17517, 21903, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(harp-1, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  70,  81,  74, 0x0, 0x3F, 0x7E, OS.TRUE, 10241, 15489, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(harp-2, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 82,  94,  86, 0x0, 0x3F, 0x7E, OS.TRUE, 5203, 9797, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(harp-3, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 95, 127,  98, 0x0, 0x3F, 0x7E, OS.TRUE, 5099, 10311, 0xFFFFFFFF, OS.TRUE)
    add_instrument(Harp, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // Probably good for latin styled music or something, idfk, idgaf.
    add_instrument_sample(an_bright_piano-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  44,  40, 0x0, 0x3F, 0x7E, OS.TRUE, 7885, 17579, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_bright_piano-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 45, 57,  52, 0x0, 0x3F, 0x7E, OS.TRUE, 5984, 12774, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_bright_piano-3, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 58, 70, 64,  0x0, 0x3F, 0x7E, OS.TRUE, 5731, 11927, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_bright_piano-4, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 71, 81, 76,  0x0, 0x3F, 0x7E, OS.TRUE, 5909, 12397, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_bright_piano-5, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 82, 100, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 8373, 12787, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_bright_piano-6, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 94, 112, 100, 0x0, 0x3F, 0x7E, OS.TRUE, 11103, 13872, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Bright Piano, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // An electric version of the Piano. Just better that's all.
    add_instrument_sample(an_elect_grand-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  44,  40, 0x0, 0x3F, 0x7E, OS.TRUE, 7885, 17579, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_elect_grand-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 45, 57,  52, 0x0, 0x3F, 0x7E, OS.TRUE, 5984, 12774, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_elect_grand-3, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 58, 70, 64,  0x0, 0x3F, 0x7E, OS.TRUE, 5731, 11927, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_elect_grand-4, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 71, 81, 76,  0x0, 0x3F, 0x7E, OS.TRUE, 5909, 12397, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_elect_grand-5, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 82, 100, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 8373, 12787, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_elect_grand-6, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 94, 112, 100, 0x0, 0x3F, 0x7E, OS.TRUE, 11103, 13872, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Electric Grand Piano, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // This was a catchy instrument from Alexis Nevarez. Very western indeed.
    add_instrument_sample(an_honky_tonk-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  44,  40, 0x0, 0x3F, 0x7E, OS.TRUE, 7885, 17579, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_honky_tonk-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 45, 57,  52, 0x0, 0x3F, 0x7E, OS.TRUE, 5984, 12774, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_honky_tonk-3, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 58, 70, 64,  0x0, 0x3F, 0x7E, OS.TRUE, 5731, 11927, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_honky_tonk-4, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 71, 81, 76,  0x0, 0x3F, 0x7E, OS.TRUE, 5909, 12397, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_honky_tonk-5, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 82, 100, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 8373, 12787, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_honky_tonk-6, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 94, 112, 100, 0x0, 0x3F, 0x7E, OS.TRUE, 11103, 13872, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Honky Tonk, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // The grandfather of the Piano. Can be used as a strong stringy bass too.
    add_instrument_sample(an_hpchrd-1, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 0, 35,  43, 0x0, 0x3F, 0x7E, OS.TRUE, 23121, 31352, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-2, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 36, 39, 48, 0x0, 0x3F, 0x7E, OS.TRUE, 20689, 29287, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-3, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 40, 47, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 21357, 30872, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-4, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 48, 54,  60, 0x0, 0x3F, 0x7E, OS.TRUE, 21224, 29787, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-5, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 55, 59, 67, 0x0, 0x3F, 0x7E, OS.TRUE, 24345, 31693, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-6, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 60, 63, 72, 0x0, 0x3F, 0x7E, OS.TRUE, 22610, 29828, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-7, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 64, 65, 76, 0x0, 0x3F, 0x7E, OS.TRUE, 23456, 31611, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-8, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 66, 67, 79, 0x0, 0x3F, 0x7E, OS.TRUE, 20311, 30598, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-9, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 68, 71, 81, 0x0, 0x3F, 0x7E, OS.TRUE, 19744, 31454, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-10, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 72, 78, 88, 0x0, 0x3F, 0x7E, OS.TRUE, 20281, 29941, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-11, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 79, 85, 96, 0x0, 0x3F, 0x7E, OS.TRUE, 13711, 17855, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-12, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 86, 89, 100, 0x0, 0x3F, 0x7E, OS.TRUE, 28254, 31785, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_hpchrd-13, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 90, 127, 108, 0x0, 0x3F, 0x7E, OS.TRUE, 8980, 14115, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Harpsichord, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // Tasty lick keyboard go brrrr lmfao
    add_instrument_sample(an_clav-1, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 0, 36, 36, 0x0, 0x3F, 0x7E, OS.TRUE, 21456, 22922, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-2, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 37, 40, 40, 0x0, 0x3F, 0x7E, OS.TRUE, 22231, 23009, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-3, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 41, 48, 48, 0x0, 0x3F, 0x7E, OS.TRUE, 22580, 23557, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-4, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 49, 52, 52, 0x0, 0x3F, 0x7E, OS.TRUE, 20550, 21132, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-5, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 53, 55, 55, 0x0, 0x3F, 0x7E, OS.TRUE, 25662, 26314, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-6, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 56, 60, 60, 0x0, 0x3F, 0x7E, OS.TRUE, 25790, 25912, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-7, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 61, 64, 64, 0x0, 0x3F, 0x7E, OS.TRUE, 19097, 19291, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-8, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 65, 67, 67, 0x0, 0x3F, 0x7E, OS.TRUE, 20947, 21029, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-9, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 68, 72, 72, 0x0, 0x3F, 0x7E, OS.TRUE, 20606, 20728, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-10, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 73, 76, 76, 0x0, 0x3F, 0x7E, OS.TRUE, 11383, 11480, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-11, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 77, 79, 79, 0x0, 0x3F, 0x7E, OS.TRUE, 16587,  16668, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_clav-12, 0x0, 0x0, 66 * 500, 0x7F, 0x7F, 0x0, 0x7F, 80, 127, 84, 0x0, 0x3F, 0x7E, OS.TRUE, 23210, 23271, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Clav, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // Honey why is our clavinet on fire!?!
    add_instrument_sample(burning_clav-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  70,  58, 0x0, 0x3F, 0x7E, OS.TRUE, 11306, 14843, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Burning Clav, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // You can now play as Mad Piano! NOM!
    add_instrument_sample(mad-piano-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  71,  60, 0x0, 0x3F, 0x7E, OS.TRUE, 17548, 26563, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(mad-piano-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 72,  83,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 9531, 13745, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(mad-piano-3, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 84,  96,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 4219, 6325, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Mad Piano, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: I hope this scares you because it only has one sample.
    add_instrument_sample(infinite-one, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  0,  107,  96, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(Infinite One, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Just a pure CAPCOM classic
    add_instrument_sample(Vibra_C3, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  0,  59,  48, 0x0, 0x3F, 0x7E, OS.TRUE, 9459, 9705, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(Vibra_C4, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F,  60,  71,  60, 0x0, 0x3F, 0x7E, OS.TRUE, 8490, 8613, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(Vibra_C5, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 72,  83,  72, 0x0, 0x3F, 0x7E, OS.TRUE, 3045, 3534, 0xFFFFFFFF, OS.TRUE)
    add_instrument_sample(Vibra_C6, 0x0, 700000, 66 * 1879, 0x7F, 0x0, 0x0, 0x7F, 84, 127,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 2618, 2863, 0xFFFFFFFF, OS.TRUE)
    add_instrument(Vibraphone, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: This is the most perfect square. Better than SSB square.
    add_instrument_sample(standard-square-0, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F,  0,  45,  36, 0x0, 0x3F, 0x7E, OS.TRUE,  9847, 29047, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(standard-square-1, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 46,  57,  48, 0x0, 0x3F, 0x7E, OS.TRUE, 4677, 11077, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(standard-square-2, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 58,  69,  60, 0x0, 0x3F, 0x7E, OS.TRUE,  3939, 7139, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(standard-square-3, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 70,  81,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  1539, 3139, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(standard-square-4, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 82,  93,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 677, 1477, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(standard-square-5, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 94, 127,  96, 0x0, 0x3F, 0x7E, OS.TRUE,  339, 739, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Perfect Square PCM, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    //The waves actually look like teeth
    add_instrument_sample(saw-0, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F,  0,  45,  36, 0x0, 0x3F, 0x7E, OS.TRUE,  13785, 26585, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saw-1, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 46,  57,  48, 0x0, 0x3F, 0x7E, OS.TRUE, 2462, 5662, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saw-2, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 58,  69,  60, 0x0, 0x3F, 0x7E, OS.TRUE,  1354, 2954, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saw-3, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 70,  81,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  739, 1539, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saw-4, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 82,  93,  84, 0x0, 0x3F, 0x7E, OS.TRUE, 646, 1446, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(saw-5, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 94, 127,  96, 0x0, 0x3F, 0x7E, OS.TRUE,  1108, 3508, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Perfect Saw, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Generally used for Diamond Marina. It is their favorite instrument, very synthy.
    add_instrument_sample(an_power_drive-1, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 0, 66, 60, 0x0, 0x3F, 0x7E, OS.TRUE, 7574, 18584, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(an_power_drive-2, 0x0, 0x004C4B40, 66 * 450, 0x7F, 0x0, 0x0, 0x7F, 67, 91, 79, 0x0, 0x3F, 0x7E, OS.TRUE, 5998, 16719, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Alexis' Power Drive, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x80, 0xF1, 0x64, 0x01)

    // TODO: Dedicated for analog electronic music. You might as well putting the pitch shift all the way UP to the normal precussion if you are gonna use this kit.
    add_instrument_sample(808-01, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  35,  35,  35, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-02, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  36,  36,  36, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-03, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  37,  37,  37, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-04, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  38,  38,  38, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-05, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  39,  39,  39, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-06, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  40,  40,  40, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-09, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  41,  41,  41, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-08, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  42,  42,  42, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-09, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  43,  43,  41, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-10, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  44,  44,  44, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-13, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  45,  45,  47, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-12, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  46,  46,  46, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-13, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  47,  47,  47, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-16, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  48,  48,  48, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-15, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F,  49,  49,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  7453, 10114, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(808-16, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  50,  50,  50, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-17, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  56,  56,  56, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-18, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  62,  62,  62, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-19, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  63,  63,  63, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-20, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  64,  64,  64, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-21, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  70,  70,  70, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument_sample(808-22, 0x0, 0x0, 66 * 1879, 0x7F, 0x7F, 0x0, 0x7F,  75,  75,  75, 0x0, 0x3F, 0x7E, OS.FALSE, 0, 0, 0, OS.FALSE)
    add_instrument(TR-808 Kit, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    //This is what the REAL Shamisen sounds like!
    add_instrument_sample(JVShamisen-1, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F,  0,  50,  43, 0x0, 0x3F, 0x7E, OS.TRUE,  23296, 34172, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-2, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 51,  55,  55, 0x0, 0x3F, 0x7E, OS.TRUE, 15744, 23127, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-3, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 56,  59,  58, 0x0, 0x3F, 0x7E, OS.TRUE,  18279, 28143, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-4, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 60,  62,  60, 0x0, 0x3F, 0x7E, OS.TRUE,  12779, 21376, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-5, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 63,  67,  67, 0x0, 0x3F, 0x7E, OS.TRUE, 18443, 27585, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-6, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 68, 76,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  12539, 18127, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(JVShamisen-7, 0x0, 0x0, 66 * 30, 0x7F, 0x7F, 0x0, 0x7F, 77, 91,  72, 0x0, 0x3F, 0x7E, OS.TRUE,  14954, 23684, 0xFFFFFFFF, OS.FALSE)
    add_instrument(True Shamisen (JV-1080), 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    //Banjo sound funny hehe.
    add_instrument_sample(banjo-1, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F,  0,  71, 67, 0x0, 0x3F, 0x7E, OS.TRUE, 10725, 12275, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(banjo-2, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F, 72,  76, 74, 0x0, 0x3F, 0x7E, OS.TRUE, 9472, 11268, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(banjo-3, 0x0, 0x0010C8E0, 25000, 0x7F, 0x00, 0x00, 0x7F, 77,  90, 79, 0x0, 0x3F, 0x7E, OS.TRUE, 8226, 10224, 0xFFFFFFFF, OS.FALSE)
    add_instrument(SR-JV Banjo, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: This can be used for amazing beats!
    add_instrument_sample(loop-1, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  24,  18, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 46207, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(loop-2, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  24,  42, 0x0, 0x3F, 0x7E, OS.TRUE, 0, 32111, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Drum Loops, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    // TODO: Be a guitar hero bro.
    add_instrument_sample(strat-01, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 0,  57,  64, 0x0, 0x3F, 0x7E, OS.TRUE, 5921, 8885, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(strat-02, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 58,  69,  76, 0x0, 0x3F, 0x7E, OS.TRUE, 6152, 14773, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(strat-03, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 70,  92,  86, 0x0, 0x3F, 0x7E, OS.TRUE, 6179, 6233, 0xFFFFFFFF, OS.FALSE)
    add_instrument_sample(strat-04, 0x0, 800000, 66 * 1879, 0x7F, 0x20, 0x0, 0x7F, 93,  112,  100, 0x0, 0x3F, 0x7E, OS.TRUE, 3027, 3075, 0xFFFFFFFF, OS.FALSE)
    add_instrument(Guitar Hero, 0x7E, 0x3F, 0x05, 1200, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0)

    move_instrument_bank_map()

    // @ Description
    // Loads the instrument bank map from ROM to RAM so that instrument data is properly processed at startup
    scope dmaCopy_moved_bank_map_: {
        OS.patch_start(0x20148, 0x8001F548)
        jal     dmaCopy_moved_bank_map_
        nop
        OS.patch_end()

        OS.save_registers()                             // save registers

        // reload bank table from ROM
        li      a0, moved_inst_bank_map_origin          // load rom address
        li      a1, moved_inst_bank_map                 // load ram address
        li      a2, 0x10 + (instrument_count * 4)       // load length of bank table
        jal     0x80002CA0                              // dmaCopy
        nop

        OS.restore_registers()                          // restore registers

        _end:
        j       0x8001E91C                              // original line 1
        or      a2, s0, r0                              // original line 2
    }

    print "========================================================================== \n"

    // @ Description
    // Adds a priority override for the given instrument/bgm combination.
    // Also creates a priority override array if it doesn't already exist.
    // bgm - id of bgm
    // instrument - id of instrument
    // priority - priority value to use for this track
    macro add_priority_override(bgm, instrument, priority) {
        evaluate bgm({bgm})

        // create an override array for this bgm if it doesn't exist
        if !{defined priority_override_{bgm}} {
            global define priority_override_{bgm}()

            priority_override_array_{bgm}:
            constant priority_override_array_{bgm}_origin(origin())
            fill instrument_count
            OS.align(16)

            pushvar origin, base
            origin priority_override_table_origin + ({bgm} * 0x4)
            dw  priority_override_array_{bgm}
            pullvar base, origin
        }

        // add the override value for this instrument
        pushvar origin, base
        origin priority_override_array_{bgm}_origin + {instrument}
        db  {priority}
        pullvar base, origin
    }

    // @ Description
    // Adds a bend range override for the given instrument/bgm combination.
    // Also creates a bend range override array if it doesn't already exist.
    // bgm - id of bgm
    // instrument - id of instrument
    // bend_range - bend_range value to use for this track
    macro add_bend_range_override(bgm, instrument, bend_range) {
        evaluate bgm({bgm})

        // create an override array for this bgm if it doesn't exist
        if !{defined bend_range_override_{bgm}} {
            global define bend_range_override_{bgm}()

            bend_range_override_array_{bgm}:
            constant bend_range_override_array_{bgm}_origin(origin())
            fill instrument_count * 2
            OS.align(16)

            pushvar origin, base
            origin bend_range_override_table_origin + ({bgm} * 0x4)
            dw  bend_range_override_array_{bgm}
            pullvar base, origin
        }

        // add the override value for this instrument
        pushvar origin, base
        origin bend_range_override_array_{bgm}_origin + ({instrument} * 2)
        dh  {bend_range}
        pullvar base, origin
    }

    // @ Description
    // Adds a master volume override for the given bgm.
    // bgm - id of bgm
    // volume - master volume value to use for this track
    macro add_master_volume_override(bgm, volume) {
        evaluate bgm({bgm})
        // add the override value for this bgm
        pushvar origin, base
        origin master_volume_override_table_origin + {bgm}
        if {volume} > 127 {
        print "WARNING: Max value for master volume override is 127 \n"
        db  127
        } else {
        db  {volume}
        }
        pullvar base, origin
    }

    // @ Description
    // Alternate version of subroutine 0x8002E2AC which seems to load instrument parameters.
    // Checks to see if the current BGM gives an alternate priority or bend range value for the given instrument.
    // a0 - unknown (original)
    // a1 - address of instrument parameters
    // a2 - unknown (original)
    scope override_instrument_parameters_: {
        OS.patch_start(0x2C820, 0x8002BC20)
        jal     override_instrument_parameters_
        OS.patch_end()

        lw      t6, 0x0068(a0)              // ~
        sll     v0, a2, 0x2                 // ~
        subu    v0, v0, a2                  // ~
        sll     v0, v0, 0x3                 // ~
        addu    t7, t6, v0                  // ~
        sw      a1, 0x0000(t7)              // ~
        lw      t9, 0x0068(a0)              // undocumented original logic

        _priority:
        li      t0, BGM.safe_id             // t0 = address of safe bgm_id
        lw      t0, 0x0000(t0)              // t0 = current bgm_id
        li      t1, priority_override_table // t1 = priority_override_table
        sll     t0, t0, 0x2                 // t0 = offset (bgm * 4)
        addu    t1, t1, t0                  // t1 = priority_override_table + offset
        lw      t1, 0x0000(t1)              // t1 = address of override array for current bgm
        beql    t1, r0, _bend_range         // skip if array pointer = NULL...
        lbu     t8, 0x0002(a1)              // ...and load original priority to t8

        // if there is a priority override array for the current bgm, check for an override value for the current instrument
        // fp/s8 is presumed to always contain the instrument id at this point, this is almost certainly safe because it's used for
        // a check for invalid instrument ids right before the function call we replace
        addu    t1, t1, s8                  // t1 = array pointer + offset(instrument id)
        lbu     t8, 0x0000(t1)              // t8 = priority override value
        beql    t8, r0, _bend_range         // if priority override = 0...
        lbu     t8, 0x0002(a1)              // ...load original priority to t8 instead

        _bend_range:
        // t0 = offset (bgm * 4)
        li      t1, bend_range_override_table // t1 = bend_range_override_table
        addu    t1, t1, t0                  // t1 = bend_range_override_table + offset
        lw      t1, 0x0000(t1)              // t1 = address of override array for current bgm
        beql    t1, r0, _continue           // skip if array pointer = NULL...
        lh      t1, 0x000C(a1)              // ...and load original bend range to t1 instead

        // if there is a bend range override array for the current bgm, check for an override value for the current instrument
        // fp/s8 is presumed to always contain the instrument id at this point, this is almost certainly safe because it's used for
        // a check for invalid instrument ids right before the function call we replace
        sll     t2, s8, 0x1                 // t2 = offset (instrument id * 2)
        addu    t1, t1, t2                  // t1 = array pointer + offset
        lh      t1, 0x0000(t1)              // t1 = bend range override value
        beql    t1, r0, _continue           // if bend rage override = 0...
        lh      t1, 0x000C(a1)              // ...load original bend range to t1 instead

        _continue:
        addu    t0, t9, v0                  // ~
        sb      t8, 0x0008(t0)              // store priority
        lw      t2, 0x0068(a0)              // ~
        addu    t3, t2, v0                  // ~
        sh      t1, 0x0004(t3)              // store bend range
        lw      t5, 0x0068(a0)              // ~
        lbu     t4, 0x0000(a1)              // ~
        addu    t6, t5, v0                  // ~
        jr      ra                          // ~
        sb      t4, 0x0011(t6)              // undocumented original logic
    }

    // @ Description
    // Overrides the vanilla master volume with a custom one if the track has it
    scope override_master_volume_: {
        OS.patch_start(0x302C0, 0x8002F6C0)
        j       override_master_volume_
        lbu     t7, 0x0078(a0)              // t7 = master volume (original line 2)
        _return:
        OS.patch_end()

        li      t0, BGM.safe_id             // t0 = address of safe bgm_id
        lw      t0, 0x0000(t0)              // t0 = current bgm_id
        li      t1, master_volume_override_table // t1 = master_volume_override_table
        addu    t1, t1, t0                  // t1 = master_volume_override_table + bgm_id
        lbu     t1, 0x0000(t1)              // t1 = master volume override for current bgm
        bnezl   t1, _end                    // if an override value is present...
        or      t7, t1, r0                  // t7 = new master volume value

        _end:
        j       _return
        lh      t6, 0x003A(a0)              // load other volume parameter (original line 2)
    }

    // @ Description
    // Can enable or disable MIDI channels. Bitflag located at 0x8003D31C
    // a0 = new channel bitflags to use (0x0000FFFF)
    scope toggle_channels: {
        lui     v0, 0x8004
        jr      ra
        sh      a0, 0xD31C(v0)              // v0 = current bitflags
    }

    OS.align(16)
    priority_override_table:
    constant priority_override_table_origin(origin())
    fill midi_count * 0x4
    OS.align(16)

    OS.align(16)
    bend_range_override_table:
    constant bend_range_override_table_origin(origin())
    fill midi_count * 0x4
    OS.align(16)

    OS.align(16)
    master_volume_override_table:
    constant master_volume_override_table_origin(origin())
    fill midi_count
    OS.align(16)

    // ADD PRIORITY OVERRIDES HERE
    // This can be used when MIDI cc16 fails to provide satisfactory results.
    // It should only be used in advanced cases and be used with care, as giving instruments extreme priority can cause FGMs to cut out or play back wrong.
    // bgm - id of bgm
    // instrument - id of instrument
    // priority - priority value to use for this track
    add_priority_override({MIDI.id.FOREST_INTERLUDE}, 7, 0x7F)
    add_priority_override({MIDI.id.FOREST_INTERLUDE}, 15, 0x7F)
    add_priority_override({MIDI.id.FOREST_INTERLUDE}, 28, 0x7F)
    add_priority_override({MIDI.id.FOREST_INTERLUDE}, 40, 0x7F)
    add_priority_override({MIDI.id.FOREST_INTERLUDE}, 55, 0x7F)

    add_priority_override({MIDI.id.DK_RAP}, 63, 0x7F)

    add_priority_override({MIDI.id.ROLL}, 64, 0x7F)

    add_priority_override({MIDI.id.YOSHI_TALE}, 65, 0x7F)

    add_priority_override({MIDI.id.TABUU}, 58, 0x7F)

    add_priority_override({MIDI.id.DISCOVERYFALLS}, 28, 0x7F)
    add_priority_override({MIDI.id.DISCOVERYFALLS}, 44, 0x7F)
    add_priority_override({MIDI.id.DISCOVERYFALLS}, 7, 0x7F)
    add_priority_override({MIDI.id.DISCOVERYFALLS}, 67, 0x7F)

    add_priority_override({MIDI.id.WIZPIG}, 58, 0x7F)
    add_priority_override({MIDI.id.WIZPIG}, 44, 0x7F)

    add_priority_override({MIDI.id.TOADS_TURNPIKE}, 2, 0x7F)
    add_priority_override({MIDI.id.TOADS_TURNPIKE}, 7, 0x7F)
    add_priority_override({MIDI.id.TOADS_TURNPIKE}, 44, 0x7F)

    add_priority_override({MIDI.id.FIRE_EMBLEM}, 34, 0x7F)

    add_priority_override({MIDI.id.ROCKSOLID}, 7, 0x7F)

    add_priority_override({MIDI.id.BIG_BRIDGE}, 34, 0x7F)

    add_priority_override({MIDI.id.TARGET_TEST}, 56, 0x7F)

    add_priority_override({MIDI.id.SS_AQUA}, 56, 0x7F)
    add_priority_override({MIDI.id.SS_AQUA}, 51, 0x7F)

    add_priority_override({MIDI.id.ELADARD}, 54, 0x7F)
    add_priority_override({MIDI.id.ELADARD}, 55, 0x7F)

    add_priority_override({MIDI.id.DRAKE_LAKE}, 1, 0x7F)

    add_priority_override({MIDI.id.BATTLE_AMONG_FRIENDS}, 28, 0x7F)

    add_priority_override({MIDI.id.MURASAKI}, 55, 0x7F)

    add_priority_override({MIDI.id.SKYWORLD}, 1, 0x7F)

    // ADD BEND RANGE OVERRIDES HERE
    // This can be used when default bend ranges fail to provide satisfactory results.
    // bgm - id of bgm
    // instrument - id of instrument
    // bend_range - bend_range value to use for this track

    add_bend_range_override({MIDI.id.YOSHI_TALE}, 2, 100) // sets vanilla organ to have a pitch bend of +/- 1 semitone instead of 0.1

    add_bend_range_override({MIDI.id.SLIDER}, 29, 1200)

    add_bend_range_override({MIDI.id.WILDLANDS}, 1, 200)

    add_bend_range_override({MIDI.id.OPUS_13}, 47, 100)

    add_bend_range_override({MIDI.id.FUTUREFRENZY}, 24, 1200)

    add_bend_range_override({MIDI.id.MUTE_CITY}, 41, 1200)

    add_bend_range_override({MIDI.id.SILVERSURFER}, 19, 1200)
    add_bend_range_override({MIDI.id.SILVERSURFER}, 20, 1200)

    add_bend_range_override({MIDI.id.TOWEROFHEAVEN}, 19, 1200)

    add_bend_range_override({MIDI.id.LIPS_THEME}, 19, 1200)
    add_bend_range_override({MIDI.id.LIPS_THEME}, 14, 1200)

    add_bend_range_override({MIDI.id.WALUIGI_PINBALL}, 12, 1200)
    add_bend_range_override({MIDI.id.WALUIGI_PINBALL}, 29, 1200)

    add_bend_range_override({MIDI.id.SONIC_R}, 13, 1200)

    add_bend_range_override({MIDI.id.RACEWAYS}, 11, 1200)

    add_bend_range_override({MIDI.id.BOWSERBOSS}, 5, 1200)

    add_bend_range_override({MIDI.id.BUBBLEGUM_KK}, 6, 1200)

    // ADD MASTER VOLUME OVERRIDES HERE
    // This can be used to adjust the overall volume of a track in-game.
    // bgm - id of bgm
    // volume - master volume to use for this track, 0-127, default is 100
    add_master_volume_override({MIDI.id.CORNERIA}, 93)
    add_master_volume_override({MIDI.id.DR_MARIO}, 90)
    add_master_volume_override({MIDI.id.GAME_CORNER}, 90)
    add_master_volume_override({MIDI.id.SMASHVILLE}, 110)
    add_master_volume_override({MIDI.id.STONECARVING_CITY}, 112)
    add_master_volume_override({MIDI.id.GODDESSBALLAD}, 115)
    add_master_volume_override({MIDI.id.TOWEROFHEAVEN}, 82)
    add_master_volume_override({MIDI.id.FOD}, 90)
    add_master_volume_override({MIDI.id.MEMENTOS}, 110)
    add_master_volume_override({MIDI.id.SPIRAL_MOUNTAIN}, 87)
    add_master_volume_override({MIDI.id.N64}, 104)
    add_master_volume_override({MIDI.id.BATTLEFIELD}, 95)
    add_master_volume_override({MIDI.id.MADMONSTER}, 90)
    add_master_volume_override({MIDI.id.GREEN_GREENS}, 95)
    add_master_volume_override({MIDI.id.POKEMON_STADIUM}, 83)
    add_master_volume_override({MIDI.id.SMB3OVERWORLD}, 90)
    add_master_volume_override({MIDI.id.DELFINO}, 110)
    add_master_volume_override({MIDI.id.ONETT}, 105)
    add_master_volume_override({MIDI.id.ZEBES_LANDING}, 95)
    add_master_volume_override({MIDI.id.EASTON_KINGDOM}, 83)
    add_master_volume_override({MIDI.id.WING_CAP}, 85)
    add_master_volume_override({MIDI.id.RBY_GYMLEADER}, 80)
    add_master_volume_override({MIDI.id.KITCHEN_ISLAND}, 90)
    add_master_volume_override({MIDI.id.DK_RAP}, 100)
    add_master_volume_override({MIDI.id.MACHRIDER}, 95)
    add_master_volume_override({MIDI.id.POKEFLOATS}, 82)
    add_master_volume_override({MIDI.id.GERUDO_VALLEY}, 90)
    add_master_volume_override({MIDI.id.POP_STAR}, 120)
    add_master_volume_override({MIDI.id.STAR_WOLF}, 83)
    add_master_volume_override({MIDI.id.POKEMON_CHAMPION}, 85)
    add_master_volume_override({MIDI.id.POLLYANNA}, 90)
    add_master_volume_override({MIDI.id.SAMBA_DE_COMBO}, 95)
    add_master_volume_override({MIDI.id.UNFOUNDED_REVENGE}, 90)
    add_master_volume_override({MIDI.id.KENGJR}, 86)
    add_master_volume_override({MIDI.id.BEIN_FRIENDS}, 90)
    add_master_volume_override({MIDI.id.KK_RIDER}, 95)
    add_master_volume_override({MIDI.id.SNAKEY_CHANTEY}, 95)
    add_master_volume_override({MIDI.id.TAZMILY}, 115)
    add_master_volume_override({MIDI.id.YOSHI_GOLF}, 88)
    add_master_volume_override({MIDI.id.FINALTEMPLE}, 88)
    add_master_volume_override({MIDI.id.OBSTACLE}, 90)
    add_master_volume_override({MIDI.id.EVEN_DRIER_GUYS}, 87)
    add_master_volume_override({MIDI.id.PEACH_CASTLE}, 105)
    add_master_volume_override({MIDI.id.BANJO_MAIN}, 95)
    add_master_volume_override({MIDI.id.GANGPLANK}, 108)
    add_master_volume_override({MIDI.id.FD_BRAWL}, 90)
    add_master_volume_override({MIDI.id.ARIA_OF_THE_SOUL}, 118)
    add_master_volume_override({MIDI.id.KING_OF_THE_KOOPAS}, 90)
    add_master_volume_override({MIDI.id.SKERRIES}, 95)
    add_master_volume_override({MIDI.id.BEWARE_THE_FORESTS_MUSHROOMS}, 95)
    add_master_volume_override({MIDI.id.TARGET_TEST}, 95)
    add_master_volume_override({MIDI.id.VENOM}, 80)
    add_master_volume_override({MIDI.id.BK_FINALBATTLE}, 107)
    add_master_volume_override({MIDI.id.OLE}, 92)
    add_master_volume_override({MIDI.id.WINDY}, 93)
    add_master_volume_override({MIDI.id.DATADYNE}, 90)
    add_master_volume_override({MIDI.id.INVESTIGATION_X}, 85)
    add_master_volume_override({MIDI.id.NSMB}, 105)
    add_master_volume_override({MIDI.id.JUNGLEJAPES}, 90)
    add_master_volume_override({MIDI.id.TOADS_TURNPIKE}, 92)
    add_master_volume_override({MIDI.id.GB_MEDLEY}, 90)
    add_master_volume_override({MIDI.id.FLOWER_GARDEN}, 110)
    add_master_volume_override({MIDI.id.WILDLANDS}, 125)
    add_master_volume_override({MIDI.id.VS_MARX}, 115)
    add_master_volume_override({MIDI.id.SS_AQUA}, 86)
    add_master_volume_override({MIDI.id.METAL_BATTLE}, 110)
    add_master_volume_override({MIDI.id.KANTO_WILD_BATTLE}, 85)
    add_master_volume_override({MIDI.id.PIRATELAND}, 90)
    add_master_volume_override({MIDI.id.FLYINGBATTERY}, 90)
    add_master_volume_override({MIDI.id.CASINO_NIGHT}, 90)
    add_master_volume_override({MIDI.id.SONIC2_SPECIAL}, 90)
    add_master_volume_override({MIDI.id.SONICCD_SPECIAL}, 95)
    add_master_volume_override({MIDI.id.GIANTWING}, 90)
    add_master_volume_override({MIDI.id.EMERALDHILL}, 90)
    add_master_volume_override({MIDI.id.LIVE_AND_LEARN}, 83)
    add_master_volume_override({MIDI.id.STARDUST}, 95)
    add_master_volume_override({MIDI.id.GREEN_HILL_ZONE}, 89)
    add_master_volume_override({MIDI.id.CHEMICAL_PLANT}, 87)
    add_master_volume_override({MIDI.id.BABY_BOWSER}, 85)
    add_master_volume_override({MIDI.id.METALLIC_MADNESS}, 85)
    add_master_volume_override({MIDI.id.EVERYTHING}, 80)
    add_master_volume_override({MIDI.id.RACEWAYS}, 90)
    add_master_volume_override({MIDI.id.KIRBY_64_BOSS}, 90)
    add_master_volume_override({MIDI.id.SMB2_MEDLEY}, 90)
    add_master_volume_override({MIDI.id.SMW_TITLECREDITS}, 90)
    add_master_volume_override({MIDI.id.DEDEDE}, 80)
    add_master_volume_override({MIDI.id.IRON_BLUE_INTENTION}, 90)
    add_master_volume_override({MIDI.id.DRACULAS_TEARS}, 80)
    add_master_volume_override({MIDI.id.WARIOWARE}, 110)
    add_master_volume_override({MIDI.id.FROZEN_HILLSIDE}, 95)
    add_master_volume_override({MIDI.id.SOCCER_MENU}, 90)
    add_master_volume_override({MIDI.id.TROUBLE_MAKER}, 90)
    add_master_volume_override({MIDI.id.WL2_PERFECT}, 85)
    add_master_volume_override({MIDI.id.CONTROL}, 90)
    add_master_volume_override({MIDI.id.OEDO_EDO}, 95)
    add_master_volume_override({MIDI.id.MAJORA_MIDBOSS}, 92)
    add_master_volume_override({MIDI.id.SMW_ATHLETIC}, 85)
    add_master_volume_override({MIDI.id.BRAWL_OOT}, 110)
    add_master_volume_override({MIDI.id.BOSS_E}, 80)
    add_master_volume_override({MIDI.id.MARINE_FORTRESS}, 75)
    add_master_volume_override({MIDI.id.TWILIGHT_CITY}, 95)
    add_master_volume_override({MIDI.id.SOUTHERNISLAND}, 90)
    add_master_volume_override({MIDI.id.QUEST64_BATTLE}, 83)
    add_master_volume_override({MIDI.id.DECISIVE}, 90)
    add_master_volume_override({MIDI.id.HILLTOPCHASE}, 110)
    add_master_volume_override({MIDI.id.FF4BOSS}, 89)
    add_master_volume_override({MIDI.id.GRIMREAPERSCAVERN}, 90)
    add_master_volume_override({MIDI.id.SHANTAEMEDLEY}, 91)
    add_master_volume_override({MIDI.id.BURNINGTOWN}, 87)
    add_master_volume_override({MIDI.id.SHANTAEBOSS}, 90)
    add_master_volume_override({MIDI.id.FORTRESS_BOSS}, 90)
    add_master_volume_override({MIDI.id.HORROR_LAND}, 94)
    add_master_volume_override({MIDI.id.DARKWORLD}, 88)
    add_master_volume_override({MIDI.id.FRAPPE_SNOWLAND}, 92)
    add_master_volume_override({MIDI.id.SMRPG_BATTLE}, 85)
    add_master_volume_override({MIDI.id.TRAVELING}, 90)
    add_master_volume_override({MIDI.id.CHILL}, 112)
    add_master_volume_override({MIDI.id.ROLL}, 90)
    add_master_volume_override({MIDI.id.STICKERBRUSH_SYMPHONY}, 93)
    add_master_volume_override({MIDI.id.DKCTITLE}, 93)
    add_master_volume_override({MIDI.id.PLANTATION}, 87)
    add_master_volume_override({MIDI.id.7AM}, 110)
    add_master_volume_override({MIDI.id.QUEQUE}, 87)
    add_master_volume_override({MIDI.id.VSRIDLEY}, 95)
    add_master_volume_override({MIDI.id.FLANDRES_THEME}, 90)
    add_master_volume_override({MIDI.id.THE_ALOOF_SOLDIER}, 90)
    add_master_volume_override({MIDI.id.WENDYS_HOUSE}, 90)
    add_master_volume_override({MIDI.id.DANGEROUS_FOE}, 90)
    add_master_volume_override({MIDI.id.PIKA_CUP}, 85)
    add_master_volume_override({MIDI.id.WIZPIG}, 90)
    add_master_volume_override({MIDI.id.BATTLE_C1}, 80)
    add_master_volume_override({MIDI.id.CREDITS_BRAWL}, 90)
    add_master_volume_override({MIDI.id.BATTLE_GOLD_SILVER}, 90)
    add_master_volume_override({MIDI.id.GOLDENROD_CITY}, 90)
    add_master_volume_override({MIDI.id.GANONMEDLEY}, 80)
    add_master_volume_override({MIDI.id.FUGUE}, 85)
    add_master_volume_override({MIDI.id.SILVER_MOUNTAIN}, 85)
    add_master_volume_override({MIDI.id.PORKY}, 80)
    add_master_volume_override({MIDI.id.NSANITYBEACH}, 93)
    add_master_volume_override({MIDI.id.DISCOVERYFALLS}, 90)
    add_master_volume_override({MIDI.id.DK_MEDLEY}, 90)
    add_master_volume_override({MIDI.id.BIG_BRIDGE}, 93)
    add_master_volume_override({MIDI.id.HOGWILD}, 88)
    add_master_volume_override({MIDI.id.MARATHON}, 91)
    add_master_volume_override({MIDI.id.FORGONE}, 95)
    add_master_volume_override({MIDI.id.ELADARD}, 90)
    add_master_volume_override({MIDI.id.FZEROX_MEDLEY}, 115)
    add_master_volume_override({MIDI.id.BUBBLEGUM_KK}, 93)
    add_master_volume_override({MIDI.id.MADMAZEMAUL}, 80)
    add_master_volume_override({MIDI.id.TITANIA}, 93)
    add_master_volume_override({MIDI.id.SHEVAT}, 115)
    add_master_volume_override({MIDI.id.CORTEX}, 115)
    add_master_volume_override({MIDI.id.WILY_FIELD}, 111)
    add_master_volume_override({MIDI.id.SMS_BOSS}, 87)
    add_master_volume_override({MIDI.id.VS_DSAMUS}, 85)
    add_master_volume_override({MIDI.id.STRIKE_THE_EARTH}, 80)
    add_master_volume_override({MIDI.id.VAMPIREKILLER}, 88)
    add_master_volume_override({MIDI.id.REDIAL}, 95)
    add_master_volume_override({MIDI.id.AGAVE}, 95)
    add_master_volume_override({MIDI.id.RAIDBLUE}, 111)
    add_master_volume_override({MIDI.id.RISKNECK}, 111)
    add_master_volume_override({MIDI.id.SHERBETLAND}, 86)
    add_master_volume_override({MIDI.id.DEATH_MOUNTAIN}, 95)
    add_master_volume_override({MIDI.id.BATTLE_AMONG_FRIENDS}, 95)
    add_master_volume_override({MIDI.id.NBA_JAM}, 106)
    add_master_volume_override({MIDI.id.MURASAKI}, 115)
    add_master_volume_override({MIDI.id.FE6_MEDLEY}, 111)
    add_master_volume_override({MIDI.id.FUTUREFRENZY}, 107)
    add_master_volume_override({MIDI.id.LANKY_VICTORY}, 127)
    add_master_volume_override({MIDI.id.LIPS_THEME}, 95)
    add_master_volume_override({MIDI.id.CRASHBASH_LOADING}, 95)
    add_master_volume_override({MIDI.id.TREASURE_TROVE_COVE}, 95)
    add_master_volume_override({MIDI.id.GREENGARDEN}, 105)
    add_master_volume_override({MIDI.id.BLUE_RESORT}, 127)
    add_master_volume_override({MIDI.id.DRMARIO_VICTORY}, 127)
    add_master_volume_override({MIDI.id.BOWSERBOSS}, 88)
    add_master_volume_override({MIDI.id.LOST}, 93)
}

} // __MIDI__

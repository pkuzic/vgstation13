
// Rune Spells that aren't listed when the player tries to draw a guided rune.




////////////////////////////////////////////////////////////////////
//																  //
//							SUMMON TOME							  //
//																  //
////////////////////////////////////////////////////////////////////
//Reason: Redundant with paraphernalia. No harm in keeping the rune somewhat usable until another use is found for that word combination.

/datum/rune_spell/summontome
	secret = TRUE
	name = "Summon Tome"
	desc = "Bring forth an arcane tome filled with Nar-Sie's knowledge."
	desc_talisman = "Turns into an arcane tome upon use."
	invocation = "N'ath reth sh'yro eth d'raggathnor!"
	word1 = /datum/rune_word/see
	word2 = /datum/rune_word/blood
	word3 = /datum/rune_word/hell
	cost_invoke = 4
	page = ""

/datum/rune_spell/summontome/cast()
	var/obj/effect/rune/R = spell_holder
	R.one_pulse()

	if (pay_blood())
		var/datum/role/cultist/C = activator.mind.GetRole(CULTIST)
		C.gain_devotion(10, DEVOTION_TIER_0, "conjure_paraphernalia", "Arcane Tome")
		spell_holder.visible_message("<span class='rose'>The rune's symbols merge into each others, and an Arcane Tome takes form in their place</span>")
		var/turf/T = get_turf(spell_holder)
		var/obj/item/weapon/tome/AT = new (T)
		anim(target = AT, a_icon = 'icons/effects/effects.dmi', flick_anim = "tome_spawn")
		qdel(spell_holder)
	else
		qdel(src)

/datum/rune_spell/summontome/cast_talisman()//The talisman simply turns into a tome.
	var/turf/T = get_turf(spell_holder)
	var/obj/item/weapon/tome/AT = new (T)
	if (spell_holder == activator.get_active_hand())
		activator.drop_item(spell_holder, T)
		activator.put_in_active_hand(AT)
		var/datum/role/cultist/C = activator.mind.GetRole(CULTIST)
		C.gain_devotion(10, DEVOTION_TIER_0, "conjure_paraphernalia", "Arcane Tome")
	else//are we using the talisman from a tome?
		activator.put_in_hands(AT)
	flick("tome_spawn",AT)
	qdel(src)


////////////////////////////////////////////////////////////////////
//																  //
//								STREAM							  //
//																  //
////////////////////////////////////////////////////////////////////
//Reason: we don't want a new cultist player to use this rune by accident, better leave it to savvy ones

/datum/rune_spell/stream
	secret = TRUE
	name = "Stream"
	desc = "Start or stop streaming on Spess.TV."
	desc_talisman = "Start or stop streaming on Spess.TV."
	invocation = "L'k' c'mm'nt 'n' s'bscr'b! P'g ch'mp! Kappah!"
	word1 = /datum/rune_word/other
	word2 = /datum/rune_word/see
	word3 = /datum/rune_word/self
	page = "This rune lets you start (or stop) streaming on Spess.TV so that you can let your audience watch and cheer for you while you slay infidels in the name of Nar-sie. #Sponsored"

/datum/rune_spell/stream/cast()
	var/datum/role/streamer/streamer = activator.mind.GetRole(STREAMER)
	if(!streamer)
		streamer = new /datum/role/streamer
		streamer.team = ESPORTS_CULTISTS
		if(!streamer.AssignToRole(activator.mind, 1))
			streamer.Drop()
			return
		streamer.OnPostSetup()
		streamer.Greet(GREET_DEFAULT)
		streamer.AnnounceObjectives()
	streamer.team = ESPORTS_CULTISTS
	if(!streamer.camera)
		streamer.set_camera(new /obj/machinery/camera/arena/spesstv(activator))
	streamer.toggle_streaming()
	qdel(src)


////////////////////////////////////////////////////////////////////
//																  //
//						    TEAR REALITY						  //
//																  //
////////////////////////////////////////////////////////////////////
//Reason: the words for that one are revealed to cultists on their UI once the Eclipse timer has reached zero

/datum/rune_spell/tearreality
	secret = TRUE
	name = "Tear Reality"
	desc = "Bring 8 cultists or prisoners to kickstart the ritual to bring forth Nar-Sie."
	desc_talisman = "Use to kickstart the ritual to bring forth Nar-Sie where you stand."
	invocation = "Tok-lyr rqa'nap g'lt-ulotf!"
	word1 = /datum/rune_word/hell
	word2 = /datum/rune_word/join
	word3 = /datum/rune_word/self
	page = ""
	var/atom/blocker
	var/list/dance_platforms = list()
	var/dance_count = 0
	var/dance_target = 120
	var/obj/effect/cult_ritual/dance/dance_manager
	var/image/crystals
	var/image/top_crystal
	var/image/narsie_glint

	var/spawners_sent = FALSE
	var/list/pillar_spawners = list()
	var/list/gateway_spawners = list()

/datum/rune_spell/tearreality/cast()
	var/obj/effect/rune/R = spell_holder
	R.one_pulse()
	var/turf/T = get_turf(R)

	//The most fickle rune there ever was
	var/datum/faction/bloodcult/cult = find_active_faction_by_type(/datum/faction/bloodcult)
	if (!istype(cult))
		to_chat(activator, "<span class='warning'>Couldn't find the cult faction. Something's broken, please report the issue to an admin or using the BugReport button at the top.</span>")
		return

	switch(cult.stage)
		if (BLOODCULT_STAGE_NORMAL)
			to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
			to_chat(activator, "<span class='sinister'>The Eclipse is coming, but until then this rune serves no purpose.</span>")
			if (R.z != map.zMainStation)
				to_chat(activator, "<span class='sinister'>When it does, you should try again <font color='red'>aboard the station</font>.</span>")
			else if (isspace(R.loc) || is_on_shuttle(R) || (get_dist(locate(map.center_x,map.center_y,map.zMainStation),R) > 100))
				to_chat(activator, "<span class='sinister'>When it does, you should try again <font color='red'>closer from the station's center</font>.</span>")
			var/obj/structure/dance_check/checker = new(T, src)
			var/list/moves_to_do = list(SOUTH, WEST, NORTH, NORTH, EAST, EAST, SOUTH, SOUTH, WEST)
			for (var/direction in moves_to_do)
				if (!checker.Move(get_step(checker, direction)))//The checker passes through mobs and non-dense objects, but bumps against dense objects and turfs
					to_chat(activator, "<span class='sinister'>and <font color='red'>in a more open area</font>.</span>")
			abort()
			return

		if (BLOODCULT_STAGE_MISSED)
			to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
			to_chat(activator, "<span class='sinister'>The window of opportunity has passed along with the Eclipse. Make your way off this space station so you may attempt another day.</span>")
			abort()
			return

		if (BLOODCULT_STAGE_ECLIPSE)
			to_chat(activator, "<span class='sinister'>The Bloodstone has been raised! Now is not the time to use that rune.</span>")
			abort()
			return

		if (BLOODCULT_STAGE_DEFEATED)
			to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
			to_chat(activator, "<span class='sinister'>With the Bloodstone's collapse, the veil in this region of space has fully mended itself. Another cult will make an attempt in another space station someday.</span>")
			abort()
			return

		if (BLOODCULT_STAGE_NARSIE)
			to_chat(activator, "<span class='sinister'>The tear has already be opened. Praise the Geometer in this most unholy day!</span>")
			abort()
			return

	if (cult.stage != BLOODCULT_STAGE_READY)
		to_chat(activator, "<span class='warning'>Cult faction appears to be in an unset stage. Something's broken, please report the issue to an admin or using the BugReport button at the top.</span>")
		abort()
		return

	if (R.z != map.zMainStation)
		to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
		to_chat(activator, "<span class='sinister'>You should try again <font color='red'>aboard the station</font>.</span>")
		abort()
		return

	if (cult.tear_ritual)
		var/obj/effect/rune/U = cult.tear_ritual.spell_holder
		to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
		to_chat(activator, "<span class='sinister'>It appears that another tear is currently being opened. Somewhere...<font color='red'>to the [dir2text(get_dir(R, U))]</font>.</span>")
		abort()
		return

	if (isspace(R.loc) || is_on_shuttle(R) || (get_dist(locate(map.center_x,map.center_y,map.zMainStation),R) > 100))
		to_chat(activator, "<span class='sinister'>The rune pulses but no energies respond to its signal.</span>")
		to_chat(activator, "<span class='sinister'>Try again <font color='red'>closer from the station's center</font>.</span>")
		abort()
		return

	var/obj/structure/dance_check/checker = new(T, src)
	var/list/moves_to_do = list(SOUTH, WEST, NORTH, NORTH, EAST, EAST, SOUTH, SOUTH, WEST)
	for (var/direction in moves_to_do)
		if (!checker.Move(get_step(checker, direction)))//The checker passes through mobs and non-dense objects, but bumps against dense objects and turfs
			if (blocker)
				to_chat(activator, "<span class='sinister'>The nearby [blocker] will impede the ritual.</span>")
			to_chat(activator, "<span class='sinister'>You should try again <font color='red'>in a more open area</font>.</span>")
			abort()
			return

	//Alright now we can get down to business
	cult.tear_ritual = src
	R.overlays.len = 0
	R.icon = 'icons/obj/cult_96x96.dmi'
	R.pixel_x = -32
	R.pixel_y = -32
	R.layer = BELOW_TABLE_LAYER
	R.plane = OBJ_PLANE
	R.set_light(1, 2, LIGHT_COLOR_RED)

	var/datum/holomap_marker/newMarker = new()
	newMarker.id = HOLOMAP_MARKER_TEARREALITY
	newMarker.filter = HOLOMAP_FILTER_CULT
	newMarker.x = R.x
	newMarker.y = R.y
	newMarker.z = R.z
	holomap_markers[HOLOMAP_MARKER_TEARREALITY] = newMarker

	anim(target = R.loc, a_icon = 'icons/obj/cult_96x96.dmi', flick_anim = "rune_tearreality_activate", lay = BELOW_TABLE_LAYER, offX = -32, offY = -32, plane = OBJ_PLANE)

	var/list/platforms_to_spawn = list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
	for (var/direction in platforms_to_spawn)
		if (!destroying_self)
			var/turf/U = get_step(R, direction)
			shadow(U,R.loc)
			var/obj/effect/cult_ritual/dance_platform/platform = new(U, src)
			dance_platforms += platform
			sleep(1)

	if (!destroying_self)
		message_admins("[key_name(activator)] is preparing the Tear Reality ritual at [T.loc] ([T.x],[T.y],[T.z]).")
		for (var/datum/role/cultist in cult.members)
			var/mob/M = cultist.antag.current
			to_chat(M, "<span class='sinister'>The ritual to tear reality apart and pull the station into the realm of Nar-Sie is now taking place in <font color='red'>[T.loc]</font>.</span>")
			to_chat(M, "<span class='sinister'>A total of 8 persons, either cultists or prisoners, is required for the ritual to start. Go there to help start and then protect the ritual.</span>")

		var/image/I_circle = image('icons/obj/cult_96x96.dmi',"rune_tearreality")
		I_circle.plane = relative_plane_to_plane(ABOVE_TURF_PLANE,spell_holder.plane)
		I_circle.layer = ABOVE_TILE_LAYER
		I_circle.appearance_flags |= RESET_COLOR
		var/image/I_crystals = image('icons/obj/cult_96x96.dmi',"tear_stones")
		I_crystals.plane = relative_plane_to_plane(OBJ_PLANE,spell_holder.plane)
		I_crystals.layer = BELOW_TABLE_LAYER
		I_crystals.appearance_flags |= RESET_COLOR
		R.overlays += I_circle
		R.overlays += I_crystals
		custom_rune = TRUE

		crystals = image('icons/obj/cult_96x96.dmi',"tear_stones_[min(8,1+(dance_count/30))]")
		crystals.plane = relative_plane_to_plane(ABOVE_OBJ_PLANE,spell_holder.plane)

		top_crystal = image('icons/obj/cult_96x96.dmi',"tear_stones_top")
		top_crystal.plane = relative_plane_to_plane(ABOVE_HUMAN_PLANE,spell_holder.plane)
		top_crystal.layer = RAILING_FRONT_LAYER
		top_crystal.appearance_flags |= RESET_COLOR
		R.overlays += top_crystal

		narsie_glint = image('icons/obj/cult.dmi',"narsie_glint")
		narsie_glint.plane = relative_plane_to_plane(ABOVE_LIGHTING_PLANE,spell_holder.plane)
		narsie_glint.layer = NARSIE_GLOW
		narsie_glint.alpha = 0
		narsie_glint.pixel_x = 32
		narsie_glint.pixel_y = 32
		R.overlays += narsie_glint


/datum/rune_spell/tearreality/cast_talisman() //Tear Reality talismans create an invisible summoning rune beneath the caster's feet.
	var/obj/effect/rune/R = new(get_turf(activator))
	R.icon_state = "temp"
	R.active_spell = new type(activator,R)
	qdel(src)

/datum/rune_spell/tearreality/midcast(var/mob/add_cultist)
	to_chat(add_cultist, "<span class='sinister'>Stand in the surrounding circles with fellow cultists and captured prisoners until every spot is filled.</span>")

/datum/rune_spell/tearreality/abort(var/cause)
	var/datum/faction/bloodcult/cult = find_active_faction_by_type(/datum/faction/bloodcult)
	if (cult && (cult.tear_ritual == src))
		cult.tear_ritual = null
	if (dance_manager)
		QDEL_NULL(dance_manager)

	var/obj/effect/rune/R = spell_holder
	R.set_light(0)
	R.icon = 'icons/effects/deityrunes.dmi'
	R.pixel_x = 0
	R.pixel_y = 0
	R.layer = RUNE_LAYER
	R.plane = ABOVE_TURF_PLANE

	for(var/obj/effect/cult_ritual/dance_platform/platform in dance_platforms)
		qdel(platform)

	spawn()
		for(var/obj/effect/cult_ritual/tear_spawners/pillar_spawner/CR in pillar_spawners)
			CR.cancel()
			sleep(1)

	for(var/obj/effect/cult_ritual/CR in gateway_spawners)
		qdel(CR)

	..()

/datum/rune_spell/tearreality/proc/dancer_check(var/mob/living/C)
	var/obj/effect/rune/R = spell_holder
	if (dance_platforms.len <= 0)
		return
	if (!isturf(R.loc))//moved inside the blood stone
		return
	if (dance_manager && C)
		dance_manager.dancers |= C
		if(iscultist(C))
			C.say("Tok-lyr rqa'nap g'lt-ulotf!","C")
		else
			to_chat(C, "<span class='sinister'>The tentacles shift and force your body to move alongside them, performing some kind of dance.</span>")
		return
	for(var/obj/effect/cult_ritual/dance_platform/platform in dance_platforms)
		if (!platform.dancer)
			return

	//full dancers!
	var/turf/T = get_turf(R)

	var/datum/faction/bloodcult/cult = find_active_faction_by_type(/datum/faction/bloodcult)
	cult.twister = TRUE

	if (!spawners_sent)
		spawners_sent = TRUE
		new /obj/effect/cult_ritual/tear_spawners/vertical_spawner(T, src)
		new /obj/effect/cult_ritual/tear_spawners/vertical_spawner/up(T, src)
		new /obj/effect/cult_ritual/tear_spawners/horizontal_spawner/left(T, src)
		new /obj/effect/cult_ritual/tear_spawners/horizontal_spawner/right(T, src)

	dance_manager = new(T)

	for(var/obj/effect/cult_ritual/dance_platform/platform in dance_platforms)
		dance_manager.extras += platform
		platform.dance_manager = dance_manager
		if (platform.dancer)
			dance_manager.dancers += platform.dancer
			if(iscultist(platform.dancer))
				platform.dancer.say("Tok-lyr rqa'nap g'lt-ulotf!","C")
				if (iscarbon(platform.dancer))
					var/mob/living/carbon/CA = platform.dancer
					if (CA.get_cult_power() < 80)
						to_chat(platform.dancer, "<span class='warning'>You feel like you could dance more effectively by wearing proper cult attire.</span>")
					else if (!istype(CA.get_active_hand(), /obj/item/candle/blood) && !istype(CA.get_inactive_hand(), /obj/item/candle/blood))
						to_chat(platform.dancer, "<span class='warning'>Holding a lit blood candle would help you focus your mind on the ritual while you dance.</span>")
			else
				to_chat(platform.dancer, "<span class='sinister'>The tentacles shift and force your body to move alongside them, performing some kind of dance.</span>")

	dance_manager.tear = src
	dance_manager.we_can_dance()

/datum/rune_spell/tearreality/proc/update_crystals()
	var/obj/effect/rune/R = spell_holder
	R.overlays -= crystals
	R.overlays -= top_crystal
	R.overlays -= narsie_glint
	crystals.icon_state = "tear_stones_[min(8,1+round(dance_count/30))]"
	top_crystal.icon_state = "tear_stones_1"
	narsie_glint.alpha = max(0, (dance_count-105)*2)//Nar-Sie's eyes become about visible half-way through the dance
	top_crystal.appearance_flags &= ~RESET_COLOR
	R.overlays += crystals
	R.overlays += top_crystal
	if (isturf(R.loc))
		if (dance_count >= dance_target)// DANCE IS OVER!!
			var/datum/faction/bloodcult/cult = find_active_faction_by_type(/datum/faction/bloodcult)
			if (cult && !cult.bloodstone)
				var/obj/structure/cult/bloodstone/blood_stone = new(R.loc)
				cult.bloodstone = blood_stone
				holomap_markers -= HOLOMAP_MARKER_TEARREALITY
				var/datum/holomap_marker/newMarker = new()
				newMarker.id = HOLOMAP_MARKER_BLOODSTONE
				newMarker.filter = HOLOMAP_FILTER_CULT
				newMarker.x = blood_stone.x
				newMarker.y = blood_stone.y
				newMarker.z = blood_stone.z
				holomap_markers[HOLOMAP_MARKER_BLOODSTONE] = newMarker
				cult.stage(BLOODCULT_STAGE_ECLIPSE)
				R.mouse_opacity = 0
				R.forceMove(blood_stone)//keeping the rune safe inside the bloodstone
				QDEL_NULL(dance_manager)
				blood_stone.flashy_entrance(src)
		else
			R.overlays += narsie_glint
	R.update_moody_light('icons/lighting/moody_lights_96x96.dmi', crystals.icon_state)

/datum/rune_spell/tearreality/proc/pillar_update(var/update_level)
	for (var/obj/effect/cult_ritual/tear_spawners/pillar_spawner/PS in pillar_spawners)
		PS.execute(update_level)

	for (var/obj/effect/cult_ritual/tear_spawners/gateway_spawner/GS in gateway_spawners)
		GS.execute(update_level)

/datum/rune_spell/tearreality/proc/lost_dancer()
	for(var/obj/effect/cult_ritual/dance_platform/platform in dance_platforms)
		if (platform.dancer)
			return
	dance_count = 0
	QDEL_NULL(dance_manager)
	var/obj/effect/rune/R = spell_holder
	R.overlays -= crystals
	R.overlays -= top_crystal
	top_crystal.icon_state = "tear_stones_top"
	top_crystal.appearance_flags |= RESET_COLOR
	R.overlays += top_crystal
	R.kill_moody_light()

/datum/rune_spell/tearreality/proc/dance_increment(var/mob/living/L)
	if (dance_manager)
		var/increment = 0.5
		if (iscarbon(L))
			var/mob/living/carbon/C = L
			if (istype(C.handcuffed,/obj/item/weapon/handcuffs/cult))
				increment += 0.5
			increment += (C.get_cult_power()) / 100

			var/obj/item/candle/blood/candle
			if (istype(C.get_active_hand(), /obj/item/candle/blood))
				candle = C.get_active_hand()
			else if (istype(C.get_inactive_hand(), /obj/item/candle/blood))
				candle = C.get_inactive_hand()
			if (candle && candle.lit)
				increment += 0.5
		dance_count += increment

//---------------------------------------------------------------------------------------------------------------------


/*
Hall of fame of previous deprecated runes, might redesign later, noting their old word combinations there so I can easily retrieve them later.

MANIFEST GHOST: Blood 	See 	Travel
SACRIFICE: 		Hell 	Blood 	Join
DRAIN BLOOD: 	Travel 	Blood 	Self
BLOOD BOIL: 	Destroy See 	Blood

*/

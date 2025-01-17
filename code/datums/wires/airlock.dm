// Wires for airlocks


var/const/AIRLOCK_WIRE_IDSCAN = 1
var/const/AIRLOCK_WIRE_MAIN_POWER1 = 2
var/const/AIRLOCK_WIRE_MAIN_POWER2 = 4
var/const/AIRLOCK_WIRE_DOOR_BOLTS = 8
var/const/AIRLOCK_WIRE_BACKUP_POWER1 = 16
var/const/AIRLOCK_WIRE_BACKUP_POWER2 = 32
var/const/AIRLOCK_WIRE_OPEN_DOOR = 64
var/const/AIRLOCK_WIRE_AI_CONTROL = 128
var/const/AIRLOCK_WIRE_ELECTRIFY = 256
var/const/AIRLOCK_WIRE_SAFETY = 512
var/const/AIRLOCK_WIRE_SPEED = 1024
var/const/AIRLOCK_WIRE_LIGHT = 2048
var/const/AIRLOCK_WIRE_ONOPEN = 4096

/datum/wires/airlock/secure
	random = 1

/datum/wires/airlock
	holder_type = /obj/machinery/door/airlock
	wire_count = 13
	window_y = 570

/datum/wires/airlock/New()
	wire_names=list(
		"[AIRLOCK_WIRE_IDSCAN]"        = "ID Scan",
		"[AIRLOCK_WIRE_MAIN_POWER1]"   = "Main Power 1",
		"[AIRLOCK_WIRE_MAIN_POWER2]"   = "Main Power 2",
		"[AIRLOCK_WIRE_DOOR_BOLTS]"    = "Bolts",
		"[AIRLOCK_WIRE_BACKUP_POWER1]" = "Backup Power 1",
		"[AIRLOCK_WIRE_BACKUP_POWER2]" = "Backup Power 2",
		"[AIRLOCK_WIRE_OPEN_DOOR]"     = "Open",
		"[AIRLOCK_WIRE_AI_CONTROL]"    = "AI Control",
		"[AIRLOCK_WIRE_ELECTRIFY]"     = "Electrify",
		"[AIRLOCK_WIRE_SAFETY]"        = "Safety",
		"[AIRLOCK_WIRE_SPEED]"         = "Speed",
		"[AIRLOCK_WIRE_LIGHT]"         = "Lights",
		"[AIRLOCK_WIRE_ONOPEN]"        = "On Open"
	)
	..()

/datum/wires/airlock/CanUse(var/mob/living/L)
	if(!..())
		return 0
	var/obj/machinery/door/airlock/A = holder
	if(!istype(L, /mob/living/silicon))
		if(A.isElectrified())
			var/obj/I = L.get_active_hand()
			A.shock(L, 100, get_conductivity(I))
	if(A.panel_open)
		return 1
	return 0

/datum/wires/airlock/GetInteractWindow()
	var/obj/machinery/door/airlock/A = holder
	. += ..()
	. += text("<br>\n[]<br>\n[]<br>\n[]<br>\n[]<br>\n[]<br>\n[]", (A.locked ? "The door bolts have fallen!" : "The door bolts [A.boltsDestroyed ? "have been chopped!" : "look up."]"),
	(A.lights ? "The door bolt lights are on." : "The door bolt lights are off!"),
	((A.arePowerSystemsOn() && !(A.stat & NOPOWER)) ? "The test light is on." : "The test light is off!"),
	(A.aiControlDisabled==0 ? "The 'AI control allowed' light is on." : "The 'AI control allowed' light is off."),
	(A.safe==0 ? "The 'Check Wiring' light is on." : "The 'Check Wiring' light is off."),
	(A.normalspeed==0 ? "The 'Check Timing Mechanism' light is on." : "The 'Check Timing Mechanism' light is off."))


/datum/wires/airlock/UpdateCut(var/index, var/mended, mob/user)
	var/obj/machinery/door/airlock/A = holder
	var/obj/I = user.get_active_hand()
	..()
	switch(index)
		if(AIRLOCK_WIRE_MAIN_POWER1, AIRLOCK_WIRE_MAIN_POWER2)

			if(!mended)
				//Cutting either one disables the main door power, but unless backup power is also cut, the backup power re-powers the door in 10 seconds. While unpowered, the door may be crowbarred open, but bolts-raising will not work. Cutting these wires may electocute the user.
				A.loseMainPower()
				A.shock(user, 50, get_conductivity(I))
			else
				if((!IsIndexCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!IsIndexCut(AIRLOCK_WIRE_MAIN_POWER2)))
					A.regainMainPower()
					A.shock(user, 50, get_conductivity(I))

		if(AIRLOCK_WIRE_BACKUP_POWER1, AIRLOCK_WIRE_BACKUP_POWER2)

			if(!mended)
				//Cutting either one disables the backup door power (allowing it to be crowbarred open, but disabling bolts-raising), but may electocute the user.
				A.loseBackupPower()
				A.shock(user, 50, get_conductivity(I))
			else
				if((!IsIndexCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!IsIndexCut(AIRLOCK_WIRE_BACKUP_POWER2)))
					A.regainBackupPower()
					A.shock(user, 50, get_conductivity(I))

		if(AIRLOCK_WIRE_DOOR_BOLTS)

			if(!mended)
				//Cutting this wire also drops the door bolts, and mending it does not raise them. (This is what happens now, except there are a lot more wires going to door bolts at present)
				if(A.locked!=1)
					A.locked = A.boltsDestroyed ? 0 : 1
				A.update_icon()

		if(AIRLOCK_WIRE_AI_CONTROL)

			if(!mended)
				//one wire for AI control. Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
				//aiControlDisabled: If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock.
				A.disable_AI_control()
			else
				A.enable_AI_control()

		if(AIRLOCK_WIRE_ELECTRIFY)

			if(!mended)
				//Cutting this wire electrifies the door, so that the next person to touch the door without insulated gloves gets electrocuted.
				A.shockedby += text("\[[time_stamp()]\][user](ckey:[user.ckey])")
				A.secondsElectrified = -1
			else
				A.secondsElectrified = 0

		if (AIRLOCK_WIRE_SAFETY)
			A.safe = mended

		if(AIRLOCK_WIRE_SPEED)
			A.autoclose = mended
			if(mended)
				if(!A.density)
					A.close()

		if(AIRLOCK_WIRE_LIGHT)
			A.lights = mended
			A.update_icon()

/datum/wires/airlock/UpdatePulsed(var/index, mob/user)
	var/obj/machinery/door/airlock/A = holder
	..()
	switch(index)
		if(AIRLOCK_WIRE_IDSCAN)
			//Sending a pulse through this flashes the red light on the door (if the door has power).
			if((A.arePowerSystemsOn()) && (!(A.stat & NOPOWER)) && A.density)
				A.door_animate("deny")
		if(AIRLOCK_WIRE_MAIN_POWER1, AIRLOCK_WIRE_MAIN_POWER2)
			//Sending a pulse through either one causes a breaker to trip, disabling the door for 10 seconds if backup power is connected, or 1 minute if not (or until backup power comes back on, whichever is shorter).
			A.loseMainPower()
		if(AIRLOCK_WIRE_DOOR_BOLTS)
			//one wire for door bolts. Sending a pulse through this drops door bolts if they're not down (whether power's on or not),
			//raises them if they are down (only if power's on)
			if(!A.locked)
				A.locked = A.boltsDestroyed ? 0 : 1
				playsound(A, "sound/machines/door_bolt.ogg", 50, 1, -1)
				for(var/mob/M in range(1, A))
					to_chat(M, "You hear a metallic clunk from the bottom of the door.")
			else
				if(A.arePowerSystemsOn()) //only can raise bolts if power's on
					A.locked = 0
					playsound(A, "sound/machines/door_unbolt.ogg", 50, 1, -1)
					for(var/mob/M in range(1, A))
						to_chat(M, "You hear a metallic clunk from the bottom of the door.")
			A.update_icon()

		if(AIRLOCK_WIRE_BACKUP_POWER1, AIRLOCK_WIRE_BACKUP_POWER2)
			//two wires for backup power. Sending a pulse through either one causes a breaker to trip, but this does not disable it unless main power is down too (in which case it is disabled for 1 minute or however long it takes main power to come back, whichever is shorter).
			A.loseBackupPower()
		if(AIRLOCK_WIRE_AI_CONTROL)
			if(A.aiControlDisabled == 0)
				A.disable_AI_control()

			spawn(10)
				if(A)
					if(A.aiControlDisabled == 1)
						A.enable_AI_control()

		if(AIRLOCK_WIRE_ELECTRIFY)
			//one wire for electrifying the door. Sending a pulse through this electrifies the door for 30 seconds.
			if(A.secondsElectrified==0)
				A.shockedby += text("\[[time_stamp()]\][user](ckey:[user.ckey])")
				A.secondsElectrified = 30
				spawn(10)
					if(A)
						//TODO: Move this into process() and make pulsing reset secondsElectrified to 30
						while (A.secondsElectrified>0)
							A.secondsElectrified-=1
							if(A.secondsElectrified<0)
								A.secondsElectrified = 0
							sleep(10)
		if(AIRLOCK_WIRE_OPEN_DOOR)
			//tries to open the door without ID
			//will succeed only if the ID wire is cut or the door requires no access
			for(var/mob/M in range(1, A))
				to_chat(M, "<span class = 'notice'>You see \the [holder]'s keypad blink green for a second.</span>")
			if(!A.requiresID() || A.check_access(null))
				if(A.density)
					A.open()
				else
					A.close()
		if(AIRLOCK_WIRE_SAFETY)
			A.safe = !A.safe
			if(!A.density)
				A.close()

		if(AIRLOCK_WIRE_SPEED)
			A.normalspeed = !A.normalspeed

		if(AIRLOCK_WIRE_LIGHT)
			A.lights = !A.lights
			A.update_icon()

		if(AIRLOCK_WIRE_ONOPEN)
			A.visible_message("<span class = 'notice'>\The [A]'s motors whirr.</span>")
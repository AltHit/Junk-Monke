var/global/obj/machinery/ars_silo/active_SILO
var/global/list/active_RSS


/obj/machinery/ars_silo
	name = "automated material exchange silo"
	desc = "Stores the materials sold by the AME network."
	icon = 'icons/obj/machines/squaremachines.dmi'
	icon_state = "silo"
	// layer = BELOW_OBJ_LAYER
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 1000	//same as bluespace relay


// :: ID
	var/current_logged_id

// :: MATERIALS
	var/list/materials_blacklist = list(	// WOOD IS FREE. BIOMATTER IS BAD.
		MATERIAL_WOOD,
		MATERIAL_BIOMATTER)
	var/alist/contained_material_sheets

// :: MONEY
	var/inserted_money

/obj/machinery/ars_silo/New()
	..()
	if(!active_SILO)
		active_SILO = src
		return
	visible_message(span_warning("CAUTION! ACTIVE SILO DETECTED. TO AVOID TRANSACTIONAL OVERLAP, CURRENT SILO REMAINS INACTIVE. ACTIVE SILO POSITION: X[active_SILO.x], Y[active_SILO.y], Z[active_SILO.z]"))
	//[!] get other silo position here!!!!

/obj/machinery/ars_silo/Destroy()
	..()
	if(src == active_SILO)
		active_SILO = null

/obj/machinery/ars_silo/LateInitialize()
	..()
	update_icon()
	var/area/areatocheck = get_area(src)
	if(areatocheck.vessel != "CEV Eris")
		return FALSE



/obj/machinery/ars_silo/attackby(obj/item/I, mob/living/user)
	if(user.incapacitated())
		return

	switch(istype(I))
		if(/obj/item/spacecash)
			var/obj/item/spacecash/cash = I
			inserted_money += cash.worth
			qdel(I)
			return
		if(/obj/item/stack/material/)
			if(I in materials_blacklist)
				to_chat(user, span_warning("THIS MATERIAL IS BANNED!"))
				return
			var/obj/item/stack/material/sheets = I
			contained_material_sheets[get_material_by_name(I.name)] += sheets.amount

				//bad red visual for vendor here
			//add material

	if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_BOLT_TURNING, FAILCHANCE_EASY, required_stat = STAT_MEC))
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		user.visible_message( \
			span_notice("\The [user] unfastens \the [src]."), \
			span_notice("You have unfastened \the [src]."), \
			"You hear a ratchet.")
		return







// ---------------------------------------------------------------------------------------------------------------------------------------------------------








/obj/machinery/amerecycler
	name = "Reclamation System Station"
	desc = "Recycle today for a better tomorrow!"
	icon = 'icons/obj/vending.dmi'
	icon_state = "recycle"
	layer = BELOW_OBJ_LAYER
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 211	//same as softdrinks vendor

// :: MATERIALS
	var/list/materials_blacklist = list(	// WOOD IS FREE. BIOMATTER IS BAD.
		MATERIAL_WOOD,
		MATERIAL_BIOMATTER)
	var/alist/contained_material_sheets

// :: MONEY
	var/inserted_money


/obj/machinery/amerecycler/New(loc, ...)
	. = ..()
	update_icon()

/obj/machinery/amerecycler/LateInitialize()
	. = ..()


/obj/machinery/amerecycler/Destroy()
	eject_stored_item()
	..()


/obj/machinery/amerecycler/update_icon()
	overlays.Cut()
	if(stat & BROKEN)
		icon_state = "recycle_broken"
		return

	icon_state = "recycle"

	if(stat & NOPOWER || !anchored)
		return

	if(stat & NOPOWER)
		overlays += "recycle_screen_red"
		overlays += "recycle_button_top_red"
		overlays += "recycle_button_bottom_red"
	else
		overlays += "recycle_screen_green"
		overlays += "recycle_button_top_green"
		overlays += "recycle_button_bottom_green"

	if(panel_open)
		overlays += "recycle_panel"

/obj/machinery/amerecycler/power_change()
	..()
	update_icon()


// :: INTERACTABLE CODE

/obj/machinery/amerecycler/attackby(obj/item/I, mob/living/user)
	if(user.incapacitated())
		return

	switch(istype(I))
		if(/obj/item/spacecash)
			var/obj/item/spacecash/cash = I
			inserted_money += cash.worth
			qdel(I)
			return
		if(/obj/item/stack/material/)
			if(I in materials_blacklist)
				to_chat(user, span_warning("THIS MATERIAL IS BANNED!"))
				return
			var/obj/item/stack/material/sheets = I
			contained_material_sheets[get_material_by_name(I.name)] += sheets.amount

				//bad red visual for vendor here
			//add material

	if(I.use_tool(user, src, WORKTIME_FAST, QUALITY_BOLT_TURNING, FAILCHANCE_EASY, required_stat = STAT_MEC))
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
		user.visible_message( \
			span_notice("\The [user] unfastens \the [src]."), \
			span_notice("You have unfastened \the [src]."), \
			"You hear a ratchet.")
		return








/obj/machinery/amerecycler/attack_hand(mob/user)
	if(user.incapacitated())
		return

	ui_interact(user)


/obj/machinery/amerecycler/AltClick(mob/user)
	if(user.incapacitated())
		return

	eject_stored_item()


/obj/machinery/amerecycler/proc/eject_stored_item(obj/stored_item_object)
	if(stored_item_object)
		stored_item_object.forceMove(loc)
	flick("recycle_vend", src)
	update_icon()

/obj/machinery/amerecycler/proc/recycle_and_output(obj/itemtorecycle)


/obj/machinery/amerecycler/Process()
	if(stat & (BROKEN|NOPOWER))
		return

	if(prob(1)) // Flag is set when value is not default
		speak(pick(
			"Bitch, don\'t you wanna start making some real fucking money?!",
			"Recycle. Everybody\'s doing it.",
			"Recycling is the only option.",
			"Recycling is a cool thing to do.",
			"Recycling Rocks.",
			"I pity the fool who doesn\'t recycle."))


/obj/machinery/amerecycler/ui_status()
	. = ..()
	if(stat & NOPOWER)
		. = UI_DISABLED


/obj/machinery/amerecycler/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FrontNode")
		ui.open()

/obj/machinery/amerecycler/ui_data(mob/user)
	var/list/data = list()
	var/access = user.GetAccess()


	return data

/obj/machinery/amerecycler/ui_act(action, params)




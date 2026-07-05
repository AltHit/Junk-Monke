/global/active_SILO
/global/list/active_RSS


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

	var/list/materials_blacklist = list(	// WOOD IS FREE. BIOMATTER IS BAD.
		MATERIAL_WOOD,
		MATERIAL_BIOMATTER)

/obj/machinery/ars_silo/New()
	..()
	if(!active_SILO)
		active_SILO = src
		return
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
	if(BITTEST(wire_flags, WIRE_SHOCK) && shock(user, 100))
		return

	switch(istype(I))
		if(/obj/item/spacecash/)
			inserted_money += I.worth
			qdel(I)
			return
		if(/obj/item/stack/material/)
			if(I in materials_blacklist)
				to_chat(user, span_warning("THIS MATERIAL IS BANNED!"))
				return
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

// :: ID
	var/current_logged_id

// :: WIRES
	var/datum/wires/recycle_vendor/wires
	var/wire_flags = 0

// :: BACKGROUND CODE


/obj/machinery/amerecycler/New(loc, ...)
	. = ..()
	wires = new(src)
	update_icon()

/obj/machinery/amerecycler/LateInitialize()
	. = ..()


/obj/machinery/amerecycler/Destroy()
	qdel(wires)
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

	if(!silo || silo?.stat & NOPOWER)
		overlays += "recycle_screen_red"
		overlays += "recycle_button_top_red"
		overlays += "recycle_button_bottom_red"
	else
		overlays += sales_paused				? "recycle_screen_red"			: "recycle_screen_green"
		overlays += silo.materials_stored.len	? "recycle_button_top_green"	: "recycle_button_top_red"
		overlays += silo.budget > 500			? "recycle_button_bottom_green"	: "recycle_button_bottom_red"

	if(panel_open)
		overlays += "recycle_panel"

/obj/machinery/amerecycler/power_change()
	..()
	update_icon()


// :: INTERACTABLE CODE

/obj/machinery/amerecycler/attackby(obj/item/I, mob/living/user)
	if(user.incapacitated())
		return
	if(BITTEST(wire_flags, WIRE_SHOCK) && shock(user, 100))
		return

	switch(istype(I))
		if(/obj/item/spacecash/)
			inserted_money += I.worth
			qdel(I)
		if(/obj/item/stack/material/)








/obj/machinery/amerecycler/attack_hand(mob/user)
	if(user.incapacitated())
		return

	if(BITTEST(wire_flags, WIRE_SHOCK) && shock(user, 100))
		return

	ui_interact(user)


/obj/machinery/amerecycler/AltClick(mob/user)
	if(user.incapacitated())
		return

	eject_stored_item()


/obj/machinery/amerecycler/proc/eject_stored_item(obj/stored_item_object)
	if(stored_item_object)
		stored_item_object.forceMove(loc)
		if(stored_item_object in saleworthy_items)
			saleworthy_items.Remove(stored_item_object)
	else
		for(var/obj/item/item in saleworthy_items)
			item.forceMove(loc)
		saleworthy_items.Cut()

	flick("recycle_vend", src)
	update_icon()


/obj/machinery/amerecycler/emag_act(remaining_charges, mob/user, emag_source)
	. = ..()
	sales_paused = TRUE
	to_chat(user, span_notice("[src]'s display flashes red."))
	update_icon()

/obj/machinery/amerecycler/proc/evaluate_stored_item(obj/evaluated)
	if(!silo)
		return FALSE // if there is no silo, it is not stored

	var/valueofitem = 0
	var/list/intermediary = evaluated.get_matter()
	var/matsinitem = intermediary?.Copy()
	for(var/obj/O in evaluated.GetAllContents()) // can now recycle empty shells to get at the contents
		if(length(O.get_matter()))
			matsinitem += O.get_matter()
	if(length(matsinitem) < 1)
		return FALSE
	for(var/i in matsinitem)
		if(!(i in silo.materials_supported)) // determine all materials are suitable
			return FALSE // if it does not contain the right materials, it is not stored
		var/material/mat = get_material_by_name(i)
		var/obj/item/stack/material/M = mat.stack_type
		valueofitem += initial(M.price_tag) * matsinitem[i]
	saleworthy_items[evaluated] = valueofitem // add this to the list
	. = TRUE // and store it


/obj/machinery/amerecycler/proc/recycle_and_pay(obj/itemtorecycle)
	var/combinedvalue = 0
	var/list/stufftorecycle = list()
	if(silo.stat & NOPOWER)
		flick("recycle_screen_red", overlays[1])
		return
	else if(itemtorecycle)
		stufftorecycle.Add(itemtorecycle)
	else
		stufftorecycle |= saleworthy_items
	if(!length(stufftorecycle))
		return
	for(var/toadd in stufftorecycle)
		combinedvalue += round(saleworthy_items[toadd] * 0.8) // 20% fee on vendor, rounded up.
	if(!combinedvalue || combinedvalue > silo?.my_account.money) // can we afford it all?
		flick("recycle_screen_red", overlays[1])
		if(!BITTEST(wire_flags, WIRE_SPEAKER))
			audible_message("[src] outputs \"Error: Funding Insufficient.\"")
		return
	var/list/combinedmats = list()
	for(var/obj/item/getthisone in stufftorecycle)
		var/list/intermediary = getthisone.get_matter()
		var/list/matter = intermediary?.Copy()
		for(var/obj/O in getthisone.GetAllContents()) // can now recycle empty shells to get at the contents
			if(length(O.get_matter()))
				matter += O.get_matter()
		for(var/toadd in matter)
			combinedmats[toadd] += matter[toadd]
		var/sellvalue = saleworthy_items[getthisone] * 0.8 // 20% fee
		sellvalue = round(sellvalue) // don't make it round and you won't lose your money
		var/datum/transaction/T = new(-sellvalue, "", "Recycling payout for [getthisone.name]", src)
		T.apply_to(silo.my_account)
		qdel(getthisone) // we first add the item to the garbage queue

	if(length(stufftorecycle) > 1)
		saleworthy_items.Cut() // we melted it all, because we could afford it all.
	else
		saleworthy_items.Remove(stufftorecycle[1])
	stufftorecycle = null // then we remove what should be the remaining references
	playsound(loc, pick('sound/items/polaroid1.ogg', 'sound/items/polaroid2.ogg'), 50, 1)
	silo.addmaterial(combinedmats)
	spawn_money(combinedvalue, loc)
	use_power(vend_power_usage)
	silo.updatesubsidy()
	flick("recycle_vend", src)
	update_icon()

	if(combinedvalue < 50 && prob(10)) // selling less than around 32 sheets worth at a time is awfully small
		speak("Ты бы еще консервных банок насобирал!")

/obj/machinery/amerecycler/proc/recycle_and_output(obj/itemtorecycle)
	if(!silo || silo.stat & NOPOWER)
		flick("recycle_screen_red", overlays[1])
		return
	var/list/stufftorecycle = list()
	if(itemtorecycle)
		stufftorecycle.Add(itemtorecycle)
	else
		stufftorecycle |= saleworthy_items
	if(!length(stufftorecycle))
		return
	var/combinedvalue = 0
	for(var/currentitem in stufftorecycle)
		combinedvalue += CEILING(saleworthy_items[currentitem] / 5, 1) // add all the fees together, rounded as it actually does.
	if(combinedvalue > moneyinput) // if it's too much, cancel it all
		flick("recycle_screen_red", overlays[1])
		if(!BITTEST(wire_flags, WIRE_SPEAKER))
			audible_message("[src] outputs \"Error: Input Insufficient.\"")
		return FALSE
	var/list/totalmaterials = list()
	for(var/obj/currentitem in stufftorecycle)
		var/currentitemsvalue = saleworthy_items[currentitem] // key is item, item value is associated with item
		var/list/intermediary = currentitem.get_matter()
		var/currentitemmaterials = intermediary?.Copy()
		for(var/obj/O in currentitem.GetAllContents()) // can now recycle empty shells to get at the contents
			if(length(O.get_matter()))
				currentitemmaterials += O.get_matter()
		for(var/materialtype in currentitemmaterials) // add them together so they can stack
			var/amount = currentitemmaterials[materialtype]
			totalmaterials[materialtype] += amount
		currentitemsvalue *= 0.2 // 20% fee to recycle
		currentitemsvalue = CEILING(currentitemsvalue, 1) // good luck keeping your money here, although this is still cheaper than rounding twice
		moneyinput -= currentitemsvalue
		var/datum/transaction/T = new(currentitemsvalue, "", "Recycling fee for [currentitem.name]", src)
		T.apply_to(silo.my_account)
		silo.taxdebt += currentitemsvalue/32
		qdel(currentitem) // we first add the item to the garbage queue

	if(length(stufftorecycle) > 1)
		saleworthy_items.Cut() // we melted it all, because we could afford it all.
	else
		saleworthy_items.Remove(stufftorecycle[1])
	stufftorecycle = null // then we remove what should be the remaining references

	for(var/materialtype in totalmaterials) // actually spawn the stacks
		var/amount = totalmaterials[materialtype]
		var/material/materialfound = get_material_by_name(materialtype)
		var/obj/item/stack/material/stackspawned = materialfound.stack_type
		if(stackspawned) // ensure the stack has a type
			var/maxamount = initial(stackspawned.max_amount)
			var/flat = maxamount*round(amount/maxamount) // some are full if this is positive
			var/remainder = amount - flat // and one's not if this is positive
			if(flat)
				for(var/increment = 1; increment < round(amount/maxamount); increment++)
					stackspawned = new materialfound.stack_type(get_turf(src))
					stackspawned.amount = maxamount
					stackspawned.update_strings()
					stackspawned.update_icon()
			if(remainder)
				stackspawned = new materialfound.stack_type(get_turf(src))
				stackspawned.amount = remainder
				stackspawned.update_strings()
				stackspawned.update_icon()
	flick("recycle_vend", src)

/obj/machinery/amerecycler/Process()
	if(stat & (BROKEN|NOPOWER))
		return

	if(!BITTEST(wire_flags, WIRE_SPEAKER) && prob(1)) // Flag is set when value is not default
		speak(pick(
			"Bitch, don\'t you wanna start making some real fucking money?!",
			"Recycle. Everybody\'s doing it.",
			"Recycling is the only option.",
			"Recycling is a cool thing to do.",
			"Recycling Rocks.",
			"I pity the fool who doesn\'t recycle."))

	if(BITTEST(wire_flags, WIRE_THROW) && prob(2))
		throw_item()


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
	var/access = BITTEST(wire_flags, WIRE_ID_SCAN) ? list() : user.GetAccess() // grab the access if the scanner works

	data["salesactive"] = sales_paused ? null :TRUE
	data["budget"] = silo?.my_account?.money
	data["siloactive"] = (isnull(silo) || silo.stat & NOPOWER) ? null :TRUE // TGUI does not use FALSE as its boolean false

	data["dosh"] = moneyinput
	var/list/itemnamearray = list() // TGUI can only access arrays flexibly when they are not associated
	var/list/itempricearray = list() // so we have to separate the lists into arrays with matching indexes
	var/list/itemiconarray = list()
	for(var/obj/data2do in saleworthy_items)
		itemnamearray.Add(data2do.name) // string as item name
		itempricearray.Add(saleworthy_items[data2do])
		itemiconarray.Add(icon2base64html(data2do.type)) // whatever html formatted images are
	data["itemnames"] = itemnamearray
	data["icons"] = itemiconarray
	data["itemprices"] = itempricearray
	if(silo) // display the config and material exchange
		if(silo.required_access in access)
			data["authorization"] = TRUE
		var/list/maticonarray = list()
		var/list/matnumarray = list()
		var/list/matnamearray = list()
		var/list/matvaluearray = list()
		for(var/mat in silo.materials_stored)
			var/material/currentmat = get_material_by_name(mat)
			matnamearray.Add(currentmat.name)// string as mat name
			var/obj/item/stack/material/currentstack = currentmat.stack_type
			matvaluearray.Add(initial(currentstack.price_tag)) // num
			maticonarray.Add(icon2base64html(currentstack)) // string as html?? icon??
			matnumarray.Add(silo.materials_stored[mat]) // num
		data["matnums"] = matnumarray
		data["matnames"] = matnamearray
		data["matvalues"] = matvaluearray
		data["maticons"] = maticonarray

	return data

/obj/machinery/amerecycler/ui_act(action, params)
	. = ..()
	if(get_dist(usr, src) > 1) // remote operation is not currently legal, if you want to allow a case, change this check.
		. = TRUE
	if(.)
		return
	if(silo && !(silo.stat & NOPOWER))
		switch(action)
			if("sell_item")
				if(params["chosen"])
					if(params["chosen"] > length(saleworthy_items))
						return FALSE
					recycle_and_pay(saleworthy_items[params["chosen"]])
				else
					recycle_and_pay()
				return TRUE
			if("recycle_item")
				if(params["chosen"])
					if(params["chosen"] > length(saleworthy_items))
						return FALSE

					recycle_and_output(saleworthy_items[params["chosen"]])
				else
					recycle_and_output()
				return TRUE
			if("buy_mat")
				var/buyamount = params["amount"]
				if(params["matselected"] > length(silo.materials_stored))
					return FALSE
				var/materialtobuy = silo.materials_stored[params["matselected"]]
				buyamount = clamp(buyamount, 0, silo.materials_stored[materialtobuy])
				var/material/middlemat = get_material_by_name(materialtobuy) // this only exists to allow reading the var
				var/obj/item/stack/material/toread = middlemat.stack_type
				var/buyprice = initial(toread.price_tag) * buyamount * 1.2
				if(moneyinput < buyprice)
					return FALSE
				moneyinput -= buyprice
				var/datum/transaction/T = new(buyprice, "", "Material Purchase", src)
				T.apply_to(silo.my_account)
				silo.taxdebt += buyprice/32
				silo.ejectmaterial(materialtobuy, buyamount, get_turf(src))
				flick("recycle_vend", src)
				. = TRUE

	switch(action) // these ones are local
		if("toggle_sales")
			var/obj/item/card/id/IDToCheck = BITTEST(wire_flags, WIRE_ID_SCAN) ? list() : usr.GetIdCard() // grab the access if the scanner works
			if(silo.required_access in IDToCheck.access)
				sales_paused = !sales_paused
			else
				return TRUE

		if("eject_item")
			if(params["chosen"] > length(saleworthy_items))
				return FALSE
			eject_stored_item(saleworthy_items[params["chosen"]])
			flick("recycle_vend", src)
			return TRUE

		if("ejectdosh")
			if(moneyinput <= 0)
				return FALSE
			spawn_money(moneyinput, get_turf(src), usr)
			flick("recycle_vend", src)
			moneyinput = 0
			return TRUE
	update_icon()

#define MINIMUM_BUDGET 800 // tax purposes


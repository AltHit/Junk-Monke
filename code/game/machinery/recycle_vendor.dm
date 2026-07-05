/obj/machinery/amerecycler
	name = "recycling and material vendor"
	desc = "Recycle today for a better tomorrow!"
	icon = 'icons/obj/vending.dmi'
	icon_state = "recycle"
	layer = BELOW_OBJ_LAYER
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 211	//same as softdrinks vendor
	var/vend_power_usage = 500

	var/obj/machinery/amesilo/silo
	var/wire_flags = 0
//
//
//

/obj/machinery/amerecycler/New(loc, ...)
	. = ..()
	update_icon()

/obj/machinery/amerecycler/LateInitialize()
	. = ..()

/obj/machinery/amerecycler/Destroy()
	eject_stored_item()
	..()



/obj/machinery/amesilo
	name = "automated material exchange silo"
	desc = "Stores the materials sold by the AME network."
	icon = 'icons/obj/machines/squaremachines.dmi'
	icon_state = "silo"
	layer = BELOW_OBJ_LAYER
	anchored = TRUE
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 1000	//same as bluespace relay
	var/prime = FALSE

	// Can't use subtypeof(), since we have lots of useless materials
	var/list/materials_supported = list(
		MATERIAL_STEEL,
		MATERIAL_GLASS,
		MATERIAL_PLASTIC,
		MATERIAL_WOOD,
		MATERIAL_SILVER,
		MATERIAL_GOLD,
		MATERIAL_URANIUM,
		MATERIAL_CARDBOARD,
		MATERIAL_PLASMA,
		MATERIAL_PLATINUM,
		MATERIAL_PLASTEEL,
		MATERIAL_DIAMOND,
		MATERIAL_PLASMAGLASS)
	var/list/materials_stored = list()
	var/budget = 4000
	var/maxcapacity = 8640 // 12 level 3 matter bins applied to the highcapacity lathes
	var/sellthreshold = 7920 // after 11, the threshold is met
	var/required_access
	var/datum/money_account/moneycard
	var/obj/item/spacecash/ewallet/chargecard
	var/taxdebt = 0

/obj/machinery/amesilo/LateInitialize()
	. = ..()
	update_icon()
	var/area/areatocheck = get_area(src)
	if(areatocheck.vessel != "CEV Eris") // this machine pays taxes, and so should you.
		return FALSE

/// @function scr_ui_tooltip()
/// @category UI
/// @description Handles tooltip logics around the main play screen
function scr_ui_tooltip() {
    if ((selected != noone) && (!instance_exists(selected))) {
        selected = noone;
    }
    if (zoomed != 0) {
        exit;
    }

    var xx = camera_get_view_x(view_camera[0]);
    var yy = camera_get_view_y(view_camera[0]);
    var tooltip = "";

    // Requisition income tooltip
    if (scr_hit(xx + 5, yy + 10, xx + 137, yy + 38)) {
        tooltip = L("Requisition Points");
        tooltip += LF("\nBase Income: {0}{1}", [income_base > 0 ? "+" : "", income_base]);
        if (obj_ini.fleet_type == ePLAYER_BASE.HOME_WORLD) {
            if (income_home > 0) {
                tooltip += LF("\nFortress Monastery Bonus: +{0}", [income_home]);
            }
            if (income_forge > 0) {
                tooltip += LF("\nNearby Forge Worlds: +{0}", [income_forge]);
            }
            if (income_agri > 0) {
                tooltip += LF("\nNearby Agri Worlds: +{0}", [income_agri]);
            }
        }
        if (obj_ini.fleet_type != ePLAYER_BASE.HOME_WORLD) {
            tooltip += LF("\nBattle Barge Trade: {0}{1}", [income_home > 0 ? "+" : "", income_home]);
        }
        if (income_training != 0) {
            tooltip += LF("\nSpecialist Training: {0}{1}", [income_training > 0 ? "+" : "", income_training]);
        }
        if (income_fleet != 0) {
            tooltip += LF("\nFleet Maintenance: {0}{1}", [income_fleet > 0 ? "+" : "", income_fleet]);
        }
        if (income_tribute != 0) {
            tooltip += LF("\nPlanet Tithes: {0}{1}", [income_tribute > 0 ? "+" : "", income_tribute]);
        }

        if (tooltip != "") {
            tooltip_draw(tooltip, 400);
        }
    }

    // Current Loyalty tooltip
    if (scr_hit(xx + 247, yy + 10, xx + 328, yy + 38)) {
        for (var i = 1; i <= 20; i++) {
            if (loyal_num[i] > 1) {
                tooltip += string(loyal[i]) + ": -" + string(loyal_num[i]) + "#";
            }
        }

        if (tooltip != "") {
            tooltip_draw(tooltip);
        } else {
            tooltip_draw(L("Loyalty"));
        }
    }

    // Stored Gene-Seed tooltip
    if (scr_hit(xx + 373, yy + 10, xx + 443, yy + 38)) {
        tooltip = L("Gene-Seed") + "#" + obj_controller.apothecary_string;
        tooltip_draw(tooltip);
    }
    // Current Astartes tooltip
    if (scr_hit(xx + 478, yy + 3, xx + 552, yy + 38)) {
        tooltip = L("Astartes (Normal/Command)") + "#" + string(obj_controller.marines);
        tooltip_draw(tooltip);
    }
    // Turn tooltip
    if ((menu == eMENU.DEFAULT) && (diplomacy <= 0)) {
        if (scr_hit(xx + 1435, yy + 40, xx + 1580, yy + 267)) {
            tooltip = LF("Turn :{0}", [obj_controller.turn]);
            tooltip_draw(tooltip);
        }
    }
    // Forge Points income tooltip
    if (scr_hit(xx + 153, yy + 10, xx + 241, yy + 38)) {
        tooltip_draw(obj_controller.forge_string);
    }

    // Penitence/Blood Debt tooltip
    if (scr_hit(xx + 923, yy + 10, xx + 1060, yy + 38) && (penitent == 1)) {
        var bd_decay_rate = min(0, (((penitent_turn + 1) * (penitent_turn + 1)) - 512) * -1);

        if (obj_controller.blood_debt == 1) {
            tooltip = L("Blood Spilled: ") + string(penitent_current);
            tooltip += "#" + L("Blood Debt: ") + string(penitent_max);
            tooltip += "#" + L("Decay Rate: ") + string(bd_decay_rate);

            tooltip += L("##Attacking enemies, Raiding enemies, and losing Astartes will lower your Chapter's Blood Debt.  Over time it decays.  Bombarding enemies will prevent decay.");
        }
        if (obj_controller.blood_debt == 0) {
            tooltip = L("Current Penitence: ") + string(penitent_current);
            tooltip += "#" + L("Required Penitence: ") + string(penitent_max);

            tooltip += L("##Penitence will be gained slowly over time.  After the timer runs out your Chapter will no longer be considered Penitent.");
        }

        if (tooltip != "") {
            tooltip_draw(tooltip);
        }
    }
}

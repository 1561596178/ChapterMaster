draw_set_font(fnt_40k_14b);
draw_set_halign(fa_left);
draw_set_color(CM_GREEN_COLOR);

if ((alerts > 0) && (popups_end == 1)) {
    for (var i = 0; i < alerts; i++) {
        var _alert = alerts_list[i];
        set_alert_draw_colour(_alert.colour);
        draw_set_alpha(min(1, _alert.alpha));
        draw_text(32, 46 + ((i + 1) * 20), string_hash_to_newline(string(_alert.txt)));
    }
}

draw_set_alpha(1);
draw_set_font(fnt_small);
draw_set_halign(fa_left);
draw_set_color(255);

if (obj_controller.force_scroll == 1) {
    exit;
}

if (combating > 0) {
    exit;
}
if (obj_controller.audience > 0) {
    exit;
}

if ((show == 0) && (current_popup == 0)) {
    draw_sprite(spr_loading, image_index, 23, 73);
}

if ((show > 0) && (current_battle <= battles)) {
    var xxx = 535;
    var yyy = 200;
    var i = current_battle;

    draw_sprite(spr_purge_panel, 0, xxx, yyy);
    if (battle_world[i] == 0) {
        scr_image("attacked", 1, xxx + 12, yyy + 54, 254, 174);
    }
    if (battle_world[i] > 0) {
        scr_image("attacked", 0, xxx + 12, yyy + 54, 254, 174);
    }

    draw_set_font(fnt_40k_14);
    draw_set_halign(fa_left);
    draw_set_color(c_gray);
    draw_text(xxx + 8, yyy + 13, string_hash_to_newline(string(i) + "/" + string(battles)));

    draw_set_halign(fa_center);
    draw_set_font(fnt_40k_30b);

    if (battle_world[i] > 0) {
        draw_text_transformed(xxx + 265, yyy + 11, string_hash_to_newline(LF("Forces Attacked! ({0} {1})", [battle_location[i], scr_roman(battle_world[i])])), 0.7, 0.7, 0);
    }
    if (battle_world[i] == 0) {
        draw_text_transformed(xxx + 265, yyy + 11, string_hash_to_newline(LF("Fleet Attacked! ({0} System)", [battle_location[i]])), 0.7, 0.7, 0);
    }

    scr_image("ui/force", 1, xxx + 346, yyy + 54, 64, 64);

    draw_set_font(fnt_40k_14);
    draw_set_halign(fa_left);

    if (battle_world[i] == 0) {
        draw_set_font(fnt_40k_14b);
        draw_set_halign(fa_left);

        draw_text(xxx + 12, yyy + 237, L("Enemy Fleets:"));
        draw_text(xxx + 332, yyy + 237, L("Allied Fleets:"));

        if (string(strin[1]) == "1") {
            draw_text(xxx + 310, yyy + 118, string_hash_to_newline(LF("{0} Battleship ({1}% HP)", [strin[1], strin[4]])));
        }
        if (string(strin[2]) == "1") {
            draw_text(xxx + 310, yyy + 138, string_hash_to_newline(LF("{0} Frigate ({1}% HP)", [strin[2], strin[5]])));
        }
        if (string(strin[3]) == "1") {
            draw_text(xxx + 310, yyy + 158, string_hash_to_newline(LF("{0} Escort ({1}% HP)", [strin[3], strin[6]])));
        }
        if (string(strin[1]) != "1") {
            draw_text(xxx + 310, yyy + 118, string_hash_to_newline(LF("{0} Battleships ({1}% HP)", [strin[1], strin[4]])));
        }
        if (string(strin[2]) != "1") {
            draw_text(xxx + 310, yyy + 138, string_hash_to_newline(LF("{0} Frigates ({1}% HP)", [strin[2], strin[5]])));
        }
        if (string(strin[3]) != "1") {
            draw_text(xxx + 310, yyy + 158, string_hash_to_newline(LF("{0} Escorts ({1}% HP)", [strin[3], strin[6]])));
        }

        draw_set_halign(fa_center);

        if (enemy_fleet[1] != 0) {
            scr_image("ui/force", enemy_fleet[1], xxx + 12, yyy + 237, 64, 64);
            var shw = "";
            if (ecap[1] == 1) {
                shw += LF("{0} Battleship#", [ecap[1]]);
            }
            if (ecap[1] != 1) {
                shw += LF("{0} Battleships#", [ecap[1]]);
            }
            if (efri[1] == 1) {
                shw += LF("{0} Frigate#", [efri[1]]);
            }
            if (efri[1] != 1) {
                shw += LF("{0} Frigates#", [efri[1]]);
            }
            if (eesc[1] == 1) {
                shw += LF("{0} Escort#", [eesc[1]]);
            }
            if (eesc[1] != 1) {
                shw += LF("{0} Escorts#", [eesc[1]]);
            }

            draw_text_transformed(xxx + 44, yyy + 286, string_hash_to_newline(shw), 0.7, 1, 0);
            draw_set_halign(fa_center);
            draw_set_font(fnt_40k_14b);
        }
        if (enemy_fleet[2] != 0) {
            scr_image("ui/force", enemy_fleet[2], xxx + 122, yyy + 237, 64, 64);
            var shw = "";
            if (ecap[2] == 1) {
                shw += LF("{0} Battleship#", [ecap[2]]);
            }
            if (ecap[2] != 1) {
                shw += LF("{0} Battleships#", [ecap[2]]);
            }
            if (efri[2] == 1) {
                shw += LF("{0} Frigate#", [efri[2]]);
            }
            if (efri[2] != 1) {
                shw += LF("{0} Frigates#", [efri[2]]);
            }
            if (eesc[2] == 1) {
                shw += LF("{0} Escort#", [eesc[2]]);
            }
            if (eesc[2] != 1) {
                shw += LF("{0} Escorts#", [eesc[2]]);
            }

            draw_text_transformed(xxx + 154, yyy + 286, string_hash_to_newline(shw), 0.7, 1, 0);
            draw_set_halign(fa_center);
            draw_set_font(fnt_40k_14b);
        }
        if (enemy_fleet[3] != 0) {
            scr_image("ui/force", enemy_fleet[3], xxx + 232, yyy + 237, 64, 64);
            var shw = "";
            if (ecap[3] == 1) {
                shw += LF("{0} Battleship#", [ecap[3]]);
            }
            if (ecap[3] != 1) {
                shw += LF("{0} Battleships#", [ecap[3]]);
            }
            if (efri[3] == 1) {
                shw += LF("{0} Frigate#", [efri[3]]);
            }
            if (efri[3] != 1) {
                shw += LF("{0} Frigates#", [efri[3]]);
            }
            if (eesc[3] == 1) {
                shw += LF("{0} Escort#", [eesc[3]]);
            }
            if (eesc[3] != 1) {
                shw += LF("{0} Escorts#", [eesc[3]]);
            }

            draw_text_transformed(xxx + 264, yyy + 286, string_hash_to_newline(shw), 0.7, 1, 0);
            draw_set_halign(fa_center);
            draw_set_font(fnt_40k_14b);
        }

        if (allied_fleet[1] != 0) {
            scr_image("ui/force", allied_fleet[1], xxx + 342, yyy + 237, 64, 64);
            var shw = "";
            if (acap[1] == 1) {
                shw += LF("{0} Battleship#", [acap[1]]);
            }
            if (acap[1] != 1) {
                shw += LF("{0} Battleships#", [acap[1]]);
            }
            if (afri[1] == 1) {
                shw += LF("{0} Frigate#", [afri[1]]);
            }
            if (afri[1] != 1) {
                shw += LF("{0} Frigates#", [afri[1]]);
            }
            if (aesc[1] == 1) {
                shw += LF("{0} Escort#", [aesc[1]]);
            }
            if (aesc[1] != 1) {
                shw += LF("{0} Escorts#", [aesc[1]]);
            }

            draw_text_transformed(xxx + 374, yyy + 286, string_hash_to_newline(shw), 0.7, 1, 0);
            draw_set_halign(fa_center);
            draw_set_font(fnt_40k_14b);
        }
        if (allied_fleet[2] != 0) {
            scr_image("ui/force", allied_fleet[2], xxx + 452, yyy + 237, 64, 64);
            var shw = "";
            if (acap[2] == 1) {
                shw += LF("{0} Battleship#", [acap[2]]);
            }
            if (acap[2] != 1) {
                shw += LF("{0} Battleships#", [acap[2]]);
            }
            if (afri[2] == 1) {
                shw += LF("{0} Frigate#", [afri[2]]);
            }
            if (afri[2] != 1) {
                shw += LF("{0} Frigates#", [afri[2]]);
            }
            if (aesc[2] == 1) {
                shw += LF("{0} Escort#", [aesc[2]]);
            }
            if (aesc[2] != 1) {
                shw += LF("{0} Escorts#", [aesc[2]]);
            }

            draw_text_transformed(xxx + 484, yyy + 286, string_hash_to_newline(shw), 0.7, 1, 0);
            draw_set_halign(fa_center);
            draw_set_font(fnt_40k_14b);
        }

        draw_set_color(c_gray);
        draw_rectangle(xxx + 132, yyy + 354, xxx + 259, yyy + 389, 0);
        draw_set_color(0);
        draw_text_transformed(xxx + 195, yyy + 362, L("Retreat"), 1.1, 1.1, 0);
        if (scr_hit(xxx + 132, yyy + 354, xxx + 259, yyy + 389)) {
            draw_set_alpha(0.2);
            draw_rectangle(xxx + 132, yyy + 354, xxx + 259, yyy + 389, 0);
            draw_set_alpha(1);
        }

        draw_set_color(c_gray);
        draw_rectangle(xxx + 272, yyy + 354, xxx + 399, yyy + 389, 0);
        draw_set_color(0);
        draw_text_transformed(xxx + 335, yyy + 362, L("Fight"), 1.1, 1.1, 0);
        if (scr_hit(xxx + 272, yyy + 354, xxx + 399, yyy + 389)) {
            draw_set_alpha(0.2);
            draw_rectangle(xxx + 272, yyy + 354, xxx + 399, yyy + 389, 0);
            draw_set_alpha(1);
        }
    }

    if (battle_world[i] >= 1) {
        if (battle_opponent[i] <= 20) {
            draw_text(xxx + 310, yyy + 118, string_hash_to_newline(LF("{0} Marines", [strin[1]])));
            draw_text(xxx + 310, yyy + 138, string_hash_to_newline(LF("{0} Vehicles", [strin[2]])));
            if (strin[3] != "") {
                draw_text(xxx + 310, yyy + 158, string_hash_to_newline(LF("{0} Fortified", [strin[3]])));
            } // Not / Barely / Lightly / Moderately / Highly / Maximally
        }

        draw_set_font(fnt_40k_14b);
        draw_set_halign(fa_left);

        draw_text(xxx + 12, yyy + 237, L("Enemy Factions:"));
        draw_text(xxx + 332, yyy + 237, L("Allies:"));

        draw_set_halign(fa_center);
        scr_image("ui/force", battle_opponent[i], xxx + 12, yyy + 257, 64, 64);
        draw_text_transformed(xxx + 44, yyy + 316, string_hash_to_newline(string(strin[4])), 0.75, 1, 0);
        draw_set_halign(fa_center);
        draw_set_font(fnt_40k_14b);

        draw_set_color(c_gray);
        draw_rectangle(xxx + 132, yyy + 354, xxx + 259, yyy + 389, 0);
        draw_set_color(0);
        draw_text_transformed(xxx + 195, yyy + 362, L("Offensive"), 1.1, 1.1, 0);
        if (scr_hit(xxx + 132, yyy + 354, xxx + 259, yyy + 389)) {
            draw_set_alpha(0.2);
            draw_rectangle(xxx + 132, yyy + 354, xxx + 259, yyy + 389, 0);
            draw_set_alpha(1);
        }

        draw_set_color(c_gray);
        draw_rectangle(xxx + 272, yyy + 354, xxx + 399, yyy + 389, 0);
        draw_set_color(0);
        draw_text_transformed(xxx + 335, yyy + 362, L("Defensive"), 1.1, 1.1, 0);
        if (scr_hit(xxx + 272, yyy + 354, xxx + 399, yyy + 389)) {
            draw_set_alpha(0.2);
            draw_rectangle(xxx + 272, yyy + 354, xxx + 399, yyy + 389, 0);
            draw_set_alpha(1);
        }
    }
}

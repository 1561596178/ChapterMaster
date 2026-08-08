/// @function add_battle_log_message
/// @param {string} _message - The message text to add to the battle log
/// @param {real} [_message_color=0] - The color enum value (0=default, eMSG_COLOR.*)
/// @returns {bool} Success indicator
function add_battle_log_message(_message, _message_color = eMSG_COLOR.WHITE) {
    if (instance_exists(obj_ncombat)) {
        obj_ncombat.combat_log.push(_message, _message_color);
        obj_ncombat.alarm[3] = 2;
        return true;
    }
    return false;
}

/// @desc Plural form of a weapon name. Names that are already plural (end in "s", e.g.
///       "Twin Linked Bolters") are left as-is so we don't print "Bolterss".
/// @param {string} _name The weapon name.
/// @returns {string}
function weapon_name_plural(_name) {
    return _name + ((string_char_at(_name, string_length(_name)) == "s") ? "" : "s");
}

/// @desc Logs one "held fire" line for weapons that had no live target left to shoot at, e.g.
///       when an earlier volley wiped the enemy before the rest of the squad fired.
/// @param {Array} _weapon_names Raw weapon names (duplicates allowed) that never fired.
function report_held_fire(_weapon_names) {
    // Dedupe and pluralise.
    var _unique = [];
    for (var i = 0; i < array_length(_weapon_names); i++) {
        var _p = weapon_name_plural(_weapon_names[i]);
        if (array_get_index(_unique, _p) == -1) {
            array_push(_unique, _p);
        }
    }

    var _count = array_length(_unique);
    if (_count == 0) {
        return;
    }

    // Build "A, B, and C" (or "A and B", or "A").
    var _list = string_join_oxford_comma(_unique);

    add_battle_log_message(LF("{0} held fire lacking live targets.", [_list]), eMSG_COLOR.WHITE);
}

function scr_flavor(id_of_attacking_weapons, target, target_type, number_of_shots, casulties, shots_bounced = false, _defer = false) {
    // Generates flavor based on the damage and casualties from scr_shoot, only for the player
    // shots_bounced: true when armour stopped the shots outright (AP too low) and nothing died,
    // so the log can explain *why* instead of a flat "no casualties".
    // _defer: when true, build the message but DON'T post it; return it so the caller can append a
    // spill-over kill list and post a single consolidated line (see emit_volley_flavour).

    // Clamp away any negative casualty count so it can never render as "-1". Every volley now earns
    // a line: a kill, a wound (injured, no kill), or an armour-bounce. The latter two are consolidated
    // per target by emit_volley_flavour / combat_tally_*.
    if (casulties < 0) {
        casulties = 0;
    }

    var attack_message, kill_message, leader_message, targeh;
    targeh = target_type;
    leader_message = "";
    attack_message = $"";
    kill_message = "";

    // Guard/diagnostic: a non-killing volley against a rank with no living models means we fired at a
    // dead target. Shouldn't happen now that emptied formations are destroyed - log it if it does and
    // bail, so it can never feed the consolidated non-pen / wound feed. (Spill-over kills, if any, are
    // still reported by emit_volley_flavour's undefined-primary path.)
    if (casulties <= 0 && (!instance_exists(target) || target.dudes_num[targeh] <= 0)) {
        LOGGER.warning(LF("scr_flavor: shot at a dead target (weapon stack {0}, rank {1})", [id_of_attacking_weapons, targeh]));
        exit;
    }

    var weapon_name = wep[id_of_attacking_weapons];

    if (id_of_attacking_weapons == -51) {
        weapon_name = "Heavy Bolter Emplacement";
    }
    if (id_of_attacking_weapons == -52) {
        weapon_name = "Missile Launcher Emplacement";
    }
    if (id_of_attacking_weapons == -53) {
        weapon_name = "Missile Silo";
    }

    // Plural form for "{n} {weapon}s ..." lines (see weapon_name_plural).
    var weapon_plural = weapon_name_plural(weapon_name);

    var weapon_data = gear_weapon_data("weapon", weapon_name, "all");
    if (!is_struct(weapon_data)) {
        weapon_data = new EquipmentStruct({}, "");
        weapon_data.name = weapon_name;
    }

    var target_name = target.dudes[targeh];

    if ((target_name == "Leader") && (obj_ncombat.enemy <= eFACTION.CHAOS)) {
        target_name = obj_controller.faction_leader[obj_ncombat.enemy];
    }

    var character_shot = false, unit_name = "", cm_kill = 0;

    if (id_of_attacking_weapons > 0) {
        if (array_length(wep_solo[id_of_attacking_weapons]) > 0) {
            character_shot = true;
            full_names = wep_solo[id_of_attacking_weapons];
            if (wep_title[id_of_attacking_weapons] != "") {
                if (array_length(full_names) == 1) {
                    unit_name = wep_title[id_of_attacking_weapons] + " " + wep_solo[id_of_attacking_weapons][0];
                } else {
                    unit_name = wep_title[id_of_attacking_weapons];
                }
            }
            if (wep_solo[id_of_attacking_weapons][0] == obj_ini.master_name) {
                cm_kill = 1;
            }
        }
    }

    if ((obj_ncombat.battle_special == "WL10_reveal") || (obj_ncombat.battle_special == "WL10_later")) {
        if ((target_name == "Veteran Chaos Terminator") && (target_name > 0)) {
            obj_ncombat.chaos_angry += casulties * 2;
        }
        if ((target_name == "Veteran Chaos Chosen") && (target_name > 0)) {
            obj_ncombat.chaos_angry += casulties;
        }
        if (target_name == "Greater Daemon of Slaanesh") {
            obj_ncombat.chaos_angry += casulties * 5;
        }
        if (target_name == "Greater Daemon of Tzeentch") {
            obj_ncombat.chaos_angry += casulties * 5;
        }
    }

    if ((target.flank == 1) && (target.flyer == 0)) {
        target_name = "flanking " + target_name;
    }

    // Firing subject for consolidated lines: "<name> <weapon>" for a titled character, "The <weapon>"
    // for a lone shot, or "<n> <weapons>" for a volley (also used when a unit has no title, e.g. Dreadnoughts).
    var firing_subject;
    if (character_shot && unit_name != "") {
        if (number_of_shots > 1) {
            // Grouped titled units (e.g. several Dreadnoughts share one "Dreadnought" title) — show the count.
            firing_subject = $"{number_of_shots} {string(unit_name)} {weapon_plural}";
        } else {
            firing_subject = $"{string(unit_name)} {weapon_name}";
        }
    } else if (number_of_shots == 1) {
        firing_subject = $"The {weapon_name}";
    } else {
        firing_subject = $"{number_of_shots} {weapon_plural}";
    }

    var flavoured = false;

    if (weapon_data.has_tag("bolt")) {
        flavoured = true;
        if (!character_shot) {
            if (obj_ncombat.bolter_drilling == 1) {
                attack_message += "With perfect accuracy ";
            }
            if (number_of_shots < 200) {
                if (target.dudes_num[targeh] == 1) {
                    if (casulties == 0) {
                        attack_message += LF("{0} {1} fire. The {2} is hit but survives.", [number_of_shots, weapon_plural, target_name]);
                    } else {
                        attack_message += LF("{0} {1} fire. The {2} is struck down.", [number_of_shots, weapon_plural, target_name]);
                    }
                } else {
                    if (casulties == 0) {
                        attack_message += LF("{0} {1} fire at {2} ranks without causing casualties.", [number_of_shots, weapon_plural, target_name]);
                    } else {
                        attack_message += LF("{0} {1} strike {2} ranks, taking down {3}.", [number_of_shots, weapon_plural, target_name, casulties]);
                    }
                }
            } else {
                if (target.dudes_num[targeh] == 1) {
                    if (casulties == 0) {
                        attack_message += LF("{0} {1} fire. Explosions rock the {2}'s armour but don't kill it.", [number_of_shots, weapon_plural, target_name]);
                    } else {
                        attack_message += LF("{0} {1} fire. Explosions take down the {2}.", [number_of_shots, weapon_plural, target_name]);
                    }
                } else {
                    if (casulties == 0) {
                        attack_message += LF("{0} {1} hit {2} ranks, but no casualties are confirmed.", [number_of_shots, weapon_plural, target_name]);
                    } else {
                        attack_message += LF("{0} {1} tear through {2} ranks, instantly killing {3}.", [number_of_shots, weapon_plural, target_name, casulties]);
                    }
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += $"{string(unit_name)} fires his {weapon_name} at the {target_name} but fails to kill it.";
                } else {
                    attack_message += $"{string(unit_name)} eliminates the {target_name} with his {weapon_name}.";
                }
            } else {
                if (casulties == 0) {
                    attack_message += $"{string(unit_name)} fires his {weapon_name} at {target_name} ranks but fails to kill any.";
                } else {
                    attack_message += $"{string(unit_name)} takes down {casulties} {target_name} with his {weapon_name}.";
                }
            }
        }
    } else if (weapon_name == "Hammer of Wrath" || weapon_name == "Hammer of Wrath(M)") {
        flavoured = true;
        if (!character_shot) {
            if (number_of_shots < 20) {
                attack_message += LF("{0} Astartes with Jump Packs soar upwards, flames roaring. They plummet back down upon the enemy- ", [number_of_shots]);
            } else if (number_of_shots >= 20 && number_of_shots < 100) {
                attack_message += LF("Squads of {0} Astartes ascend with roaring Jump Packs. They descend upon the enemy- ", [number_of_shots]);
            } else {
                attack_message += LF("A massive wave of {0} Astartes rise, their Jump Packs a furious beast. They crash down, smashing their foe- ", [number_of_shots]);
            }
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += LF("but the {0} endures the onslaught.", [target_name]);
                } else {
                    attack_message += LF("the {0} falls to the charge.", [target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message += LF("{0} ranks are hit, but no casualties are confirmed.", [target_name]);
                } else {
                    attack_message += LF("{0} ranks are hit, killing {1} in an instant.", [target_name, casulties]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                attack_message += string(unit_name) + LF(" engages his Jump Pack, soaring and crashing into the {0}- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but it endures the onslaught.";
                } else {
                    attack_message += $"and it falls to the charge.";
                }
            } else {
                attack_message += string(unit_name) + LF(" activates his Jump Pack, slamming into {0} ranks- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but all survive the impact.";
                } else {
                    attack_message += LF("and {0} are crushed in the impact.", [casulties]);
                }
            }
        }
    } else if (weapon_name == "Speed Force" || weapon_name == "Speed Force(M)") {
        flavoured = true;
        if (!character_shot) {
            if (number_of_shots < 20) {
                attack_message += LF("{0} Astartes on Bikes speed ahead, their Bikes roaring like beasts of old- ", [number_of_shots]);
            } else if (number_of_shots >= 20 && number_of_shots < 100) {
                attack_message += LF("Squads of {0} Astartes thunder ahead on their Bikes. They descend upon the enemy- ", [number_of_shots]);
            } else {
                attack_message += LF("A massive wave of {0} Astartes rolls ahead on top of their mighty Bikes. They crash into enemy lines, smashing their foe- ", [number_of_shots]);
            }
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += LF("but the {0} endures the onslaught.", [target_name]);
                } else {
                    attack_message += LF("the {0} falls to the charge.", [target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message += LF("{0} ranks are hit, but no casualties are confirmed.", [target_name]);
                } else {
                    attack_message += LF("{0} ranks are hit, killing {1} in an instant.", [target_name, casulties]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                attack_message += string(unit_name) + LF(" speeds on his bike, roaring and crashing into the {0}- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but it endures the onslaught.";
                } else {
                    attack_message += $"and it falls to the charge.";
                }
            } else {
                attack_message += string(unit_name) + LF(" speeds on his bike, slamming into {0} ranks- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but all survive the impact.";
                } else {
                    attack_message += LF("crushing {0} beneath his wheels.", [casulties]);
                }
            }
        }
    } else if (weapon_name == "Speed Force (Ranged)") {
        flavoured = true;
        if (!character_shot) {
            if (number_of_shots < 20) {
                attack_message += LF("{0} Attack Bikes race across the field, sidecar gunners hosing down the enemy on the move- ", [number_of_shots]);
            } else if (number_of_shots >= 20 && number_of_shots < 100) {
                attack_message += LF("A column of {0} Attack Bikes sweeps past, heavy weapons hammering away in a thunderous strafing run- ", [number_of_shots]);
            } else {
                attack_message += LF("A roaring tide of {0} Attack Bikes tears along the line, sidecar guns blazing without pause- ", [number_of_shots]);
            }
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += LF("but the {0} weathers the fusillade.", [target_name]);
                } else {
                    attack_message += LF("and the {0} is gunned down where it stands.", [target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message += LF("{0} ranks are raked with fire, but none fall.", [target_name]);
                } else {
                    attack_message += LF("cutting down {0} {1} in the pass.", [casulties, target_name]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                attack_message += string(unit_name) + LF(" guns his Attack Bike past the {0}, sidecar weapon roaring- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but it endures the barrage.";
                } else {
                    attack_message += $"and it is torn apart.";
                }
            } else {
                attack_message += string(unit_name) + LF(" sweeps his Attack Bike along {0} ranks, raking them with fire- ", [target_name]);
                if (casulties == 0) {
                    attack_message += $"but all survive the onslaught.";
                } else {
                    attack_message += LF("cutting down {0} in the pass.", [casulties]);
                }
            }
        }
    } else if (string_contains("RAM", weapon_name)) {
        flavoured = true;
        if (!character_shot) {
            if (number_of_shots < 10) {
                attack_message += LF("{0} vehicles thunder forward, armoured hulls crashing into the enemy lines- ", [number_of_shots]);
            } else {
                attack_message += LF("An armoured column of {0} vehicles smashes into the enemy, grinding everything in its path- ", [number_of_shots]);
            }
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += LF("but the {0} withstands the impact.", [target_name]);
                } else {
                    attack_message += LF("the {0} is crushed beneath their treads.", [target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message += LF("{0} ranks scatter before the charge, but no casualties are confirmed.", [target_name]);
                } else {
                    attack_message += LF("{0} ranks are crushed, killing {1} in the onslaught.", [target_name, casulties]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                attack_message += LF("{0} rams into the {1}- ", [unit_name, target_name]);
                if (casulties == 0) {
                    attack_message += $"but it endures the impact.";
                } else {
                    attack_message += $"and it is shattered.";
                }
            } else {
                attack_message += LF("{0} rams into {1} ranks- ", [unit_name, target_name]);
                if (casulties == 0) {
                    attack_message += $"but they all survive the impact.";
                } else {
                    attack_message += LF("crushing {0} beneath its hull.", [casulties]);
                }
            }
        }
    } else if (weapon_name == "Assault Cannon") {
        flavoured = true;
        if (!character_shot) {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += LF("{0} {1} roar, explosions clap across the armour of the {2} but it remains standing.", [number_of_shots, weapon_plural, target_name]);
                } else {
                    attack_message += LF("{0} {1} fire at the {2} and rip it apart.", [number_of_shots, weapon_plural, target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message += LF("{0} {1} thunder, {2} are rocked but unharmed.", [number_of_shots, weapon_plural, target_name]);
                } else {
                    attack_message += LF("{0} {1} mow down {2} {3}.", [number_of_shots, weapon_plural, casulties, target_name]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message += $"{string(unit_name)} {weapon_name} fires but the {target_name} survives.";
                } else {
                    attack_message += $"{string(unit_name)} obliterates the {target_name} with the {weapon_name}.";
                }
            } else {
                if (casulties == 0) {
                    attack_message += $"{string(unit_name)} {weapon_name} fails to breach {target_name} ranks.";
                } else {
                    attack_message += $"{string(unit_name)} cuts down {casulties} {target_name} with the {weapon_name}.";
                }
            }
        }
    } else if (weapon_name == "Missile Launcher") {
        flavoured = true;
        if (!character_shot) {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message = LF("{0} {1} fire upon the {2} but it remains standing.", [number_of_shots, weapon_plural, target_name]);
                } else {
                    attack_message = LF("{0} {1} blast the {2} to oblivion.", [number_of_shots, weapon_plural, target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message = LF("{0} {1} hit {2} ranks but they hold firm.", [number_of_shots, weapon_plural, target_name]);
                } else {
                    attack_message = LF("{0} {1} pulverize {2} {3}.", [number_of_shots, weapon_plural, casulties, target_name]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message = $"{string(unit_name)} {weapon_name} fires upon the {target_name} but it survives.";
                } else {
                    attack_message = $"{string(unit_name)} obliterates {target_name} with the {weapon_name}.";
                }
            } else {
                if (casulties == 0) {
                    attack_message = $"{string(unit_name)} {weapon_name} fails to inflict damage upon {target_name} ranks.";
                } else {
                    attack_message = $"{string(unit_name)} pulverizes {casulties} {target_name} with the {weapon_name}.";
                }
            }
        }
    } else if (weapon_name == "Whirlwind Missiles") {
        flavoured = true;
        if (!character_shot) {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message = LF("{0} Whirlwinds fire upon the {1} but it remains standing.", [number_of_shots, target_name]);
                } else {
                    attack_message = LF("{0} Whirlwinds blast {1} to oblivion.", [number_of_shots, target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message = LF("{0} Whirlwinds hit {1} ranks but they hold firm.", [number_of_shots, target_name]);
                } else {
                    attack_message = LF("{0} Whirlwinds pulverize {1} {2}.", [number_of_shots, casulties, target_name]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message = LF("Whirlwind fires upon the {0} but it survives.", [target_name]);
                } else {
                    attack_message = LF("Whirlwind obliterates the {0}.", [target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message = LF("Whirlwind fails to inflict damage upon {0} ranks.", [target_name]);
                } else {
                    attack_message = LF("Whirlwind pulverizes {0} {1}.", [casulties, target_name]);
                }
            }
        }
    } else if (weapon_name == "Melee") {
        flavoured = true;
        var ra = choose(1, 2, 3, 4);
        // This needs to be worked out
        if (casulties == 0) {
            attack_message = LF("{0} engaged in hand-to-hand combat, no casualties.", [target_name]);
        }
        if (casulties > 0) {
            attack_message = LF("{0} ranks ", [target_name]);
            if (ra == 1) {
                attack_message += "are struck with gun-barrels and fists.";
            }
            if (ra == 2) {
                attack_message += "are savaged by your marines in hand-to-hand combat.";
            }
            if (ra == 3) {
                attack_message += "are smashed by your marines.";
            }
            if (ra == 4) {
                attack_message += "are struck by your marines in melee.";
            }
            attack_message += LF(" {0} killed.", [casulties]);
        }
    } else if (weapon_name == "Force Staff") {
        flavoured = true;
        if (number_of_shots == 1) {
            attack_message = LF("{0} is blasted by the {1}.", [target_name, weapon_name]);
        }
        if (number_of_shots > 1) {
            attack_message = LF("{0} {1} crackle and swing into the {2} ranks, killing {3}.", [number_of_shots, weapon_name, target_name, casulties]);
        }
    } else if (weapon_data.has_tag("plasma")) {
        flavoured = true;
        if ((target.dudes_num[targeh] == 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} shoot bolts of energy into a {2}, failing to kill it.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] == 1) && (casulties == 1)) {
            attack_message = LF("{0} {1} overwhelm a {2} with bolts of energy, killing {3}.", [number_of_shots, weapon_name, target_name, casulties]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} shoot bolts of energy into the {2} ranks, failing to kill any.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties > 0)) {
            attack_message = LF("{0} {1} shoot bolts of energy into the {2}, cleansing {3}.", [number_of_shots, weapon_name, target_name, casulties]);
        }
    } else if (weapon_data.has_tag("flame")) {
        flavoured = true;
        if ((target.dudes_num[targeh] == 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} bathe the {2} in holy promethium, failing to kill it.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] == 1) && (casulties == 1)) {
            attack_message = LF("{0} {1} flash-fry the {2} inside its armour, inflicting {3}.", [number_of_shots, weapon_name, target_name, casulties]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} wash over the {2} ranks, failing to kill any.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties > 0)) {
            attack_message = LF("{0} {1} bathe the {2} ranks in holy promethium, cleansing {3}.", [number_of_shots, weapon_name, target_name, casulties]);
        }
    } else if (weapon_name == "Webber") {
        flavoured = true;
        if (((target_name == "Termagaunt") || (target_name == "Hormagaunt")) && (casulties > 0)) {
            obj_ncombat.captured_gaunt += casulties;
        }
        if ((target.dudes_num[targeh] == 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} spray ooze on the {2} but fail to immobilize it.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] == 1) && (casulties == 1)) {
            attack_message = LF("{0} {1} spray ooze on the {2} and fully immobilize it.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} spray ooze on the {2} ranks, failing to immobilize any.", [number_of_shots, weapon_name, target_name]);
        }
        if ((target.dudes_num[targeh] > 1) && (casulties > 0)) {
            attack_message = LF("{0} {1} spray ooze on the {2} ranks and immobilize {3} of them.", [number_of_shots, weapon_name, target_name, casulties]);
        }
    } else if (weapon_name == "Close Combat Weapon") {
        flavoured = true;
        if ((number_of_shots == 1) && (casulties == 0)) {
            attack_message = LF("{0} is struck by ", [target_name]) + string(obj_ini.role[100][6]) + " but survives.";
        }
        if ((number_of_shots == 1) && (casulties == 1)) {
            attack_message = LF("{0} is struck down by ", [target_name]) + string(obj_ini.role[100][6]) + ".";
        }
        if ((number_of_shots > 1) && (casulties == 0)) {
            attack_message = $"{number_of_shots} {string(obj_ini.role[100][6])}s wrench and smash at {target_name} but fail to destroy it.";
        }
        if ((number_of_shots > 1) && (casulties > 1)) {
            attack_message = $"{number_of_shots} {string(obj_ini.role[100][6])}s stomp, wrench, and smash {casulties} {target_name} into paste.";
        }
    } else if (weapon_name == "Chainsword") {
        flavoured = true;
        if ((number_of_shots == 1) && (casulties == 0)) {
            attack_message = LF("{0} is struck by a {1} but survives.", [target_name, weapon_name]);
        }
        if ((number_of_shots == 1) && (casulties == 1)) {
            attack_message = LF("{0} is cut down by a {1}.", [target_name, weapon_name]);
        }
        if ((number_of_shots > 1) && (casulties == 0)) {
            attack_message = LF("{0} motors rev and hack at the {1} ranks, but don't kill any.", [number_of_shots, target_name]);
        }
        if ((number_of_shots > 1) && (casulties > 0)) {
            attack_message = LF("{0} motors rev and hack away at the {1} ranks. {2} are cut down.", [number_of_shots, target_name, casulties]);
        }
    } else if (weapon_name == "Sarissa") {
        flavoured = true;
        if ((number_of_shots == 1) && (casulties == 0)) {
            attack_message = LF("A {0} is struck by a Battle Sister's {1} but survives.", [target_name, weapon_name]);
        }
        if ((number_of_shots == 1) && (casulties == 1)) {
            attack_message = LF("A {0} is struck down by a Battle Sister's {1}.", [target_name, weapon_name]);
        }
        if ((number_of_shots > 1) && (casulties == 0)) {
            attack_message = $"Battle Sisters " + choose("howl out", "roar") + $" and hack at {target_name} ranks with their {weapon_plural}, but they survive.";
        }
        if ((number_of_shots > 1) && (casulties > 0)) {
            attack_message = LF("{0} Battle Sisters ", [number_of_shots]) + choose("howl out", "roar") + $" as they hack away at the {target_name} ranks, killing {casulties} with their {weapon_plural}.";
        }
    } else if (weapon_name == "Eviscerator") {
        flavoured = true;
        if ((number_of_shots == 1) && (casulties == 0)) {
            attack_message = LF("A {0} is struck by a {1} but survives.", [target_name, weapon_name]);
        }
        if ((number_of_shots == 1) && (casulties == 1)) {
            attack_message = LF("A {0} is cut down by a {1}.", [target_name, weapon_name]);
        }
        if ((number_of_shots > 1) && (casulties == 0)) {
            attack_message = LF("{0} {1} rev and howl, hacking at the {2} ranks, failing to kill any.", [number_of_shots, weapon_name, target_name]);
        }
        if ((number_of_shots > 1) && (casulties > 0)) {
            attack_message = LF("{0} {1} rev and howl, hacking at the {2} ranks, {3} are cut down.", [number_of_shots, weapon_name, target_name, casulties]);
        }
    } else if (weapon_name == "Dozer Blades") {
        flavoured = true;
        if ((number_of_shots == 1) && (casulties == 0)) {
            attack_message = LF("A {0} is rammed but survives.", [target_name]);
        }
        if ((number_of_shots == 1) && (casulties == 1)) {
            attack_message = LF("A {0} is splattered by {1}.", [target_name, weapon_name]);
        }
        if ((number_of_shots > 1) && (casulties == 0)) {
            attack_message = LF("{0} ploughs {1} ranks , inflicting {2}.", [weapon_name, target_name, casulties]);
        }
        if ((number_of_shots > 1) && (casulties > 0)) {
            attack_message = LF("{0} hits {1} ranks , inflicting {2}.  ", [weapon_name, target_name, casulties]) + string(casulties) + " are smashed.";
        }
    } else if (weapon_data.has_tag("power")) {
        flavoured = true;
        if (target.dudes_num[targeh] == 1) {
            if ((number_of_shots == 1) && (casulties == 0)) {
                attack_message = LF("A {0} is struck by a {1} but survives.", [target_name, weapon_name]);
            }
            if ((number_of_shots == 1) && (casulties == 1)) {
                attack_message = LF("A {0} is struck down by a {1}.", [target_name, weapon_name]);
            }

            if ((number_of_shots > 1) && (casulties == 0)) {
                attack_message = LF("A {0} is struck by {1} {2} but survives.", [target_name, number_of_shots, weapon_plural]);
            }
            if ((number_of_shots > 1) && (casulties == 1)) {
                attack_message = LF("A {0} is struck down by {1} {2}.", [target_name, number_of_shots, weapon_plural]);
            }
        }
        if (target.dudes_num[targeh] > 1) {
            if ((number_of_shots > 1) && (casulties == 0)) {
                attack_message = LF("{0} {1} crackle and spark, striking at the {2} ranks, inflicting no damage.", [number_of_shots, weapon_plural, target_name]);
            }
            if ((number_of_shots > 1) && (casulties > 0)) {
                attack_message = LF("{0} {1} crackle and spark, hewing through the {2} ranks, {3} are cut down.", [number_of_shots, weapon_plural, target_name, casulties]);
            }
        }
    }

    // A fallback flavour
    if (flavoured == false) {
        flavoured = true;
        if (!character_shot) {
            if (target.dudes_num[targeh] == 1) {
                if (number_of_shots == 1 && casulties == 0) {
                    attack_message = LF("A {0} is struck by {1} but survives.", [target_name, weapon_name]);
                } else if (number_of_shots == 1 && casulties == 1) {
                    attack_message = LF("A {0} is struck down by {1}.", [target_name, weapon_name]);
                } else if (number_of_shots > 1 && casulties == 0) {
                    attack_message = LF("A {0} is struck by {1} {2} but survives.", [target_name, number_of_shots, weapon_plural]);
                } else if (number_of_shots > 1 && casulties == 1) {
                    attack_message = LF("A {0} is struck down by {1} {2}.", [target_name, number_of_shots, weapon_plural]);
                }
            } else {
                if (number_of_shots == 1 && casulties == 0) {
                    attack_message = LF("{0} strikes at {1} but they survive.", [weapon_name, target_name]);
                } else if (number_of_shots == 1 && casulties > 0) {
                    attack_message = LF("{0} strikes at {1} and kills {2}", [weapon_name, target_name, casulties]);
                } else if (number_of_shots > 1 && casulties == 0) {
                    attack_message = LF("{0} {1} strike at the {2} ranks, but fail to inflict damage.", [number_of_shots, weapon_plural, target_name]);
                } else if (number_of_shots > 1 && casulties > 0) {
                    attack_message = LF("{0} {1} strike at the {2} ranks, killing {3}.", [number_of_shots, weapon_plural, target_name, casulties]);
                }
            }
        } else {
            if (target.dudes_num[targeh] == 1) {
                if (casulties == 0) {
                    attack_message = LF("{0} strikes at a {1} but fails to kill it.", [firing_subject, target_name]);
                } else {
                    attack_message = LF("{0} strikes at a {1}, killing it.", [firing_subject, target_name]);
                }
            } else {
                if (casulties == 0) {
                    attack_message = LF("{0} strikes at the {1} ranks, failing to kill any.", [firing_subject, target_name]);
                } else {
                    attack_message = LF("{0} strikes at the {1} ranks and kills {2}.", [firing_subject, target_name, casulties]);
                }
            }
        }
    }

    // Reason-aware override: armour stopped the shots cold (AP too low). Replaces whatever
    // generic "no casualties" text the branches produced with something that explains why.
    if (shots_bounced && casulties == 0) {
        flavoured = true;
        if (character_shot) {
            attack_message = $"{string(unit_name)} {weapon_name} strikes the {target_name} but fails to penetrate its armour.";
        } else if (number_of_shots == 1) {
            attack_message = LF("The {0} strikes the {1} but fails to penetrate its armour.", [weapon_name, target_name]);
        } else if (weapon_data.has_tag("bolt")) {
            attack_message = LF("{0} {1} hammer the {2} but spark harmlessly off its armour.", [number_of_shots, weapon_plural, target_name]);
        } else if (weapon_data.has_tag("flame")) {
            attack_message = LF("{0} {1} wash over the {2} but its armour endures the flames.", [number_of_shots, weapon_plural, target_name]);
        } else if (weapon_data.has_tag("power")) {
            attack_message = LF("{0} {1} strike the {2} but glance off its armour.", [number_of_shots, weapon_plural, target_name]);
        } else {
            attack_message = LF("{0} {1} strike the {2} but fail to penetrate its armour.", [number_of_shots, weapon_plural, target_name]);
        }
    }

    // if (string_length(attack_message+kill_message+p3)<8) then show_message(weapon_name+" is not displaying anything");

    // I don't understand what this was supposed to do either.
    // if (obj_ncombat.dead_enemies != 0){
    // 	for (var i = 1; i < array_length_1d(obj_ncombat.dead_ene); i++) {
    // 		if (obj_ncombat.dead_ene[i] != "") {
    // 			if (obj_ncombat.dead_enemies == 1) {
    // 				kill_message += obj_ncombat.dead_ene[i] + " unit has been eliminated.";
    // 			} else if (obj_ncombat.dead_enemies == 2) {
    // 				if (i == 1) {
    // 					kill_message += obj_ncombat.dead_ene[i] + " and ";
    // 				} else {
    // 					kill_message += obj_ncombat.dead_ene[i] + " units have been eliminated.";
    // 				}
    // 			} else if (obj_ncombat.dead_enemies > 2) {
    // 				if (i == 1) {
    // 					kill_message += obj_ncombat.dead_ene[i] + ", ";
    // 				} else if (i == obj_ncombat.dead_enemies) {
    // 					kill_message += "and " + obj_ncombat.dead_ene[i] + " units have been eliminated.";
    // 				} else {
    // 					kill_message += obj_ncombat.dead_ene[i] + ", ";
    // 				}
    // 			}
    // 		}
    // 		obj_ncombat.dead_ene[i] = "";
    // 	}
    // 	obj_ncombat.dead_enemies = 0;
    // }

    var message_color = eMSG_COLOR.DEFAULT;
    if (obj_ncombat.enemy <= eFACTION.CHAOS) {
        if (target_name == obj_controller.faction_leader[obj_ncombat.enemy]) {
            // Cleaning up the message for the enemy leader
            leader_message = string_replace(leader_message, "a " + target_name, target_name);
            leader_message = string_replace(leader_message, "the " + target_name, target_name);
            leader_message = string_replace(leader_message, target_name + " ranks , inflicting {casulties}", target_name);
            if (enemy == 5) {
                leader_message = string_replace(leader_message, "it", "her");
            }
            if ((enemy == 6) && (obj_controller.faction_gender[6] == 1)) {
                leader_message = string_replace(leader_message, "it", "him");
            }
            if ((enemy == 6) && (obj_controller.faction_gender[6] == 2)) {
                leader_message = string_replace(leader_message, "it", "her");
            }
            if ((enemy != 6) && (enemy != 5)) {
                leader_message = string_replace(leader_message, "it", "him");
            }
            message_color = eMSG_COLOR.YELLOW;
        }
    }

    // When deferred, hand the parts back to the caller instead of posting them, so the spill-over
    // kill list can be appended and the whole volley posted as one line.
    if (!_defer) {
        if (attack_message != "") {
            add_battle_log_message(attack_message, message_color);
        }

        if (leader_message != "") {
            add_battle_log_message(leader_message, message_color);
        }
    }

    return {
        attack: attack_message,
        leader: leader_message,
        color: message_color,
        bounced: (shots_bounced && casulties == 0),
        injured: (!shots_bounced && casulties == 0),
        target: target_name,
        subject: firing_subject,
    };
}

/// @desc Formats a list of kills into "the X" / "N X", joined as "A, B, and C".
/// @param {Array} _kills Array of { name, count } structs.
/// @returns {string}
function format_kill_list(_kills) {
    // Merge entries that share a name so multiple ranks of one unit read as a single tally
    // (e.g. "29 Slugga Boy and 223 Slugga Boy" -> "252 Slugga Boy").
    var _merged = [];
    for (var m = 0; m < array_length(_kills); m++) {
        var _hit = false;
        for (var n = 0; n < array_length(_merged); n++) {
            if (_merged[n].name == _kills[m].name) {
                _merged[n].count += _kills[m].count;
                _hit = true;
                break;
            }
        }
        if (!_hit) {
            array_push(_merged, {name: _kills[m].name, count: _kills[m].count});
        }
    }
    _kills = _merged;
    var _n = array_length(_kills);
    if (_n == 0) {
        return "";
    }
    var _parts = [];
    for (var i = 0; i < _n; i++) {
        var _k = _kills[i];
        array_push(_parts, (_k.count == 1) ? ("the " + _k.name) : (string(_k.count) + " " + _k.name));
    }
    var _list = string_join_oxford_comma(_parts);
    return _list;
}

/// @desc Posts a single consolidated volley line: the deferred rich flavour for the first target,
///       plus a trailing list of everything the volley's overflow killed afterwards.
/// @param {Struct} _primary Result returned by scr_flavor(..., _defer=true) for the first target (or undefined).
/// @param {Array} _spill_kills Array of { name, count } for targets killed after the first.
function emit_volley_flavour(_primary, _spill_kills) {
    var _list = format_kill_list(_spill_kills);

    // Non-killing volley (armour-bounce or a wound that dropped no-one, and nothing spilled):
    // consolidate into one chronological line per target instead of one line per weapon.
    if (is_struct(_primary) && (_primary.bounced || _primary.injured) && _list == "") {
        combat_tally_add(_primary.target, _primary.subject, _primary.injured);
        return;
    }

    // A killing volley posts immediately; flush any pending bounce/injure tally first so the log
    // stays in chronological order.
    combat_tally_flush();

    if (!is_struct(_primary)) {
        // No primary line (scr_flavor bailed on a dead target - shouldn't happen now that emptied
        // formations are destroyed). Spill-over only happens after a wipe, so this is just defensive.
        if (_list != "") {
            add_battle_log_message("Overflowing fire cuts down " + _list + ".");
        }
        return;
    }

    var _message = _primary.attack;
    if (_list != "") {
        _message += " In the torrent of fire that reaches beyond those they slaughter: " + _list + ".";
    }

    if (_message != "") {
        add_battle_log_message(_message, _primary.color);
    }
    if (_primary.leader != "") {
        add_battle_log_message(_primary.leader, _primary.color);
    }
}

/// @desc Buffers a non-killing volley (wound or armour-bounce) against a target. Consecutive volleys
///       on the same target merge; switching target flushes the previous one, keeping the log
///       chronological. _injured true = penetrated but no kill; false = bounced off armour.
function combat_tally_add(_target, _subject, _injured) {
    if (obj_ncombat.ctally_target != _target) {
        combat_tally_flush();
        obj_ncombat.ctally_target = _target;
    }
    if (_injured) {
        array_push(obj_ncombat.ctally_injure, _subject);
    } else {
        array_push(obj_ncombat.ctally_bounce, _subject);
    }
}

/// @desc Posts the buffered wound/bounce lines for the current target (one each), then clears them.
function combat_tally_flush() {
    if (obj_ncombat.ctally_target == undefined) {
        return;
    }
    var _t = obj_ncombat.ctally_target;
    if (array_length(obj_ncombat.ctally_injure) > 0) {
        add_battle_log_message($"Fire from {combat_subject_join(obj_ncombat.ctally_injure)} wounded the {_t} but didn't bring it down.", eMSG_COLOR.WHITE);
    }
    if (array_length(obj_ncombat.ctally_bounce) > 0) {
        add_battle_log_message($"Fire from {combat_subject_join(obj_ncombat.ctally_bounce)} cannot penetrate the {_t}'s armour.", eMSG_COLOR.WHITE);
    }
    obj_ncombat.ctally_target = undefined;
    obj_ncombat.ctally_bounce = [];
    obj_ncombat.ctally_injure = [];
}

/// @desc Joins firing subjects into "A", "A and B", or "A, B, and C".
function combat_subject_join(_subjects) {
    return string_join_oxford_comma(_subjects);
}

/// @self Asset.GMObject.obj_ncombat
/// @desc Sets `_newline` to the enemy strength readout (live %, boss HP, or "Defeated") and fires the
///       enemy-defeated side-effects. Shared by obj_ncombat's Alarm_3 and Step_0 so the line can't
///       drift between the two copies (that drift is what hid the % for so long).
function combat_emit_enemy_status() {
    var _newline = "";
    var _newline_color = eMSG_COLOR.YELLOW;

    if ((enemy_forces > 0) && (enemy != 30)) {
        _newline = "Enemy Forces at " + string(max(1, round((enemy_forces / enemy_max) * 100))) + "%";
    }
    if ((enemy == 30) && instance_exists(obj_enunit)) {
        _newline = "Enemy has ";
        var yoo = instance_nearest(0, 0, obj_enunit);
        _newline += string(round(yoo.dudes_hp[1])) + "HP remaining";
    }
    if (((enemy_forces <= 0) || (!instance_exists(obj_enunit))) && (defeat_message == 0)) {
        defeat_message = 1;
        _newline = L("Enemy Forces Defeated");
        timer_maxspeed = 0;
        timer_speed = 0;
        started = 2;
        instance_activate_object(obj_pnunit);
    }

    combat_log.push(_newline, _newline_color);
}

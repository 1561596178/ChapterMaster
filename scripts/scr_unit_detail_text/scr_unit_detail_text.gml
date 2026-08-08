/// @self Struct.TTRPG_stats
function scr_unit_detail_text() {
    var unit_data_string = "";
    var is_astartes = false;
    var is_superior = array_contains([obj_ini.role[100][18], obj_ini.role[100][19]], role());
    var unit_name = name();
    var unit_role = role();
    var body_augmentations = {
        mutations: [],
        bionics: [
            [],
            [],
        ],
    };
    var body_bionics = get_body_data("bionic");
    if (psionic < 0) {
        var _psy_levels = global.arr_negative_psy_levels;
        var _psionic_assignment = _psy_levels[psionic * -1];
    } else {
        var _psy_levels = global.arr_psy_levels;
        var _psionic_assignment = _psy_levels[psionic];
    }
    var _body_parts = global.unit_body_parts;
    var _body_parts_display = global.unit_body_parts_display;
    if (base_group == "astartes") {
        is_astartes = true;
    }

    // Chapter Role text
    var chapter_role = "";
    if (company > 0) {
        if (squad != "none") {
            chapter_role += is_superior ? LF("{0}, sergeant of the ", [unit_name]) : LF("{0}, member of the ", [unit_name]);
            chapter_role += scr_convert_company_to_string(company, true, true);
            var _squad_data = fetch_squad(squad);
            var _squad_display = (L(_squad_data.base) != _squad_data.base) ? L(_squad_data.base) + L(" Squad") : _squad_data.display_name;
            chapter_role += LF(" {0}.", [_squad_display]);
        } else {
            chapter_role += LF("{0}, {1} from the ", [unit_name, L(unit_role)]);
            chapter_role += scr_convert_company_to_string(company, false, true) + ".";
        }
    } else {
        chapter_role += LF("{0}, {1}.", [unit_name, L(unit_role)]);
    }
    unit_data_string += chapter_role;

    // Age and ascension date
    unit_data_string += "\n";
    if (base_group == "astartes") {
        var _ascension_date = string(marine_ascension);
        if (_ascension_date == "0") {
            _ascension_date = "unknown";
        }
        unit_data_string += LF("{0} years old. Ascended to an Astartes in the {1} year.", [round(age()), _ascension_date]);
        if (struct_exists(spawn_data, "recruit_data")) {
            var recruit_data = spawn_data.recruit_data;
            unit_data_string += "\n";
            unit_data_string += LF("they were recruited from a {0} World, and was chosen as potential candidate for the chapter by way of a {1} Trial", [L(recruit_data.recruit_world), L(scr_trial_data(recruit_data.aspirant_trial).name)]);
        }
    }

    // Religion text
    unit_data_string += L("\n\n");
    if (religion != "none") {
        unit_data_string += LF("Follower of the {0}", [L(global.religions[$ religion][$ "name"])]);
        if (religion_sub_cult != "none") {
            unit_data_string += LF(", in particular a sub cult known as {0}", [L(religion_sub_cult)]);
        }
        if ((piety > 25) && (piety < 40)) {
            unit_data_string += L(", he is firmly committed to the faith.");
        } else if (piety <= 25) {
            unit_data_string += L(", however, he is not putting much value in religion.");
        } else if (piety >= 40) {
            unit_data_string += L(", he is fervently devoted in his worship.");
        } else if (piety >= 50) {
            unit_data_string += L(", he exhibits an unshakeable fanaticism in his worship.");
        }
        unit_data_string += "\n";
    }

    // Psyker text
    unit_data_string += LF("Has an Assignment rating of {0} ({1}) ", [_psionic_assignment, psionic]);
    var is_lib = array_contains(["Lexicanum", "Codiciery", obj_ini.role[100][17]], role()) || role() == obj_ini.role[100][eROLE.CHAPTERMASTER];
    if (psionic < -6) {
        unit_data_string += L(", so inert in the Warp as to actually exhibit negative psychic influence upon others.");
    } else if (psionic < 0) {
        unit_data_string += L(", psionically-dense, oblivious to warp fluctuations and psychic probing.");
    } else if (psionic == 0) {
        unit_data_string += L(", no manifestation of psychic talent.");
    } else if (psionic == 1) {
        unit_data_string += L(", second of the two so-called inert psychic levels.");
    } else if (psionic < 8) {
        unit_data_string += L(", unconscious and minor level of psionic brain activity, causing them to be more prone to attacks from the immaterium.");
        if (is_astartes) {
            if (!is_lib) {
                unit_data_string += "\n";
                unit_data_string += L("It's recommended to send them to the Librarium, however they are unlikely to exceed the role of Lexicanum or Codiciery in their current state.");
            }
        }
    } else if (psionic < 11) {
        unit_data_string += L(", therefore is considered to be a true psyker, with conscious levels of psionic talent.");
        if (is_astartes) {
            if (!is_lib) {
                unit_data_string += "\n";
                unit_data_string += L("Their uncontrolled powers are a threat to the chapter. They must be sent to the Librarium.");
            }
        }
    } else if (psionic < 13) {
        unit_data_string += L(", a very high level of mental psychic activity, making them a potent psyker. Their presence in the warp is obvious to the daemons of the immaterium.");
        if (is_astartes) {
            if (!is_lib) {
                unit_data_string += "\n";
                unit_data_string += L("Their existence outside of the Librarium is an extreme threat. Deal with it, or the consequences may be devastating.");
            }
        }
    } else if (psionic < 17) {
        unit_data_string += L(", occurring in approximately one-per-billion human births. They are an extremely potent psyker.");
        if (is_astartes) {
            if (!is_lib) {
                unit_data_string += "\n";
                unit_data_string += L("They have to be sent to the Librarium, or your chapter may soon see its end, at the hands of a chaos god.");
            } else {
                unit_data_string += "\n";
                unit_data_string += L("His rare talent is of great benefit to the chapter and could one day be a candidate for Chief of the Librariam.");
            }
        }
    } else {
        unit_data_string += L(". State of mind of such psykers always has a perceivable level of dementation or insanity.");
        if (is_astartes) {
            unit_data_string += "\n";
            unit_data_string += L("Their talents are both a great boon and huge risk to the chapter.");
            if (!is_lib) {
                unit_data_string += L("He must brought into the guided sphere of the librarium immediately or else dealt with by other methods for the good of the chapter.");
            } else {
                unit_data_string += L("His rare talent is of great benefit to the chapter and will likely one day be a candidate for Chief of the librariam if he does not succumb to either the material or immaterium.");
            }
        }
    }

    // Bionics text
    unit_data_string += L("\n\n");
    if (is_astartes) {
        var bionic_positions = struct_get_names(body_bionics);
        var bionic_count = bionics;
        if (bionic_count == 0) {
            unit_data_string += L("Has no bodily augmentations besides his astartes gene-seed and organs.");
        } else if (bionic_count == 1 && array_length(bionic_positions) > 0) {
            for (var i = 0; i < array_length(_body_parts); i++) {
                if (bionic_positions[0] == _body_parts[i]) {
                    unit_data_string += LF("Has a bionic {0}.", [L(_body_parts_display[i])]);
                }
            }
        } else if ((bionic_count > 1) && (bionic_count <= 4)) {
            unit_data_string += L("Has some bionic replacements.");
        } else if ((bionic_count >= 5) && (bionic_count < 8)) {
            unit_data_string += L("Has many bionic replacements.");
        } else if (bionic_count > 8) {
            unit_data_string += L("Is mostly a machine, having replaced most of his flesh with bionic replacements.");
        }
        // Not sure why you need this line only for the throat.
        // if (array_contains(bionic_positions, "throat")){
        // 	unit_data_string+=" People tend to find the sound from his augmented throat unnerving.";
        // }
        // Gene-seed text
        unit_data_string += "\n";
        var mutation_names = struct_get_names(gene_seed_mutations);
        var mutation_count = 0;
        var mutation_string = "";
        for (var mute = 0; mute < array_length(mutation_names); mute++) {
            if (gene_seed_mutations[$ mutation_names[mute]] == 1) {
                mutation_count += 1;
                switch (mutation_names[mute]) {
                    case "preomnor":
                        mutation_string += L("Lacks the detoxifying gland called the Preomnor - he is more susceptible to poisons and toxins.");
                        break;
                    case "lyman":
                        mutation_string += L("Lacks a working Lyman's ear, and therefore struggles with deep strikes and certain other actions.");
                        break;
                    case "omophagea":
                        mutation_string += L("Suffers from a faulty Omophagea.");
                        break;
                    case "ossmodula":
                        mutation_string += L("Suffers from a faulty Ossmodula, and takes longer to heal from injuries.");
                        break;
                    case "zygote":
                        mutation_string += L("One of his Zygotes is faulty or missing, and therefore will produce no extra gene seed other than the one implanted.");
                        break;
                    case "betchers":
                        mutation_string += L("Missing his Betchers Gland and therefore cannot spit acid.");
                        break;
                    case "catalepsean":
                        mutation_string += L("Has a faulty Catalepsean Node reducing his awareness when tired.");
                        break;
                    case "occulobe":
                        mutation_string += L("Suffers from a faulty occulobe limiting his eyesight enhancements.");
                        break;
                    case "mucranoid":
                        mutation_string += L("Suffers from a faulty mucranoid reducing his resistance to extreme heat and cold.");
                        break;
                    case "membrane":
                        mutation_string += L("Cannot properly activate his Sus-an Membrane, this limits his ability to survive mortal wounds.");
                        break;
                    case "voice":
                        mutation_string += L("Gene-seed implantation process damaged his vocal cords, causing many to find the sound of his voice to be rather unnerving.");
                }
                mutation_string += "\n";
            }
        }
        if (mutation_count == 0) {
            unit_data_string += L("His gene-seed is pure and has no mutations.\n");
        } else {
            unit_data_string += mutation_string;
        }
        // Black carapace text
        var has_carapace;
        if (struct_exists(body[$ "torso"], "black_carapace")) {
            if (body[$ "torso"][$ "black_carapace"]) {
                has_carapace = true;
            } else {
                has_carapace = false;
                unit_data_string += L("Doesn't have black carapace installed and therefore can't use power armour to its maximum potential.") + "\n";
            }
        }

        // Sergeant text
        if (is_superior) {
            unit_data_string += "\n";
            var charisma_string = "";
            var wisdom_string = "";
            unit_data_string += L("Marines under his command ");
            // Charisma text
            if (charisma <= 25) {
                charisma_string += L("dislike him");
            } else if (charisma >= 35) {
                charisma_string += L("like him");
            } else {
                charisma_string += L("are neutral towards him");
            }
            // Wisdom text
            var separator = (charisma <= 25 && wisdom <= 35) || (charisma >= 35 && wisdom > 35) ? L(" and ") : L(" yet ");
            if (wisdom <= 30) {
                wisdom_string += L("are generally dissatisfied with his tactical decisions.");
            } else if (wisdom <= 35) {
                wisdom_string += L("do not always have a positive view of his tactical abilities.");
            } else if (wisdom <= 45) {
                wisdom_string += L("consider him to be a good tactician.");
            } else {
                wisdom_string += L("acknowledge that his military mind has saved them many times.");
            }
            unit_data_string += string_join(separator, charisma_string, wisdom_string);
            // Combat skills text
            var combat_skill_sum = ballistic_skill + weapon_skill;
            if (combat_skill_sum >= 100) {
                unit_data_string += L("\nThey are in awe of his combat skills, seeing him as a paragon of martial prowess.");
            } else if (combat_skill_sum >= 80) {
                unit_data_string += L("\nThey regard him with respect, his battle prowess a testament to his leadership.");
            } else {
                unit_data_string += L("\nThey harbor doubts about his combat abilities, having skills seemingly inadequate for his rank.");
            }
        }
        // Strength text
        if (strength >= 50) {
            unit_data_string += L("\nHis strength greatly exceeds that of the standard astartes allowing him to wield weapons that normally require two hands in one.");
        }
        // Technology text
        if (!has_trait("mars_trained") && !has_trait("chapter_trained_tech")) {
            if (technology >= 35) {
                unit_data_string += L("\nDisplays a talent with technology that might make him suited to a role within the armentarium.");
            } else if (technology <= 25) {
                unit_data_string += L("\nIs a technological luddite capable of little more than cleaning his own bolter.");
            } else {
                unit_data_string += L("\nHas a decent understanding of technology, capable of performing routine maintenance on standard issue equipment.");
            }
        } else {
            if (technology >= 45) {
                unit_data_string += L("\nIs a technological prodigy able to understand and build most anything that takes his interest.");
            } else {
                unit_data_string += L("\nIs capable enough with technical skills to carry out basic tasks in the field.");
            }
        }
    }

    // Traits text
    if (array_length(traits) > 0) {
        unit_data_string += L("\n\n");
        for (var i = 0; i < array_length(traits); i++) {
            unit_data_string += L(global.trait_list[$ traits[i]].flavour_text + ".") + "\n";
        }
    }
    return unit_data_string;
}

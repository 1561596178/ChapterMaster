#macro LOCALIZATION global.localization

#macro LANG_EN "en"
#macro LANG_ZH_CN "zh-CN"

/// @function Localization() constructor
/// @description Loads a translation table from datafiles/main/localization/<lang>.json and resolves strings at runtime.
///              The lookup key is the original English source string, so the game keeps working in English when no
///              translation is present (or when a key is missing) and stays 100% playable for development.
/// @usage
///   global.localization = new Localization();
///   global.localization.load(LANG_ZH_CN);
///   draw_text(x, y, L("God-Spear"));            // -> "神枪" (falls back to English if missing)
///   draw_text(x, y, LF("Reinforcements: {0}", [n]);  // translates then substitutes {0}
function Localization() constructor {
    /// @type {String} current language code, e.g. "en", "zh-CN"
    lang_code = LANG_EN;

    /// @type {Bool} true once translation data has been loaded (or English was chosen)
    loaded = false;

    /// @type {Struct} flat string->string lookup table (English source -> translation)
    dict = {};

    /// @description Loads a translation table from the json. Falls back to English (no-op) safely.
    /// @param {String} _lang_code language code. Must match a file in datafiles/main/localization/ e.g. "zh-CN".
    /// @returns {Bool} success
    static load = function(_lang_code = LANG_ZH_CN) {
        lang_code = _lang_code;

        if (_lang_code == LANG_EN) {
            loaded = true;
            return true;
        }

        var _path = working_directory + "main/localization/" + _lang_code + ".json";
        var _parsed = json_to_gamemaker(_path, json_parse);

        if (!is_struct(_parsed)) {
            LOGGER.warning($"Could not load localization file for '{_lang_code}' at {_path}. Falling back to English.");
            lang_code = LANG_EN;
            loaded = true;
            return false;
        }

        dict = _parsed;
        loaded = true;
        var _entry_total = array_length(struct_get_names(dict));
        LOGGER.info($"Localization '{_lang_code}' loaded with {_entry_total} string entries.");
        return true;
    };

    /// @description Translates a string. Returns the source unchanged if nothing matches.
    /// @param {String} _key source (English) string or translation key.
    /// @returns {String} translated string (or the key itself)
    static t = function(_key) {
        if (lang_code == LANG_EN || loaded == false) {
            return _key;
        }
        if (struct_exists(dict, string(_key))) {
            return string(dict[$ string(_key)]);
        }
        return string(_key);
    };

    /// @description Translates then formats a string. Uses `{0}`, `{1}`, ... style placeholders.
    /// @param {String} _template source string that may contain `{0}` style placeholders.
    /// @param {Array}  _args values to substitute into the translated template.
    /// @returns {String}
    static format = function(_template, _args) {
        var _text = t(_template);
        for (var i = 0; i < array_length(_args); i++) {
            _text = string_replace_all(_text, "{" + string(i) + "}", string(_args[i]));
        }
        return _text;
    };

    /// @description Whether the lookup table contains the given key.
    /// @param {String} _key
    /// @returns {Bool}
    static has_key = function(_key) {
        return struct_exists(dict, string(_key));
    };

    /// @description Translates in-place the well-known display-only global string arrays
    ///              (faction names, alliance grades, culture styles, ...). MUST only be used
    ///              on arrays that are purely presentational, never used as logic keys.
    ///              Call once at boot, after load().
    static localize_global_arrays = function() {
        if (lang_code == LANG_EN || loaded == false) {
            return;
        }

        var _display_arrays = [
            "faction_names",
            "alliance_grades",
            "force_strength_descriptions",
            "unit_equip_slots_display",
        ];

        for (var _i = 0; _i < array_length(_display_arrays); _i++) {
            var _name = _display_arrays[_i];
            var _array = variable_global_get(_name);
            if (is_array(_array) == false) {
                continue;
            }
            var _changed = false;
            for (var _j = 0; _j < array_length(_array); _j++) {
                var _translated = t(_array[_j]);
                if (_translated != _array[_j]) {
                    _array[_j] = _translated;
                    _changed = true;
                }
            }
            if (_changed) {
                variable_global_set(_name, _array);
            }
        }

        LOGGER.info("Global display arrays localized.");
    };
}

/// @function L(_key)
/// @description Shorthand for global.localization translate of a single string.
/// @param {String} _key source (English) string.
/// @returns {String}
function L(_key) {
    if (global.localization == undefined) {
        return _key;
    }
    return global.localization.t(_key);
}

/// @function LF(_template, _args)
/// @description Shorthand for global.localization format: translates a template and substitutes `{0}`,`{1}`,...
/// @param {String} _template source (English) template.
/// @param {Array}  _args values to substitute.
/// @returns {String}
function LF(_template, _args) {
    if (global.localization == undefined) {
        var _text = _template;
        for (var i = 0; i < array_length(_args); i++) {
            _text = string_replace_all(_text, "{" + string(i) + "}", string(_args[i]));
        }
        return _text;
    }
    return global.localization.format(_template, _args);
}

fading = 0;
effect = 0;
settings = room == rm_main_menu;
cooldown = 0;

var _spawn_button = function(_x, _y, _text, _target) {
    var _butt = instance_create(_x, _y, obj_new_button);
    _butt.button_id = 1;
    _butt.button_text = _text;
    _butt.target = _target;
    _butt.scaling = 1.5;
    _butt.depth = -20010;
    return _butt;
};

if (room != rm_main_menu) {
    _spawn_button(821, 256, L("Save Game"), eIN_GAME_MENU_EFFECT.SAVE);
    _spawn_button(821, 336, L("Load Game"), eIN_GAME_MENU_EFFECT.LOAD);
    _spawn_button(821, 416, L("Options"), eIN_GAME_MENU_EFFECT.OPTIONS);
    _spawn_button(821, 496, L("Exit"), eIN_GAME_MENU_EFFECT.EXIT);
    _spawn_button(821, 666, L("Return"), eIN_GAME_MENU_EFFECT.RETURN);
} else {
    with (obj_new_button) {
        instance_destroy();
    }
    _spawn_button(653, 664, L("Exit"), eIN_GAME_MENU_EFFECT.BACK_FROM_SETTINGS);
}

global.ui_click_lock = true;

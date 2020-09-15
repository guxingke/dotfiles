require("utils.js")
require("mouse.js")
require("window.js")
require("app.js")
require("config.js")

log(CONFIG)

// var keys = [];
// var mash = ["alt"];
// var mashShift = ["alt", "shift"];
// var mashCtrl = ["alt", "ctrl"];
// var cmdCtrl = ['cmd', 'ctrl'];
// var shiftCmdCtrl = ['shift', 'cmd', 'ctrl'];

var ACTIVE_WINDOWS_TIMES = {};
var A_BIG_PIXEL = 10000;

var FUNCTIONS = {
   // mouse
   "central_mouse" : central_mouse,
   // screen
   "next_screen": next_screen,
   "previous_screen": previous_screen,
   "move_current_window_to_next_screen": move_current_window_to_next_screen,
   "move_current_window_to_previous_screen": move_current_window_to_previous_screen,
   // space
   "move_current_window_to_next_space": moveCurrentWindowToNextSpace,
   "move_current_window_to_previous_space": moveCurrentWindowToPrewSpace,
   // window
   "window_smaller": windowSmaller,
   "window_larger": windowLarger,
   "fullscreen": fullscreen,
   "half_left": halfLeft,
   "half_right": halfRight,
   "half_top": halfTop,
   "half_buttom": halfButtom,
   "window_central": window_central,
   "previous_window_in_one_screen": previous_window_in_one_screen,
   "next_window_in_one_screen": next_window_in_one_screen
}

/**
 * My Configuartion Global
 */
Phoenix.set({
   'daemon': false,
   'openAtLogin': true
});

/**
 * My Configuartion Screen
 */
var sp = CONFIG.SCREEN.prefix
_.map(CONFIG.SCREEN.mapping, function (it) {
   Key.on(it.key, sp, FUNCTIONS[it.name])
})

// Space
var ssp = CONFIG.SPACE.prefix
_.map(CONFIG.SPACE.mapping, function (it) {
   Key.on(it.key, ssp, FUNCTIONS[it.name])
})

/**
 * My Configuartion Window
 */
var wp = CONFIG.WINDOW.prefix
_.map(CONFIG.WINDOW.mapping, function (it) {
   Key.on(it.key, wp, FUNCTIONS[it.name])
})

/**
 * My Configuartion Mouse
 */
var mp = CONFIG.MOUSE.prefix
_.map(CONFIG.MOUSE.mapping, function (it) {
   Key.on(it.key, mp, FUNCTIONS[it.name])
})

/**
 * My Configuartion App
 */
// Launch App
var prefix = CONFIG.APP.prefix
_.map(CONFIG.APP.apps, function (it) {
   Key.on(it.key, prefix, function () { callApp(it.name) })
})

// vim: set ft=javascript sw=3:

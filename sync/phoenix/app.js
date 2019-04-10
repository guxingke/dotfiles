/**
 * App Functions
 */
function launchOrFocus(appName) {
    var app = App.launch(appName);
    assert(app !== undefined);
    app.focus();
    return app;
 }
 
 //switch app, and remember mouse position
 function callApp(appName) {
    var window = Window.focused();
    if (window) {
       save_mouse_position_for_window(window);
    }
    //App.launch(appName);
    var newWindow = _.first(launchOrFocus(appName).windows());
    if (newWindow && window !== newWindow) {
       restore_mouse_position_for_window(newWindow);
    }
 }
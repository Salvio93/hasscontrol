using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class AlarmDelegate extends Ui.BehaviorDelegate {
    hidden var _view;

    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(clickEvent) {
        App.getApp().resetInactivityTimer();
        _view.handleTap(clickEvent);
        return true;
    }

    function onBack() {
        App.getApp().resetInactivityTimer();
        Ui.popView(Ui.SLIDE_RIGHT);
        return true;
    }
}
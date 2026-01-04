using Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.System;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application as App;
using Hass;

class AlarmView extends Ui.View {
    var tapPositions;
    var refusePosition;
    var acceptPosition;
    var timeDigits;

    function initialize() {
        View.initialize();
        tapPositions = generateDialPositions(10, 20, 20);
        refusePosition = [109, 140];
        acceptPosition = [109, 100];
        timeDigits = [];
    }

    function onLayout(dc) {
        setLayout([]);
    }

    function onShow() {
        timeDigits = [];
    }

    function onUpdate(dc) {
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        /*View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();*/
        // Draw time display
        var text = "";
        if (timeDigits.size() > 0) {
            for (var i = 0; i < timeDigits.size(); i++) {
                text += timeDigits[i].toString();
                if (i == 1) {
                    text += ":";
                }
            }
        } else {
            text = "--:--";
        }
        dc.drawText(109, 50, Graphics.FONT_MEDIUM, text, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw number dial
        for (var i = 0; i < tapPositions.size(); i++) {
            var pos = tapPositions[i];
            dc.drawText(pos["x"], pos["y"], Graphics.FONT_LARGE, i.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Draw cancel button (X)
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawText(refusePosition[0], refusePosition[1], Graphics.FONT_TINY, "X", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw accept button (✓)
        dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK);
        dc.drawText(acceptPosition[0], acceptPosition[1], Graphics.FONT_TINY, "V", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onHide() {
    }

    function handleTap(clickEvent) {
        var coords = clickEvent.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        
        // Handle number tap
        if (timeDigits.size() < 4) {
            for (var i = 0; i < tapPositions.size(); i++) {
                var pos = tapPositions[i];
                var dx = x - pos["x"];
                var dy = y - pos["y"];
                var distance = Math.sqrt(dx * dx + dy * dy);

                if (distance < 40) {
                    addDigit(i);
                    break;
                }
            }
        }
        
        // Handle cancel button
        var dxr = x - refusePosition[0];
        var dyr = y - refusePosition[1];
        var distanceRefuse = Math.sqrt(dxr * dxr + dyr * dyr);

        if (distanceRefuse < 30) {
            if (timeDigits.size() > 0) {
                timeDigits = [];
            } else {
                goBack();
            }
            Ui.requestUpdate();
        }
        
        // Handle accept button
        var dxa = x - acceptPosition[0];
        var dya = y - acceptPosition[1];
        var distanceAccept = Math.sqrt(dxa * dxa + dya * dya);

        if (distanceAccept < 30 && timeDigits.size() == 4) {
            var h = timeDigits[0] * 10 + timeDigits[1];
            var m = timeDigits[2] * 10 + timeDigits[3];
            
            sendAlarm(h, m);
        }
    }
    
    function addDigit(num) {
        if (timeDigits.size() < 4) {
            timeDigits.add(num);

            if (timeDigits.size() == 4) {
                if (!validateTime()) {
                    timeDigits = [];
                }
            }
        }
        Ui.requestUpdate();
    }

    function validateTime() {
        var h = timeDigits[0] * 10 + timeDigits[1];
        var m = timeDigits[2] * 10 + timeDigits[3];

        if (h >= 24 || h == 0) {
            return false;
        }

        if (m >= 60) {
            return false;
        }

        return true;
    }
    
    function generateDialPositions(n, margin, yoffset) {
        var positions = [];
        var center = 109;
        var radius = center - margin;
        
        for (var i = 0; i < n; i++) {
            var angle = (-90 + (i * 360.0 / n)) * Math.PI / 180.0;
            var x = center + Math.cos(angle) * radius;
            var y = center - yoffset + Math.sin(angle) * radius;
            positions.add({"x" => x.toNumber(), "y" => y.toNumber()});
        }
        
        return positions;
    }
    
    function goBack() {
        Ui.popView(Ui.SLIDE_RIGHT);
    }
    
    function sendAlarm(hours, minutes) {
        System.println("Sending alarm: " + hours.format("%02d") + ":" + minutes.format("%02d"));
        
        App.getApp().viewController.showLoader("Setting Alarm");
        
        Hass.client.setAlarmTime(hours, minutes, method(:onAlarmSet));
        
        timeDigits = [];
    }
    
    function onAlarmSet(error, data) {
        if (error != null) {
            App.getApp().viewController.removeLoaderImmediate();
            App.getApp().viewController.showError(error);
            return;
        }

        App.getApp().viewController.removeLoader();
        
        // Close the alarm view
        goBack();
        
        // Show confirmation
        Ui.pushView(
            new Ui.Confirmation("Alarm Set!"),
            new Ui.ConfirmationDelegate(),
            Ui.SLIDE_IMMEDIATE
        );
    }
}
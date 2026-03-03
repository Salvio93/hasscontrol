# HassControl + Alarm & HA entity

A Garmin widget to interact with Home Assistant, **with integrated wake-up alarm** that syncs to your HA automations.

## What's Different in This Fork?

This is a customized version of [HassControl](https://github.com/hatl/hasscontrol) with added features:

- **Custom Alarm Picker** - Set variabla in HomeAssistant directly from your Garmin watch to use in wake-up automation
- **Integration** - Automatically start your coffee maker, light, curtain before you wake up
- **Smart Home Wake-Up** - Trigger lights, scenes, and automations based on your alarm time
- **Dial-Based Time Entry** - Intuitive circular interface kinda like in the original alarm app from garmin

---

## Wake-Up System Features

Set your alarm on your Garmin watch and let Home Assistant handle the rest:

1. **10 minutes before alarm** → Coffee maker starts brewing
2. **5 minutes before alarm** → Bedroom lights gradually brighten
3. **Alarm time** → Wake up to light and fresh coffee!

All synchronized through Home Assistant's `input_datetime.sleep_alarm` entity.

---

## Prerequisites

- **Home Assistant** instance accessible over HTTPS (no self-signed certificates; I used DuckDNS & Nginx on an Orange Pi but you can just buy a domain name)
- **Paired Garmin watch** with Garmin Connect app running on phone
- **MQTT broker** (Mosquitto) for coffee maker integration *(optional)*
- **Compatible Garmin device** (see original HassControl)

---


###
```bash
git clone https://github.com/Salvio93/hasscontrol.git
cd hasscontrol-alarm/widget

# Build and deploy (requires Garmin SDK)
monkeyc -d YOUR_DEVICE -o HassControl.prg -f monkey.jungle -y developer_key
```

---

## Configuration

### Basic Settings

Configure in the **Garmin Connect IQ** app:

**Host**: `https://your-homeassistant.duckdns.org:8123`  
**Long-Lived Access Token**: Generate in HA → Profile → Long-Lived Access Tokens  
**Group**: `group.garmin` *(optional - for entity sync)*

### Home Assistant Setup

#### 1. Create Input DateTime for Alarm

**File: `configuration.yaml`**
```yaml
default_config:

frontend:
  themes: !include_dir_merge_named themes

automation: !include automations.yaml
script: !include scripts.yaml
group: !include groups.yaml
scene: !include scenes.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.18.0.0/16
#    - 172.0.0.0/8
    - 192.168.1.xx
homeassistant:
  time_zone: "Europe/Brussels"
  packages: !include_dir_named packages

```

#### 2. Create Wake-Up Automation

**File: `automations.yaml`**
```yaml
automation:
  - id: wake_up_light
    alias: "Wake Up - Gradual Light"
    trigger:
      - platform: template
        value_template: >
          {% set alarm = states('input_datetime.sleep_alarm') %}
          {% if alarm not in ['unknown', 'unavailable'] %}
            {% set wake_time = today_at(alarm) - timedelta(minutes=5) %}
            {{ now() >= wake_time and now() < wake_time + timedelta(minutes=1) }}
          {% else %}
            false
          {% endif %}
    action:
      - service: light.turn_on
        target:
          entity_id: light.bedroom
        data:
          brightness_pct: 10
      # Add gradual brightness steps...
```

#### 3. Optional: Coffee Maker Automation

If you have a smart coffee maker (e.g., SenseoWifi):
```yaml
automation:
  - id: wake_up_coffee
    alias: "Wake Up - Coffee"
    trigger:
      - platform: template
        value_template: >
          {% set alarm = states('input_datetime.sleep_alarm') %}
          {% if alarm not in ['unknown', 'unavailable'] %}
            {% set coffee_time = today_at(alarm) - timedelta(minutes=10) %}
            {{ now() >= coffee_time and now() < coffee_time + timedelta(minutes=1) }}
          {% else %}
            false
          {% endif %}
    action:
      - service: switch.turn_on
        entity_id: switch.coffee_maker
```

---

## Using the Alarm Feature

### Setting an Alarm

1. Open **HassControl** on your Garmin watch
2. Long press or use menu button
3. Scroll to **"Set Sleep Alarm"** entity
4. Tap to open the **alarm picker**
5. Tap numbers on the dial to enter time (HH:MM)
6. Tap **green ✓** to confirm
7. Tap **red X** to cancel
---
## Screenshots

### Alarm Picker Interface
![Alarm Picker](resources/screenshots/alarm-picker.png)

### Entity List
![Entity List](resources/screenshots/entity-list.png)

### Coffee Maker Integration
![Coffee Integration](resources/screenshots/coffee-maker.png)

---

## Credits & Attribution

This project is a fork of the excellent HassControl

**Original HassControl**: https://github.com/hasscontrol/hasscontrol

**Additional features in this fork**:
- Custom alarm picker UI
- Coffee maker integration examples
- Wake-up automation templates

---

## License

This project maintains the same license as the original HassControl.

**Made by me**

# ideapad-noise-cancelling

A small service which reduces coil whine on (certain) Lenovo IdeaPads by keeping the battery charging and uncharging constantly in a (hopefully) not too unhealthy manner.

It does this by abusing the so-called "conservation mode", which is provided by the `thinkpad-acpi` kernel module. If this mode is activated, the notebook will uncharge to 60%, even on AC power. By monitoring the battery level and activating and deactivating the conservation mode accordingly, one can achieve that the notebook constantly charges or uncharges, with the battery level staying within defined upper and lower limits. For some models this will reduce the coil whine considerably, as for them it is very noticable (and annoying) once the battery level stays at a certain level - e. g. the usually hard to prevent 60% or 100%. 

## System requirements

To check whether this will work on your Lenovo IdeaPad you have to make sure the `conservation_mode` file required for controlling the conservation mode exists. Note that you will have to load the `thinkpad-acpi` kernel module beforehand. It should be located at the following location, whereby `VPC2004:00` can vary:

```
/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

To check the current battery level the service also requires a `capacity` file. It is located at the following location, whereby `BAT1` can vary.

```
/sys/class/power_supply/BAT1/capacity
```

## Installation

1. Clone or download and unpack this repository.
2. Execute `install.sh`.
3. Ready. The service will now start on system startup.

## Uninstallation

1. Clone or download and unpack this repository.
2. Execute `uninstall.sh`.
3. Ready.

## Usage

The `install.sh` installer installs a systemd service and a configuration file. So basically, one can configure the service by editing `/etc/ideapad-noise-cancelling.conf` and control it via systemd (`systemctl enable/start/stop/reload/status/disable ideapad-noise-cancelling.service`). Especially the output of `systemd status ideapad-noise-cancelling.service` can be interesting, as it will show the currently selected capacity mode (see below) as well as when and at which limits the service toggles the conservation mode.

## Configuration

The following settings can be customized by editing the configuration file `/etc/ideapad-noise-cancelling.conf`. All that is required is a simple assignment, e. g. `CAPA_MODE=high`. Note that the defaults are reasonable, so unless the file locations differ there is no immediate need to change anything.

The "capacity mode" may need a short explanation:
- `health` is supposed to be the next best thing right to keeping the battery level at exactly 60%.
- `high` tries to keep the battery level somewhat lower than "fully charged", while still providing enough battery life to keep the notebook actually mobile.
- `full` basically keeps the notebook fully charged, without the coil whine.

| Setting | Default | Possible values | Explanation |
| ------- | ------- | --------------- | ----------- |
| `CAPA_FILE` | `/sys/class/power_supply/BAT1/capacity` | (file location) | The location of the `capacity` file containing the battery level. |
| `CAPA_CONSERVATION_MODE_FILE` | `/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode` | (file location) | The location of the `conservation_mode` file controlling the conservation mode. |
| `CAPA_UPPER_LIMIT_MODE_HEALTH` | 65 | 60-100; >= `CAPA_LOWER_LIMIT_MODE_HEALTH` | The upper capacity limit of the battery, capacity mode `health`. |
| `CAPA_LOWER_LIMIT_MODE_HEALTH` | 60 | 60-100; <= `CAPA_UPPER_LIMIT_MODE_HEALTH` | The lower capacity limit of the battery, capacity mode `health`. |
| `CAPA_UPPER_LIMIT_MODE_HIGH` | 80 | 60-100; >= `CAPA_LOWER_LIMIT_MODE_HIGH` | The upper capacity limit of the battery, capacity mode `high`. |
| `CAPA_LOWER_LIMIT_MODE_HIGH` | 75 | 60-100; <= `CAPA_UPPER_LIMIT_MODE_HIGH` | The lower capacity limit of the battery, capacity mode `high`. |
| `CAPA_UPPER_LIMIT_MODE_FULL` | 100 | 60-100; >= `CAPA_LOWER_LIMIT_MODE_FULL` | The upper capacity limit of the battery, capacity mode `full`. |
| `CAPA_LOWER_LIMIT_MODE_FULL` | 95 | 60-100; <= `CAPA_UPPER_LIMIT_MODE_FULL` | The lower capacity limit of the battery, capacity mode `full`. |
| `CAPA_MODE` | `high` | `system-default`, `system-health`, `health`, `high`, `full` | The capacity mode to use. `system-default` turns the conservation mode off at all times. `system-health` turns the conservation mode on at all times. `health`, `high` and `full` will use the corresponding lower and upper capacity limit settings. |

## Licensing

See the `LICENSE` file.

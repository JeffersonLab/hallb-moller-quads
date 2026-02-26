## Manufacturer's manuals
* 2001:  https://clasweb.jlab.org/wiki/images/9/9c/Dynapower-40V-8000A.pdf
* 2020:  https://clasweb.jlab.org/wiki/images/d/de/Dynapower-generic-comms.pdf

## Hall B controls software
* General
  * Quad current calculation based on `MBSY2C_energy`:  [quadCurrent.c](quadCurrent.c)
  * GUI screenshot: [cs-studio.png](cs-studio.png)
* 2001 Dynapower
  * Traditional EPICS VME device support for old DVME628 and XY240 analog/digital I/O boards
  * [dynabc.db](dynabc.db) 
* 2020 Dynapower
  * RS-485, Moxa terminal server, and a soft IOC
  * EPICS Soft Channel support (in use)
    * Database:  [dynapower-2022-soft.db](dynapower-2022-soft.db)
    * Python "daemon":  [dynapower.py](dynapower.py)
  * EPICS StreamDevice support with I/O-Intr (unmaintained)
    * Database:  [dynapower-2022-iointr.db](dynapower-2022-iointr.db)
    * Protocol:  [dynapower-2022.proto](dynapower-2022.proto)
  * Ramp sequencer:  [ramp.st](ramp.st)

## Dynapower 2020 Quirks
* Readbacks
  * Contrary to the manufacturer's manual, there's no polling support, only 1 Hz unsolicited readbacks
  * Hence the attempt at EPICS I/O-Intr, StreamDevice support
* Serial termination sequence
  * It's odd, very long, and undocumented
  * IIRC, it changes depending on the power supply's on/off/remote state
    * If so, we didn't need/care to support the other state
  * Once it changed across a power supply reboot, with no software/hardware changes!
    * https://github.com/JeffersonLab/clas12-epics/commit/94faf3e001f06f268c8c992a34b8a253919b076a
    * As a result, [dynapower.py](dynapower.py) and [dynapower-2022.proto](dynapower-2022.proto) probably aren't in-sync regarding termination
* Ramping to full current in one shot isn't supported by the power supply, hence the ramp sequencer above
* EPICS SteamDevice I/O-Intr support probably has a deadlock bug, hence the Soft Channel EPICS support above
* MOXA terminal servers probably have a timeout on one-way comms, hence the keepalive mechanism and dedicated heartbeat alarm PV
* _See corresponding comments in the linked EPICS support code for all these quirks!_

## Operations
* The current must be set based on the beam energy (`MBSY2C_energy`) via the calculation above
* Tweaking the current setpoint, in real time, must also be supported
* If Hall B doesn not have write access, our Moller procedure will change only slightly:
  * phone call with MCC will now include turning the quads on
  * the on/off/setpoint steps for the quadrupoles will be dropped from our Moller sequencer
    * but no changes to readback checks (status, current)
  * and, of course, PV name changes

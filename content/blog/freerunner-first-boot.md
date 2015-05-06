---
date: 2008-08-14 03:42:31+00:00
slug: freerunner-first-boot
title: Freerunner First Boot
categories:
  - FreeRunner
tags:
  - FreeRunner
  - Neo
---

Here's some notes on my initial experience setting up the [Neo
Freerunner](http://wiki.openmoko.org/wiki/FreeRunner_Overview). I've been
meaning to write this post for a while now and most of this is already old
stuff but I'm posting it anyhow for reference. I purchased the Neo Freerunner
fully aware that it was a developer phone but my hope was that I could at least
ssh into the device and make/receive a few phone calls. I'm happy to report
that after first booting I was able to get most things functioning within a few
hours.<!--more-->

**First Boot**

There's several [distributions](http://wiki.openmoko.org/wiki/Distributions)
for the Freerunner which can get quite confusing but the one that comes stock
with the Freerunner is referred to as
[2007.2](http://wiki.openmoko.org/wiki/Om_2007.2). First time booting up the
Freerunner you're presented the home screen for 2007.2. You can also
[boot](http://wiki.openmoko.org/wiki/Boot) into NAND and NOR flash which allows
you to update the kernel, root filesystem and the boot loader (U-Boot).

My first mission was to ssh into the device. Followed the instructions on the
wiki for setting up [USB
networking](http://wiki.openmoko.org/wiki/USB_Networking).  By default the IP
address of the Freerunner is 192.168.0.202. On the desktop side you first have
to ifconfig the usb0 interface and setup the correct routes. Here's the script
I run on my desktop after connecting the Freerunner:

{{< highlight bash >}}
#!/bin/bash

/sbin/ifconfig usb0 192.168.0.200 netmask 255.255.255.0
/sbin/route add -host 192.168.0.202/32 dev usb0
{{< /highlight >}}

One extra step I had to do was configure my firewall to allow connections
to/from usb0. I'm running Ubuntu hardy 8.04 and using Firestarter. Open up
Firestarter:

- Preferences -> Firewall -> Network Settings
- Set 'Local network connected device' to:  Unknown device (usb0)
- Check 'Enable internet connection sharing'

Verified usb0 network connections:

```
$ ping -I usb0 192.168.0.202
$ ssh root@192.168.0.202
```

Once connected to the Freerunner next step was to get the date to display on
the home screen. To do this I just followed the [instructions on the
wiki](http://wiki.openmoko.org/wiki/Today/2007.2#Adjust_UI_components_at_runtime)
for customizing the today page (run these commands on the Neo):

```
# dbus-launch gconftool-2 -t boolean -s /desktop/poky/interface/reduced false
# /etc/init.d/xserver-nodm restart
```

Here's a screenshot of the home screen:


{{< figure src="/media/neo-clock.png" >}}

**Upgrade Software**

Once I was able to successfully ssh into the Neo and verifed that I could also
connect to the internet from the Neo I wanted to upgrade to the latest software
release. To do this you use [opgk](http://wiki.openmoko.org/wiki/Opkg) (package
management system based on Ipkg). The first time you upgrade from the software
release shipped with the Neo you have to first upgrade dropbear (ssh server)
from the terminal on the Neo, then you can ssh back into the Neo and upgrade
the rest of the software:

```
# opkg update
On the Neo, open Terminal and run: # opkg install dropbear
Then ssh to neo and run: # opkg upgrade
```

At this point I rebooted and inserted my T-Mobile sim card and microSD card.
Once back at the home screen it showed I was registered to the T-Mobile network
and I opened up the dialer app and placed my first call!

**Set up Timezone and correct date/time**

To fix the timezone run this from the Neo:
```
# opkg install tzdata tzdata-americas
# ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
# /etc/init.d/xserver-nodm restart
```

To set the correct time using ntp run:
```
# opkg install ntpclient
# ntpclient -s -h pool.ntp.org
# hwclock --systohc
```

**WLAN**

Next up was connecting the Neo to my wireless LAN. The wireless interface on
the Neo is eth0. First have to make sure WLAN device is turned on which it
seemed to be by default when you first boot. You can check this by holding down
the power button for a few seconds which should pop up a menu showing the state
of the various devices. Here's the script I use to connect the Neo to my WLAN:

{{< highlight bash >}}
#!/bin/sh

/sbin/ifconfig eth0 down
/sbin/ifconfig eth0 up
/sbin/iwconfig eth0 key restricted 'xxxxx'
/sbin/iwconfig eth0 essid 'xxxx'
/sbin/udhcpc eth0
{{< /highlight >}}

**GPS**

[tangoGPS](http://www.tangogps.org/) rocks. This app is amazing and it worked
right out of the box. Followed the [directions on the
wiki](http://wiki.openmoko.org/wiki/Getting_Started_with_your_Neo_FreeRunner#Use_the_GPS)
to get it up and running. There was an
[issue](http://wiki.openmoko.org/wiki/GPS_Problems) getting a fix with the SD
card installed but by the time I tried this out they already had a kernel
update which fixed the issue. I had no problem getting a fix and my TTFF was
35s with the SD card in. Here's some screenshots of tangoGPS in action:

{{< figure src="/media/screenshot-1.png" >}}

{{< figure src="/media/screenshot-2.png" >}}

I also installed and ran [AGPS
Test](http://wiki.openmoko.org/wiki/Howto_Test_Your_GPS_with_agpsui) which is a
program for testing out GPS on the Neo. It shows some nice graphs of the
various satellites you're currently connected to and their signal strengths:

{{< figure src="/media/screenshot-4.png" >}}

{{< figure src="/media/screenshot-5.png" >}}

**Bugs/Issues**

Overall I was impressed by how much I was able to get working the first time
around however there's definitely a few issues I came across. The most
concerning was the [GSM
buzzing](http://wiki.openmoko.org/wiki/Freerunner_Hardware_Issues#Poor_Audio_Quality)
during phone calls. On the Neo side everything sounds fine but the person on
the other end hears a very loud buzzing noise. Here's the [latest
update](http://lists.openmoko.org/pipermail/hardware/2008-August/000288.html)
from the hardware list regarding the issue. I tried tweaking the various alsa
settings in `/usr/share/openmoko/scenarios/gsmhandset.state` with some luck but
still wasn't able to find the right balance to completely eliminate the
buzzing. Still trying to wrap my head around which alsa settings do what but I
found playing with alsamixer during a live call to be helpful. The basic
procedure goes something like this:

1. ssh to FreeRunner
2. Make a phone call
3. While call is in progress run alsamixer
4. Tweak settings to minimize buzzing/echo
5. While call is still in progress run: `$ alsactl store -f gsmhandset-test1.txt`

Now you can diff this new file against the original
(/usr/share/openmoko/scenarios/gsmhandset.state) and see which settings were
changed. This is really the only thing holding me back from using the Neo as my
primary phone so I look forward to a possible fix.

I found using the Terminal on the Neo rather clunky due to the lack of
characters available on the keyboard. For example there's no <TAB> or '/'. I'm
sure there's ways to customize the keyboard. Looks like only vi is available by
default on the Neo so I plan on seeing if I can find a vim package (.ipk) or
figuring out how to compile vim for the Neo.

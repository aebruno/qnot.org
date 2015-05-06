---
date: 2007-08-21 02:16:30+00:00
slug: xplanet-view-of-hurricane-dean
title: Xplanet view of Hurricane Dean
categories:
  - Linux
---

I'm a big fan of [Xplanet](http://xplanet.sourceforge.net/) and every year
during the hurricane season there's no better way to liven up your desktop than
to download the latest [cloud maps](http://xplanet.sourceforge.net/clouds.php)
and watch the path of the storm. <!--more-->Here's a screenshot of my desktop showing
[hurricane dean](http://en.wikipedia.org/wiki/Hurricane_Dean_(2007)):

{{< figure src="/media/dean_xplanet_large.jpg" >}}

I cron a script to download the latest cloud maps every 4 hours or so. The
xplanet command I run is as follows:

{{< highlight bash >}}
xplanet -origin sun -north orbit \
        -config xplanet.conf -label \
        -marker_file brightStars \
        -target earth \
        -latitude 22 \
        -longitude -78 \
        -radius 30 \
        -labelpos +30+30
{{< /highlight >}}

Here's my xplanet.conf:

{{< highlight bash >}}
[earth]
cloud_map=clouds_2048.jpg
magnify=20

[moon]
magnify=20
{{< /highlight >}}

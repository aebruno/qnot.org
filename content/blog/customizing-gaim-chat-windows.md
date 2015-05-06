---
date: "2007-01-14 10:09:52+00:00"
slug: "customizing-gaim-chat-windows"
title: "Customizing Gaim Chat Windows"
categories:
  - Linux
---

[Gaim](http://gaim.sf.net) is an excellent instant messaging client with
support for multiple protocols and runs on several different
[platforms](http://gaim.sourceforge.net/about.php). For the longest time I've
wanted to customize the background color of my chat windows so they resemble my
xterm settings of green text on a black background. There doesn't seem to be an
easy way to do this via Gaim's preferences and after a little digging I finally
got it working.<!--more-->

The most recent version of Gaim uses [GTK+ 2.0](http://www.gtk.org) and the
background color for chat windows can be customized by adding some styles to
your `~/.gaim/gtkrc-2.0` file. You can also customize key bindings, fonts, and
other widgets in Gaim by tweaking this file but I'm just going to discuss the
settings for the chat windows in this post. I'm no GTK+ guru but I found the
[API docs](http://www.gtk.org/tutorial/x2138.html) and this
[mini-FAQ](http://ometer.com/gtk-colors.html) helpful and gave a nice
introduction to styles and themes in GTK+.

To customize the colors in your chat windows edit your `~/.gaim/gtkrc-2.0` file
or create if it doesn't exist and add the following lines:

{{< highlight css >}}
style "gaim-dark" {
    base[NORMAL]="#000000"
    text[NORMAL]="#00FF00"
    GtkIMHtml::hyperlink-color="#007FFF"
    GtkWidget::cursor-color="#60AFFE"
    GtkWidget::secondary-cursor-color="#A4D3EE"
}
widget "*gaim_gtkconv_imhtml" style "gaim-dark"
widget "*gaim_gtkconv_entry" style "gaim-dark"
{{< /highlight >}}

`base[NORMAL]` sets the background color and `text[NORMAL]` sets the color of
the text. You can tweak the colors to your liking restart Gaim and your chat
windows should now be customized. I didn't find a way to change the color of
the screen names displayed in the chat window. Digging through the source code
it looks like these colors are hardcoded  using `#define SEND_COLOR "#204a87"`
and `#define RECV_COLOR "#cc0000"` around line number 86 inside the file
[./gtk/gtkconv.c](https://svn.sourceforge.net/svnroot/gaim/trunk/gtk/gtkconv.c)
of the Gaim source. You could always try changing these values and re-compiling
Gaim. I haven't tested this but seems like it should work.  Here's a screen
shot of my customized chat window:

{{< figure src="/media/gaim_green_black.jpg" >}}

There is also a plugin which comes with Gaim called _Gaim GTK+ Theme Control_
which seems to provide a GUI interface for editing your `~/.gaim/gtkrc-2.0`
file but I didn't see any options for customizing the chat windows. In the Gaim
FAQ there is also a link to a [sample gtkrc-2.0](http://gaim.sourceforge.net/gtkrc-2.0) 
which gives some good examples of other customizations.

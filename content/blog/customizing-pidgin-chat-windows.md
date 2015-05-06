---
date: 2007-07-07 05:53:55+00:00
slug: customizing-pidgin-chat-windows
title: Customizing Pidgin Chat Windows
categories:
  - Hacks
  - Linux
---

In my [previous post]({{< ref "blog/customizing-gaim-chat-windows.md" >}}) I discussed
customizing Gaim chat windows. Since then Gaim has formally changed it's name
to [Pidgin](http://pidgin.im/pidgin/home/) due to [legal issues with
AOL](http://pidgin.im/~elb/cgi-bin/pyblosxom.cgi/going_public.html). I finally
upgraded to Pidgin and had to do a few minor tweaks to get the same chat window
customizations as before. <!--more--> I updated `~/.purple/gtkrc-2.0` which previously
resided in `~/.gaim` and changed the widget names from `gaim_gtkconv_*` to
`pidgin_conv_*`. Here's my updated `~/.purple/gtkrc-2.0` file:

```
style "pidgin-dark" {
    base[NORMAL]="#000000"
    text[NORMAL]="#00FF00"
    GtkIMHtml::hyperlink-color="#007FFF"
    GtkWidget::cursor-color="#60AFFE"
    GtkWidget::secondary-cursor-color="#A4D3EE"
}
widget "*pidgin_conv_imhtml" style "pidgin-dark"
widget "*pidgin_conv_entry" style "pidgin-dark"
```

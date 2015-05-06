---
date: 2010-09-14 04:29:59+00:00
slug: logging-out-without-killing-a-process
title: Logging out without killing a process
categories:
  - Linux
---

Here's the scenario, you're logged into your favorite *nix box and are using
bash as your shell. You fired off some process which is going to take a while
to run (and forgot to run [screen](http://www.gnu.org/software/screen/)) and
you want to logout without killing that process. <!--more-->The command to use is
[disown](http://www.gnu.org/software/bash/manual/bashref.html#Job-Control-Builtins).
Here's a really simple example:

```
$ ssh some-host
$ perl script-that-chugs-along.pl
$ Ctrl-Z (suspend)
$ bg (put it in background)
$ disown -h
$ logout
```

The `disown` command allows you to remove jobs from the list of active jobs
associated with your login shell. Here's an excerpt from the bash man page: 

> Without options, each _jobspec_ is removed from the table of active jobs. If
> the `-h` option is given, the job is not removed from the table, but is marked
> so that `SIGHUP` is not sent to the job if the shell receives a `SIGHUP`.

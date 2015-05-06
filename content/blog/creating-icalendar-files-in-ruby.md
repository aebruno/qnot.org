---
date: 2007-02-07 06:24:50+00:00
slug: creating-icalendar-files-in-ruby
title: Creating iCalendar Files in Ruby
categories:
  - Ruby
---

I recently came across a great ruby module called
[icalendar](http://icalendar.rubyforge.org/) for working with
[iCalendar](http://en.wikipedia.org/wiki/ICalendar) files. For a quick example
here's some code that generates the [Buffalo Sabres](http://www.sabres.com)
06/07 schedule in iCalendar format. The source data comes from the Excel
spreadsheet available [here](http://www.sabres.com/downloads_html.cfm) which
gets converted to CSV before running through the script.<!--more-->

{{< highlight ruby >}}
require 'rubygems'
require 'icalendar'
require 'csv'

if ARGV.size != 1
    puts "usage: ruby sabres_ical [schedule.csv]"
    exit;
end

cal = Icalendar::Calendar.new

CSV.open(ARGV[0], 'r') do |row|
    event = cal.event
    event.timestamp = DateTime.now
    event.summary = row[0]
    event.description = row[0]
    event.location = row[16] 

    start_date = Date.parse(row[1])
    end_date = Date.parse(row[3])
    game_time = row[2]

    event.start = DateTime.parse(start_date.to_s + " " + game_time)

    # Games usually last about 3 hours
    (h,m,s) = game_time.split(":")
    endTime = [h.to_i + 3,m,s].join(":")
    event.end = DateTime.parse(end_date.to_s + " " + endTime)
end

puts cal.to_ical
{{< /highlight >}}

Here's an example of the output which is sent to stdout:

```
BEGIN:VCALENDAR
VERSION:2.0
CALSCALE:GREGORIAN
PRODID:iCalendar-Ruby
BEGIN:VEVENT
DTEND:20061006T223000
UID:2007-01-16T17:59:38-0800_408345411@sugaree
DESCRIPTION:Sabres vs. Montreal
SUMMARY:Sabres vs. Montreal
DTSTART:20061006T193000
DTSTAMP:20070116T175938
SEQ:0
LOCATION:HOME
END:VEVENT
BEGIN:VEVENT
DTEND:20061014T220000
UID:2007-01-16T17:59:38-0800_606587692@sugaree
DESCRIPTION:Sabres vs. NY Rangers
SUMMARY:Sabres vs. NY Rangers
DTSTART:20061014T190000
DTSTAMP:20070116T175938
SEQ:0
LOCATION:HOME
END:VEVENT
```

If you're a Sabres fan and not able to run ruby scripts you can download the
iCal version of the [Sabres 06/07 schedule here](/data/Sabres-06-07.ics) 
for importing into your favorite [calendaring](http://www.mozilla.org/projects/calendar/sunbird/)
program. For some reason there are some games missing in the source Excel
spreadsheet so unfortunately they will also be missing in the iCalendar
version. I don't make any guarantees to it's correctness so if you find an
error or miss a game you've been warned.

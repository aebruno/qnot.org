---
date: 2007-01-15 08:05:01+00:00
slug: creating-sparklines-with-jfreechart
title: Creating Sparklines with JFreeChart
categories:
  - Java
---

[Sparklines](http://en.wikipedia.org/wiki/Sparkline) are very small charts
usually displayed along side some text and help quickly compare time series
data. They are usually rendered without any axis, labels, or tick marks and
appear as just a simple line. Sparklines were developed by [Edward
Tufte](http://www.edwardtufte.com/) and further explained
[here](http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001OR&topic_id=1).<!--more-->

[JFreeChart](http://www.jfree.org/jfreechart/) does not have any built in
classes for creating sparklines but are easily created by adjusting a few
settings in the basic charting classes. Here's a few quick examples of some
sparklines generated using JFreeChart:

Name   | Trend
-------|------------------------------------------------------------
Foo 90 | ![](/media/sparkline.png)
Bar 34 | ![](/media/sparkline1.png)
Baz 54 | ![](/media/sparkline2.png)

To create sparklines using JFreeChart you just need to turn off the display of
labels, tickmarks, lines, etc. on the domain/range axis as well as the XYPlot.

Here's a complete example:

{{< highlight java >}}
import java.io.File;
import java.io.IOException;
import java.util.Calendar;
import java.util.Date;
import java.util.Random;

import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.DateAxis;
import org.jfree.chart.axis.DateTickUnit;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.StandardXYItemRenderer;
import org.jfree.data.time.Day;
import org.jfree.data.time.TimeSeries;
import org.jfree.data.time.TimeSeriesCollection;
import org.jfree.ui.RectangleInsets;

public class Sparkline {
    public static void main(String[] args) {
        TimeSeriesCollection dataSet = new TimeSeriesCollection();
        Day day = new Day();
        TimeSeries data = new TimeSeries("Sparkline", day.getClass());

        // XXX add real data here
        Random r = new Random();
        Calendar c = Calendar.getInstance();
        for(int i = 0; i < 100; i++) {
            int val = r.nextInt(100);
            if(val < 50)
                val += 50;
            c.add(Calendar.DATE, 7);
            Date date = c.getTime();
            data.add(new Day(date), val);
        }

        dataSet.addSeries(data);

        // The sparkline is created by setting a bunch of the visible 
        // properties on the domain, range axis and the XYPlot 
        // to false
        DateAxis x = new DateAxis();
        x.setTickUnit(new DateTickUnit(DateTickUnit.MONTH, 1));
        x.setTickLabelsVisible(false);
        x.setTickMarksVisible(false);
        x.setAxisLineVisible(false);
        x.setNegativeArrowVisible(false);
        x.setPositiveArrowVisible(false);
        x.setVisible(false);

        NumberAxis y = new NumberAxis();
        y.setTickLabelsVisible(false);
        y.setTickMarksVisible(false);
        y.setAxisLineVisible(false);
        y.setNegativeArrowVisible(false);
        y.setPositiveArrowVisible(false);
        y.setVisible(false);

        XYPlot plot = new XYPlot();
        plot.setInsets(new RectangleInsets(-1, -1, 0, 0));
        plot.setDataset(dataSet);
        plot.setDomainAxis(x);
        plot.setDomainGridlinesVisible(false);
        plot.setDomainCrosshairVisible(false);
        plot.setRangeGridlinesVisible(false);
        plot.setRangeCrosshairVisible(false);
        plot.setRangeAxis(y);
        plot.setRenderer(new StandardXYItemRenderer(
                StandardXYItemRenderer.LINES));

        JFreeChart chart = new JFreeChart(
            null,
            JFreeChart.DEFAULT_TITLE_FONT,
            plot, false
        );
        chart.setBorderVisible(false);

        try {
            ChartUtilities.saveChartAsPNG(
                new File("sparkline.png"),
                chart,
                100,
                30
            );
        } catch(IOException e) {
            System.err.println("Failed to render chart as png: "
                    + e.getMessage());
            e.printStackTrace();
        }
    }
}
{{< /highlight >}}

---
date: 2007-08-15 03:06:55+00:00
slug: rotate-labels-jfreechart
title: Rotate Labels JFreeChart
categories:
  - Java
---

When creating a chart that has rather long labels for the x-axis it is
sometimes desirable to rotate them a bit so they fit on the plot. The method to
use is `setCategoryLabelPositions(..)` on the `CategoryAxis` class. <!--more-->Here's a
quick example:

![](/media/rotate_labels.png)

And the code..

{{< highlight java >}}
import java.io.File;
import java.io.IOException;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.ChartColor;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.axis.CategoryLabelPositions;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.data.category.DefaultCategoryDataset;

public class RotateLabels {
    public static void main(String[] args) {
        DefaultCategoryDataset dataSet = new DefaultCategoryDataset();
        dataSet.addValue(51, "series", "Colonel Forbin");
        dataSet.addValue(92, "series", "The Lizards");
        dataSet.addValue(33, "series", "Wilson");
        dataSet.addValue(77, "series", "Rutherford the Brave");
        dataSet.addValue(37, "series", "The Unit Monster");
        dataSet.addValue(97, "series", "The Famous Mockingbird");
        dataSet.addValue(67, "series", "Poster Nutbag");

        JFreeChart chart = ChartFactory.createBarChart(
            "Gamehendge",
            null,
            null,
            dataSet,
            PlotOrientation.VERTICAL,
            false,
            false,
            false
        );

        CategoryPlot plot = (CategoryPlot)chart.getPlot();
        CategoryAxis xAxis = (CategoryAxis)plot.getDomainAxis();
        xAxis.setCategoryLabelPositions(CategoryLabelPositions.UP_45);

        chart.setBackgroundPaint(ChartColor.WHITE);
        try {
            ChartUtilities.saveChartAsPNG(new File("chart.png"), chart, 400, 300);
        } catch(IOException e) {
            e.printStackTrace();
        }
    }
}
{{< /highlight >}}

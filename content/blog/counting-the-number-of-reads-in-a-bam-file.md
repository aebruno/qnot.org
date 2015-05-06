---
date: 2012-04-14 02:31:54+00:00
slug: counting-the-number-of-reads-in-a-bam-file
title: Counting the number of reads in a BAM file
categories:
  - Bioinformatics
  - Java
---

The output from short read aligners like
[Bowtie](http://bowtie-bio.sourceforge.net/index.shtml) and
[BWA](http://bio-bwa.sourceforge.net/) is commonly stored in
[SAM/BAM](http://samtools.sourceforge.net/) format. When presented with one of
these files a common first task is to calculate the total number of alignments
(reads) captured in the file. In this post I show some examples for finding the
total number of reads using samtools and directly from Java code. <!--more--> For the
examples below, I use the HG00173.chrom11 BAM file from the 1000 genomes
project which can be downloaded
[here](ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/data/HG00173/alignment/). 

First, we look at using the samtools command directly. One way to get the total
number of alignments is to simply dump the entire SAM file and tell samtools to
count instead of print (`-c` option):

```
$ samtools view -c HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
5218322
```

If we're only interested in counting the total number of mapped reads we can
add the `-F 4` flag. Alternativley, we can count only the unmapped reads with
`-f 4`:

```
# Mapped reads only
$ samtools view -c -F 4 HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
5068340

# Unmapped reads only
$ samtools view -c -f 4 HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
149982
```

To understand how this works we first need to inspect the SAM format. The SAM
format includes a bitwise FLAG field described
[here](http://samtools.sourceforge.net/samtools.shtml#5). The `-f/-F` options
to the samtools command allow us to query based on the presense/absence of bits
in the FLAG field. So `-f 4` only output alignments that are unmapped (flag
0x0004 is set) and `-F 4` only output alignments that are _not_ unmapped (i.e.
flag 0x0004 is not set), hence these would only include mapped alignments.  

An example for paired end reads you could do the following. To count the number
of reads having both itself and it's mate mapped:

```
$ samtools view -c -f 1 -F 12 HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
4906035
```

The `-f 1` switch only includes reads that are paired in sequencing and `-F 12`
only includes reads that are _not_ unmapped (flag 0x0004 is not set) and where
the mate is _not_ unmapped (flag 0x0008 is not set). Here we add `0x0004 +
0x0008 = 12` and use the `-F` (bits not set), meaning you want to include all
reads where neither flag 0x0004 or 0x0008 is set. For help understanding the
values for the SAM FLAG field there's a handy web tool
[here](http://picard.sourceforge.net/explain-flags.html). 

There's also a nice command included in samtools called `flagstat` which
computes various summary statistics. However, I wasn't able to find much
documentation describing the output and it's not mentioned anywhere in the man
page. This
[post](http://biostar.stackexchange.com/questions/12502/what-does-samtools-flagstat-results-mean)
examines the C code for the flagstat command which provides some insight into
the output.

```
$ samtools flagstat HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
5218322 + 0 in total (QC-passed reads + QC-failed reads)
273531 + 0 duplicates
5068340 + 0 mapped (97.13%:-nan%)
5205999 + 0 paired in sequencing
2603248 + 0 read1
2602751 + 0 read2
4881994 + 0 properly paired (93.78%:-nan%)
4906035 + 0 with itself and mate mapped
149982 + 0 singletons (2.88%:-nan%)
19869 + 0 with mate mapped to a different chr
15271 + 0 with mate mapped to a different chr (mapQ>=5)
```

The above shows a few simple examples using the samtools command but what if
you wanted to count the total number of reads in code? I've been using the
excellent [Picard](http://picard.sourceforge.net/) Java library as of late and
haven't found a simple way to do this via the API. I was looking for a fast way
to compute this without having to scan the entire BAM file each time. Would
love to see this added as a public function to the
[BAMIndexMetaData](http://picard.sourceforge.net/javadoc/net/sf/samtools/BAMIndexMetaData.html)
object or similar. Here's a function I wrote to calcuate the total mapped reads
from a BAM file. This makes use of the BAM index for speed and obviously
requires you to first index your BAM file:

{{< highlight java >}}
public int getTotalReadCount(SAMFileReader sam) {
    int count = 0;

    AbstractBAMFileIndex index = (AbstractBAMFileIndex) sam.getIndex();
    int nRefs = index.getNumberOfReferences();
    for (int i = 0; i < nRefs; i++) {
        BAMIndexMetaData meta = index.getMetaData(i);
        count += meta.getAlignedRecordCount();
    }

    return count;
}
{{< /highlight >}}

This uses the BAMIndex to loop through each reference and sum the total mapped
reads. A complete working example is included below:

{{< highlight java >}}
import java.io.File;

import net.sf.samtools.AbstractBAMFileIndex;
import net.sf.samtools.BAMIndexMetaData;
import net.sf.samtools.SAMFileReader;

public class CountMapped {

    public static void main(String[] args) {
        File bamFile = new File(args[0]);

        SAMFileReader sam = new SAMFileReader(bamFile, 
                                 new File(bamFile.getAbsolutePath() + ".bai"));

        AbstractBAMFileIndex index = (AbstractBAMFileIndex) sam.getIndex();

        int count = 0;
        for (int i = 0; i < index.getNumberOfReferences(); i++) {
            BAMIndexMetaData meta = index.getMetaData(i);
            count += meta.getAlignedRecordCount();
        }

        System.out.println("Total mapped reads: " + count);
    }

}
{{< /highlight >}}

Requires the Picard Java library. To compile/run:

```
$ javac -cp samtools.jar CountMapped.java
$ java -cp samtools.jar:. CountMapped HG00173.chrom11.ILLUMINA.bwa.FIN.low_coverage.20111114.bam
Total mapped reads: 5068340
```

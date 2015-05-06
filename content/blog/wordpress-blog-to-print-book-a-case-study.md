---
date: 2011-04-09 05:05:18+00:00
slug: wordpress-blog-to-print-book-a-case-study
title: WordPress Blog to Print Book - A Case Study
categories:
  - Hacks
  - PHP
  - XML
---

In this post I discuss my experience converting a WordPress blog into a print
book. This is by no means a generic how-to guide but more along the lines of a
case study. There's a number of ways one could tackle this problem however I
wasn't able to find any existing methods that fit my needs. Specifically, I
wanted to convert the content of a WordPress blog into a high quality print
ready PDF book (complete with chapters, sections, table of contents, images,
figures, page numbering, index, etc.) which could then be sent to various
[POD](http://en.wikipedia.org/wiki/Print_on_demand) publishers such as
[Lulu](http://www.lulu.com/) for printing. <!--more-->I wanted to streamline as much of
the process as possible to allow for regenerating the PDF book as new posts are
made. Ideally there would be a WordPress plugin for this but to make such a
plugin generic enough would be tricky and require many assumptions to be made
regarding the structure of your blog (i.e. what constitutes a chapter or a
section?, etc.). In this post I describe how I ended up creating a PDF book
from WordPress and discuss a few challenges I encountered along the way. A
brief disclaimer: this post is intended for folks who are familiar with *nix
command line and enjoy mucking around in code (and don't mind slinging around
some XML here and there). It's not for the faint of heart but hopefully it will
be useful to others interested in a similar outcome.

If you'd rather skip this epic post and dive right into the code you can browse
it all over on [github](https://github.com/aebruno/wp2print). There's a
[README](https://github.com/aebruno/wp2print/blob/master/README) file and a
[Makefile](https://github.com/aebruno/wp2print/blob/master/Makefile) which
details how to run wp2print and includes a simple example. 

**Background and Assumptions**

The idea for this project came about as my family has been writing a private
blog that I want to be able to share with my children some day. I've often
thought about giving them a copy of the blog when their much older and wondered
what would be the best way to preserve the content ensuring it's viewable years
down the road. I thought by creating a physical copy of the blog I could have
something tangible to pass down through the generations. Using the services
provided by companies like Lulu and Blurb printing a book is as simple as
uploading a PDF and designing a cover. Having [worked](http://oreilly.com/) in
the publishing industry in a former life I had some experience generating PDF
books so I looked forward to the challenge. 

As my goal was to create a book I needed to convert the content of the blog
into an intermediate format which represented the book and could then be used
to generate a PDF file. As I had a good amount of experience slinging around
[DocBook](http://www.docbook.org/), my general idea was to export the content
from WordPress and convert it into DocBook. Then converting DocBook into a PDF
is fairly straightforward using the wonderful [DocBook
stylesheets](http://docbook.sourceforge.net/) and [Apache
FOP](http://xmlgraphics.apache.org/fop/). 

The first obvious challenge when converting a blog into a book is deciding how
to go about organizing the blog posts into chapters and sections. Our family
blog was authored in such a way that each post had only one tag (category) and
most importantly all posts were tagged chronologically. Meaning that all posts
in a given category were sequential. For example, posts 0-5 are all tagged with
"tag1", posts 6-10 are all tagged with "tag2", and so on. You can probably see
where this is going. Having authored the blog in this format allowed me to
easily use each tag as a Chapter and each post appeared as a section within
that chapter. If your unable to make these assumptions about your blog (and
most likely you won't be able to) just keep this in mind as we delve into the
code later on. You would need to modify the script I wrote and add in the
appropriate logic to slice your blog posts up into chapters/sections or however
you'd like to structure your DocBook file. I experimented with just making each
post a chapter (and even a series of DocBook
[articles](http://www.docbook.org/tdg5/en/html/article.html)) which isn't a bad
option however depending on the number of posts you may want to consider
omitting the table of contents.

A few other assumptions I made:
	
- All posts were written by the same author so I omitted displaying any author
  information. Easy enough to add in if needed
- All comments were excluded from the book. Comments are an important part of
  any blog but in this case my blog didn't have very many comments. I was most
  interested in the content of the post only and decided to omit any and all
  comments. These could certainly be added in but some thought would be needed
  on which DocBook element to use for structuring them within the book.
- There was one page (not a post) with the title "About" that I used as the
  preface for the book. This can be any post/page or omitted completely if
  desired.
- Access to the WordPress code that runs the blog. This won't work if your blog
  is hosted for example at WordPress.com. You'll need to export your blog and
  run it on your own server.

Here's a brief outline of the entire process. I'll go over each step in detail
in the next section. 

1. Convert WordPress content to DocBook using PHP and some XSLT
2. Convert DocBook to [XSL-FO](https://secure.wikimedia.org/wikipedia/en/wiki/XSL_Formatting_Objects) 
   using DocBook stylesheets
3. Convert XSL-FO to PDF using Apache FOP
4. Upload PDF file to Lulu and order print book

**Convert WordPress content to DocBook**

First step was to convert the blog into DocBook. This was by far the most
challenging step. My first attempt was to use the
[Export](https://en.support.wordpress.com/export/) feature in WordPress which
dumps the entire contents of your blog in XML format (WordPress eXtended RSS)
and write an XSLT to convert into DocBook. This turned out to be slightly
harder than I anticipated because of how the content of each post was formatted
in the WordPress XML dump. It appeared to be in the native format WordPress
uses to store the post in the database and I didn't want to have to write a
custom WordPress post renderer for DocBook. I decided to instead write a fairly
simple PHP script which used the WordPress API to render each post in HTML just
like it normally would if someone visited the site, then convert the HTML to
DocBook. I found converting the HTML to DocBook was slightly easier than having
to parse the native WordPress format. I did this in two steps, first I wrote a
PHP script to generate a quasi-DocBook file which uses the WordPress API to
embed the HTML content of each post within a `<section/>`. Then I wrote an XSLT
which transforms the quasi-DocBook and embedded HTML into a final valid DocBook
file. The main PHP code is
[here](https://github.com/aebruno/wp2print/blob/master/lib/export-docbook.php).
You'll need to change the include paths in
[config.php](https://github.com/aebruno/wp2print/blob/master/lib/config.php) to
point to your WordPress installation (see the
[Makefile](https://github.com/aebruno/wp2print/blob/master/Makefile) for a
complete example).  The XSLT is
[here](https://github.com/aebruno/wp2print/blob/master/wp-html2docbook.xsl). It
looks for various HTML tags that appear in my blog and converts those to valid
DocBook elements. I built up the XSLT by trial and error. I first just rendered
the quasi-DocBook generated from the PHP script as PDF. The DocBook stylesheets
have a nice feature in that any invalid DocBook elements it encounters are
highlighted in red in the resulting PDF. By iterating through the invalid
elements I was able to add the correct templates to my XSLT to account for all
HTML tags found in my blog posts. You'll most certainly need to modify this
XSLT file to suite your specific needs but should serve as a decent starting
point. Here's an example of the HTML generated by WordPress for an image
included in a blog post:

{{< highlight xml >}}
<div id="attachment_155" class="wp-caption aligncenter" style="width: 310px">
  <a href="/wp-content/media/2008/11/image.jpg">
        <img class="size-medium wp-image-155" title="image title" src="/wp-content/media/2008/11/image-300x218.jpg" alt="image alt" width="300" height="218"/>
  </a>
  <p class="wp-caption-text">This is a description of the image</p>
</div>
{{< /highlight >}}

Which then gets converted to a DocBook [mediaobject](http://www.docbook.org/tdg5/en/html/mediaobject.html) element:

{{< highlight xml >}}
<para>
  <mediaobject>
    <imageobject>
       <imagedata align="center" fileref="images/2008/11/image.jpg" width="4.0in" depth="3.0in" scalefit="1" format="JPG"/>
    </imageobject>
    <caption><para>This is a description of the image</para></caption>
  </mediaobject>
</para>
{{< /highlight >}}

**A note about images...**

Care must be taken to ensure any images you want included in the book are print
ready. I ended up having quite a few images in my blog that I wanted to include
in the final PDF which required some extra work to get them ready for printing.
For best results you'll want make to be sure the resolution of your images are
at least 300ppi ([pixels per
inch](https://secure.wikimedia.org/wikipedia/en/wiki/Dots_per_inch#DPI_or_PPI_in_digital_image_files)).
See [this post on
Lulu](http://connect.lulu.com/t5/Interior-Formatting/What-resolution-DPI-should-my-images-have-to-achieve-optimum/ta-p/31434).
For example, if your image is 600x600px and you set the resolution to be
300ppi, the printed image will be roughly 2x2in. In my case I was printing a
6x9 book and after factoring in margins/spine/bleed etc. I calculated the
maximum print size I wanted each image was 4x3in (as defined in the DocBook XML
element `<imagedata width="4.0in" height="3.0in"/>` in the above example). As
most of the images were pictures, this print size ended up being large enough
so the photo was still viewable but small enough to allow for 2 images per
page. This meant that the minimum size (in pixels) each image had to be was
1200x900px. The problem was when we uploaded pictures to our blog we had
WordPress resize them to 500x400px (from their original size of 2816x2112px
from the camera). Fortunately, I still had the original image files which I
collected and used in the final PDF. Something to keep in mind if you have
images (especially photographs) in your blog that you want printed. I ran into
another edge case with the images which required a little bit of
[imagemagick](http://www.imagemagick.org). I had a few important pictures that
were taken with photo booth on a mac in which the original size image was a
mere 640x480px. I knew the print version of the images would look dreadful so
my only option was to resample them to a higher resolution. This can easily be
accomplished using imagemagick's [convert
command](http://www.imagemagick.org/script/command-line-options.php#resample):
  
```
$ convert -resample 300x orig.jpg hires.jpg
```

In summary, be sure your images are high enough resolution for printing. It's
definitely worth the extra work. I had roughly 100 images in my blog and all of
them turned out really nice in the final print book. I was quite impressed with
the quality of Lulu's printers. 

**DocBook --> XSL-FO --> PDF**

Converting DocBook to PDF was fairly straightforward using two excellent
projects [DocBook stylesheets](http://docbook.sourceforge.net/) and [Apache
FOP](http://xmlgraphics.apache.org/fop/). I won't cover how to install them on
your platform and refer you to the excellent INSTALL guides at the
[respective](http://docbook.sourceforge.net/release/xsl/current/INSTALL)
[sites](http://xmlgraphics.apache.org/fop/quickstartguide.html). If you happen
to be running Ubuntu using the stock packages should work fine. Simply run
`aptitude install fop docbook-xsl` and you should be all set. The basic goal
for this step was to use the DocBook XSL FO stylesheets to convert the DocBook
created from the previous step into XSL-FO which can be fed into Apache FOP for
conversion into PDF. This step required that an XSLT processor be installed
such as xsltproc (libXML), Saxon, Xalan, etc. I used xsltproc and can easily be
installed on Ubuntu `aptitude install xsltproc`. After running xsltproc I
passed the resulting XSL-FO output into Apache FOP to generate the final PDF.
For more details see the
[Makefile](https://github.com/aebruno/wp2print/blob/master/Makefile). Here's
the basic commands:
 
```
$ xsltproc /path/to/docbook-xsl/fo/docbook.xsl docbook-final.xml > book.fo
$ fop book.fo book.pdf
```

The DocBook XSL FO stylesheets provide a [generous number of
parameters](http://docbook.sourceforge.net/release/xsl/current/doc/fo/index.html)
for customizing the resulting FO. The default parameter settings produce a very
nice looking PDF but if you like to tweak things there's no shortage of knobs
to turn. As I ended up printing my book with Lulu there were a few specific
customizations that were required. First I was interested in printing a US
Trade 6x9 inch hard cover book so the default page
[width](http://docbook.sourceforge.net/release/xsl/current/doc/fo/page.width.html)/[height](http://docbook.sourceforge.net/release/xsl/current/doc/fo/page.height.html)
needed to be set accordingly. Some other tweaks I made included adjusting the
[margins](http://docbook.sourceforge.net/release/xsl/current/doc/fo/page.margin.inner.html)
slightly to provide some extra room on the [spine
edge](http://connect.lulu.com/t5/Interior-Formatting/How-big-should-my-margins-be/ta-p/31404)
of the book, customizing the [table of
contents](http://docbook.sourceforge.net/release/xsl/current/doc/fo/generate.toc.html)
to only include the chapter/sections, and [customizing the
indentation](http://docbook.sourceforge.net/release/xsl/current/doc/fo/body.start.indent.html)
of chapters and sections (in this case I didn't want any indentation). Here's
the resulting xsltproc command with the custom parameter settings:

{{< highlight bash >}}
$ xsltproc \
    --stringparam page.width 6in \
    --stringparam page.height 9in \
    --stringparam page.margin.inner 1.0in \
    --stringparam page.margin.outer 0.8in \
    --stringparam body.start.indent 0pt \
    --stringparam body.font.family  Times \
    --stringparam title.font.family Times \
    --stringparam dingbat.font.family Times \
    --stringparam generate.toc 'book toc title' \
    --stringparam hyphenate false \
    /path/to/docbook-xsl/fo/docbook.xsl \
    docbook-final.xml > book.fo
{{< /highlight >}}

**A note about Fonts..**

The last and most important configuration I made was with fonts. Lulu requires
fonts to be fully
[embedded](https://secure.wikimedia.org/wikipedia/en/wiki/Portable_Document_Format#Fonts)
which means any font you use in your PDF [must be
embedded](http://www.lulu.com/help/embed_fonts) (the font files are included
directly in the PDF file) or else they will reject the PDF. Embedding fonts is
supported by Apache FOP but requires some custom configuration. First I had to
decide which font to use. Fonts can be really tricky and I didn't want to get
too fancy. Using a single font for the entire book was fine with me and I
decided to stick with a traditional Times New Roman font. I ended up using the
FreeSerif TrueType font from [GNU
FreeFont](http://www.gnu.org/software/freefont/). It was already installed on
my Ubuntu machine and very easy to embed with Apache FOP. By default these
fonts are installed in `/usr/share/fonts/truetype/freefont/`.There's lots of
other free fonts out there that you could use including the [Liberation
Fonts](https://fedorahosted.org/liberation-fonts/) and even the [Micro$oft True
Type Core Fonts](http://packages.ubuntu.com/lucid/ttf-mscorefonts-installer)
which can be installed on Ubuntu by running `aptitude install msttcorefonts`.
To configure Apache FOP to use GNU Free Fonts and embed them into the final PDF
I created a file called `userconf.xconf` with the following lines:

{{< highlight xml >}}
<?xml version="1.0"?>
<fop version="1.0">
<renderers>
   <renderer mime="application/pdf">
      <!-- Full path to truetype fonts to be embedded in PDF file -->
      <fonts>
        <font embed-url="file:///usr/share/fonts/truetype/freefont/FreeSerif.ttf">
          <font-triplet name="Times" style="normal" weight="normal"/>
        </font>
        <font embed-url="file:///usr/share/fonts/truetype/freefont/FreeSerifBold.ttf">
          <font-triplet name="Times" style="normal" weight="bold"/>
        </font>
        <font embed-url="file:///usr/share/fonts/truetype/freefont/FreeSerifItalic.ttf">
          <font-triplet name="Times" style="italic" weight="normal"/>
        </font>
        <font embed-url="file:///usr/share/fonts/truetype/freefont/FreeSerifBoldItalic.ttf">
          <font-triplet name="Times" style="italic" weight="bold"/>
        </font>
      </fonts>
   </renderer>
</renderers>
</fop>
{{< /highlight >}}

Then ran fop passing the -f option like so: `fop -f userconf.xconf book.fo
book.pdf`. Note the `<font-triplet **name="Times"** />` attribute must match
the `body.font.family Times` XSLT parameter passed to xsltproc command. 

**Simple Example**

All the code described in this post is available on
[github](https://github.com/aebruno/wp2print). I also include a simple example
to demonstrate the entire conversion process and provide some sample PDFs to
see how final book renders. I created a simple test blog consisting of
Shakespeare's Sonnets I thru X and exported the content in WordPress eXtended
RSS so you can then import into a fresh install of WordPress. I tested using
the latest version of WordPress at the time of this writing (v3.1). To try it
out yourself download the code for wp2print and read thru the
[README](https://github.com/aebruno/wp2print/blob/master/README) file which
outlines all the gory details. The
[Makefile](https://github.com/aebruno/wp2print/blob/master/Makefile) outlines
the general process and should provide a good starting point for experimenting.
Here's some sample PDFs that were rendered from the example Shakespeare blog:
    
- [Book with Chapters and Sections](/media/book-with-chapters.pdf)
- [Book with all posts as DocBook Articles](/media/book-with-articles.pdf)
- [Raw DocBook output](https://github.com/aebruno/wp2print/blob/master/sample/sample-docbook.xml)

**Conclusion**

With the help of a few simple scripts it's possible to create a high quality
print ready PDF book from a WordPress blog. Depending on the content of the
blog you'll most certainly need to tailor these scripts to suite your specific
requirements. The main challenges are figuring out how you want to organize
your blog posts into the framework of a book and then modifying the XSLT
templates to convert the WordPress html markup of your blog into valid DocBook
elements. The services offered by print on demand publishers such as Lulu
provide an easy way to turn the resulting PDF into a high quality paper book.  



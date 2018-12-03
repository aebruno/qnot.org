---
date: 2007-01-25 08:39:43+00:00
slug: converting-mif-to-xml
title: Converting MIF to XML
categories:
  - XML
---

MIF (Maker Interchange Format) is an ASCII text representation of a
[FrameMaker](http://en.wikipedia.org/wiki/FrameMaker) document. You can export
your FrameMaker documents into this text based representation to allow for
parsing and manipulation by external tools outside of FrameMaker. You can also
import MIF files back into FrameMaker. If your interested in reading more about
MIF you can check out the [MIF
Reference](http://partners.adobe.com/public/developer/en/framemaker/MIF_Reference.pdf)
from Adobe (link may be out of date).<!--more-->

There's a great perl module on CPAN for working with MIF files called
[FrameMaker::MifTree](http://search.cpan.org/perldoc?FrameMaker%3A%3AMifTree).
It's a subclass of
[Tree::DAG_Node](http://search.cpan.org/perldoc?Tree%3A%3ADAG_Node) and
provides a nice interface for modifying the in-memory tree structure and
dumping back out into MIF. The only downside to this module is that it's very
slow especially with larger MIF files.

At [O'Reilly](http://www.oreilly.com) we've had to work with MIF files quite a
bit and have taken several different approaches for processing MIF most of
which turn out to be unmaintainable scripts that are not very pleasant to work
with. One of the ideas [Andrew S.](http://www.oreillynet.com/pub/au/1848) and
[Keith](http://kfahlgren.com/blog/) came up with was to convert MIF to an
intermediate XML format which would allow us to process MIF using XML tools
such as XSLT and XQuery. From this intermediate XML format we can transform to
DocBook, WordML, or even convert back to MIF again for later importing into
FrameMaker. This approach was very appealing as it can greatly reduce the
number of one off scripts and allow us to benefit from the wide variety of
libraries for parsing and transforming XML.<!-- more -->

For example, the following snippet from a MIF file:

```
#
# Example of MIF 
#
<FontCatalog
 <Font
  <FTag `Acronym'>
  <FPosition FSubscript>
  <FLocked No>
 > # end of Font
> # end of FontCatalog
```

Would get converted to this XML:

{{< highlight xml >}}
<?xml version="1.0"?>
<!--
 Example XML from MIF
-->
<mif>
  <FontCatalog>
    <Font>
      <FTag>`Acronym'</FTag>
      <FPosition>FSubscript</FPosition>
      <FLocked>No</FLocked>
    </Font>
  </FontCatalog>
</mif>
{{< /highlight >}}

This is not a new idea and one tool I know of which seems to do a similar task
is called [MIFML](http://www.leximation.com/tools/mifml/) written by Leximation
which coverts MIF to MIFML (an intermediate XML dialect they created).
Unfortunately, it only runs on Windows and is not open source. They have
however released the [DTD](http://www.leximation.com/tools/mifml/mifml.dtd.txt)
they are using for MIFML.

I thought this would be a fun problem to take a stab at so I built tool called
`mif2xml` that produces output that looks a lot like the example above. You can
download a [copy here](https://github.com/aebruno/mif2xml/downloads) or browse
the [source code](https://github.com/aebruno/mif2xml) online via svn.

The guts of `mif2xml` include a lexer `mif.ll` and a helper class for writing
out MIF XML tags.  I chose to create a `c++` lexer so I could make use of the
STL `stack` and `string` classes. Here's the `mif.ll` file which gets run
through flex to generate the lexer:

{{< highlight cpp >}}
/** 
 * Copyright (c) 2007 Andrew Bruno <aeb@qnot.org>
 * Licensed under the GNU General Public License version 2
 */

%{
#include <iostream>
#include <stack>
#include <string>
#include <miftag.h>
using namespace std;

stack<Tag> tags;
string data;
string facet;
%}

%option  noyywrap
%option  c++
%x DATA
%x STR
%x FACET

ID                [A-Za-z][A-Za-z0-9]*
TAG               "<"{ID}" "
TAG_END           ">"
NONNEWLINE        [^\r|\n|\r\n]
NEWLINE           [\r|\n|\r\n]
WHITE_SPACE_CHAR  [ \n\t]

%%

<INITIAL>{TAG}  {
    Tag tag;
    string name = YYText();
    tag.name = name.substr(1, name.length()-2);
    tags.push(tag);
    tag.writeStart();
    data = string("");
    BEGIN(DATA);
}

<INITIAL>{TAG_END} {
    if(!tags.empty()) {
        Tag tag = tags.top();
        tag.writeEnd();
        tags.pop();
    }
}

<INITIAL>^"="[a-zA-Z][a-zA-Z0-9]*{NEWLINE} {
    facet = string("");
    string str = string(YYText());
    facet.append(str);
    BEGIN(FACET);
}

<INITIAL>{WHITE_SPACE_CHAR}+   {  /* eat up whitespace */ }
<INITIAL>{NONNEWLINE}          {  /* eat up everything else  */ }

<DATA>{NEWLINE}  {
    if(!tags.empty()) {
        Tag tag = tags.top();
        tag.value = data;
    }
    BEGIN(INITIAL);
}
<DATA>"`"  {  BEGIN(STR); }
<DATA>{TAG_END}  {
    if(!tags.empty()) {
        Tag tag = tags.top();

        if(data.length() > 0) {
            tag.value = data;
        }
        tag.writeEnd();
        tags.pop();
    }
    BEGIN(INITIAL);
}
<DATA>[^\n|\r|\r\n|`|>] {
    string str = string(YYText());
    data.append(str);
}

<STR>"'"  {
    if(!tags.empty()) {
        Tag &tag = tags.top();
        if(tag.value.length() == 0) {
            tag.value = "`'";
        }
    }
    BEGIN(INITIAL);
}
<STR>[^']*  {
    if(!tags.empty()) {
        Tag &tag = tags.top();
        string str = string(YYText());
        string buf = "`";
        buf.append(str);
        buf.append("'");
        tag.value = buf;
    }
}

<FACET>^"=EndInset"{NEWLINE} {
    string str = string(YYText());
    facet.append(str);
    writeFacet(facet);
    BEGIN(INITIAL);
}

<FACET>.*{NEWLINE} {
    string str = string(YYText());
    facet.append(str);
}

%%

int main(int argc, char **argv) {
    cout << "<?xml version=\"1.0\"?><mif>";
    FlexLexer* lexer = new yyFlexLexer;
    while(lexer->yylex() != 0);
    cout << "</mif>";
    return 0;
}
{{< /highlight >}}

Here's the `miftag.h` file which contains a helper class for writing out MIF
XML tags. Rather than having a dependency on libxml or some other XML
processing library I choose to just implement the XML output by hand. It's not
nearly as robust but it worked out ok for a first pass.

{{< highlight cpp >}}
/** 
 * Copyright (c) 2007 Andrew Bruno <aeb@qnot.org>
 * Licensed under the GNU General Public License version 2
 */

#ifndef __MIFTAG__
#define __MIFTAG__

#include <string>
using namespace std;

class Tag {
    public:
        string name;
        string value;

        void writeEnd();
        void writeStart();
};

void Tag::writeEnd() {
    if(!this->value.empty()) {
        /* escape xml special chars */
        string::size_type size = this->value.size();
        for(string::size_type i = 0; i < size;) {
            if(this->value[i] == '&') {
                this->value.replace(i, 1, "&amp;");
                i += 4;
                size += 4;
            } else if(this->value[i] == '<') {
                this->value.replace(i, 1, "&lt;");
                i += 3;
                size += 3;
            } else if(this->value[i] == '>') {
                this->value.replace(i, 1, "&gt;");
                i += 3;
                size += 3;
            } else if(this->value[i] == '"') {
                this->value.replace(i, 1, "&quot;");
                i += 5;
                size += 5;
            } else {
                i++;
            }
        }

        /* Trim leading spaces */
        while(this->value[0] == ' ') {
            this->value.erase(0, 1);
        }

        /* Trim trailing spaces */
        while(this->value[this->value.size()-1] == ' ') {
            this->value.erase(this->value.size()-1, 1);
        }

        cout << value << "</" << this->name << ">";
    } else {
        cout << "</" << this->name << ">";
    }
}

void Tag::writeStart() {
    cout << "<" << this->name << ">";
}

void writeFacet(string facet) {
    cout << "<_facet><![CDATA[" << facet << "]]></_facet>";
}

#endif
{{< /highlight >}}

Finally a quick and dirty Makefile:

{{< highlight make >}}
all:
	flex++ mif.ll
	g++ -I. -o mif2xml lex.yy.cc -lfl

clean:
	rm -f lex.yy.cc *.o mif2xml
{{< /highlight >}}


The code above has not been thoroughly tested on all possible MIF files so your
mileage may vary. We currently use a version of `mif2xml` at O'Reilly on the
occasions we need to process MIF and has been working out quite well. The XML
generated from `mif2xml` is then run through a set of custom transforms written
in XSLT 2.0 which transform the MIF XML to DocBook, WordML, and various other
formats.

In my [next post]({{< ref "converting-mif-to-xml-java-version.md" >}})
I'll discuss a pure Java version of `mif2xml` which uses a great library called
[JFlex](http://www.jflex.de/) for generating the MIF lexer.

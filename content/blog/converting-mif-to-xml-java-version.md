---
date: 2007-02-01 03:57:01+00:00
slug: converting-mif-to-xml-java-version
title: Converting MIF to XML - Java Version
categories:
  - Java
  - XML
---

In my [previous post]({{< ref "converting-mif-to-xml.md" >}}) I discussed a
tool called `mif2xml` for converting MIF files to an intermediate XML dialect.
In this post I'll talk about the Java port of `mif2xml` called `mif2xml-j`
which you can download [here](https://github.com/aebruno/mif2xml-j) including
just the [executable
jar](https://github.com/downloads/aebruno/mif2xml-j/mif2xml-0.3.jar).<!--more-->

[JFlex](http://www.jflex.de/) is a lexical analyzer generator for Java and is
the library I chose to use for creating the MIF lexer. The first step was to
get JFlex integrated into my build environment. For this project I decided to
use [ant](http://ant.apache.org/) but integrating JFlex into another build
environment should be straightforward. I created the following
directory structure:

{{< highlight bash >}}
--/
  |-- src/main/jflex/               - JFlex lexical specifications
  |-- src/main/resources/MANIFEST   - Defines main class for executable jar
  |-- src/main/java/                - Java source
  |-- lib/                          - 3rd party libraries (JFlex.jar)
  |-- build.xml                     - Ant build file
{{< /highlight >}}

JFlex comes bundled with a `JFlexAntTask` which provides a very convenient
`<jflex/>` task. Here's a snippet of the ant build file I created which shows
how to set it up:
{{< highlight xml >}}
<property name="src"   location="${basedir}/src/main/java" />
<property name="lib" location="${basedir}/lib" />
<property name="scanner-file" value="${basedir}/src/main/jflex/mif.jflex" />

<path id="classpath">
    <pathelement location="${build}" />
    <fileset dir="${lib}">
        <include name="*.jar" />
    </fileset>
</path>

<taskdef classpathref="classpath" classname="JFlex.anttask.JFlexTask" name="jflex" />

<target name="jflex" description="Generate the MIF lexer">
    <echo message="Generating the MIF Lexer" />
    <jflex file="${scanner-file}" destdir="${src}" />
</target>
{{< /highlight >}}

I found writing the lexical specification in JFlex and flex to be very similar.
JFlex has a great [user manual](http://www.jflex.de/manual.html) which contains
a lot of useful info. Here's the `mif.jflex` file:

{{< highlight java >}}
/*
 * Copyright 2007 Andrew Bruno <aeb@qnot.org>
 * Licensed under the Apache License, Version 2.0
 */

package org.qnot.mif2xml;
import java.util.Stack;

%%

%{
  private Stack<Tag> tags = new Stack<Tag>();
  private StringBuffer data = new StringBuffer();
  private StringBuffer facet = new StringBuffer();
%}

%line
%char
%standalone
%class  MifLexer
%xstate DATA
%xstate STR
%xstate FACET

ID=[A-Za-z][A-Za-z0-9]*
TAG="<"{ID}" "
TAG_END=">"
NONNEWLINE=[^\r|\n|\r\n]
NEWLINE=[\r|\n|\r\n]
WHITE_SPACE_CHAR=[ \n\t]

%%

<YYINITIAL> { 
   {TAG}   {
        Tag tag = new Tag();
        tag.setName(yytext().substring(1, yytext().length()-1));
        tags.push(tag);
        tag.writeStart();
        data = new StringBuffer();
        yybegin(DATA);
    }

    {TAG_END}   {
        if(!tags.empty()) {
            Tag tag = (Tag)tags.pop();
            tag.writeEnd();
        }
    }

    ^"="[a-zA-Z][a-zA-Z0-9]*{NEWLINE} {
        facet = new StringBuffer();
        facet.append(yytext());
        yybegin(FACET);
    }

    {WHITE_SPACE_CHAR}+   {  /* eat up whitespace */ }
    {NONNEWLINE}          {  /* eat up everything else  */ }
}

<DATA> {
    {NEWLINE}  {
        if(!tags.empty()) {
            Tag tag = (Tag)tags.pop();
            tag.setValue(data.toString());
            tags.push(tag);
        }
        yybegin(YYINITIAL);
    }
    "`"  {  yybegin(STR); }
    {TAG_END}  {
        if(!tags.empty()) {
            Tag tag = (Tag)tags.pop();
            String value = tag.getValue();

            String dataStr = data.toString();
            if(dataStr != null && dataStr.length() > 0) {
                value = dataStr;
            }

            if(value != null) {
                value = value.replaceAll("^\\s+", "");
                value = value.replaceAll("\\s+$", "");
            }

            tag.setValue(value);
            tag.writeEnd();
        }
        yybegin(YYINITIAL);
    }
    [^\n|\r|\r\n|`|>] {
        data.append(yytext());
    }
}

<STR> {
    "'"  {
        if(!tags.empty()) {
            Tag tag = (Tag)tags.pop();
            if(tag.getValue() == null || tag.getValue().length() == 0) {
                tag.setValue("`'");
            }
            tags.push(tag);
        }
        yybegin(YYINITIAL);
    }
    [^']*  {
        if(!tags.empty()) {
            Tag tag = (Tag)tags.pop();
            StringBuffer buf = new StringBuffer();
            buf.append("`");
            buf.append(yytext());
            buf.append("'");
            tag.setValue(buf.toString());
            tags.push(tag);
        }
    }
}

<FACET> {
    ^"=EndInset"{NEWLINE} {
        facet.append(yytext());
        Tag.writeFacet(facet.toString());
        yybegin(YYINITIAL);
    }

    .*{NEWLINE} {
        facet.append(yytext());
    }
}
{{< /highlight >}}

I created a simple `Tag` class to encapsulate a MIF XML tag and handle writing
out each tag. The `MifLexer` keeps a stack of `Tag` instances while it's
processing the input file:

{{< highlight java >}}
/*
 * Copyright 2007 Andrew Bruno <aeb@qnot.org>
 * Licensed under the Apache License, Version 2.0
 */

package org.qnot.mif2xml;

public class Tag {
    private String name;
    private String value;

    public String getName() {
        return this.name;
    }

    public String getValue() {
        return this.value;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public void writeEnd() {
        if(value != null && value.length() > 0) {
            System.out.print(escape(value) + "</" + name + ">");
        } else {
            System.out.print("</" + name + ">");
        }
    }

    public void writeStart() {
        System.out.print("<" + name + ">" );
    }

    public static void writeFacet(String facet) {
        System.out.print("<_facet><![CDATA[");
        System.out.print(facet);
        System.out.print("]]></_facet>");
    }

    private String escape(String str) {
        str = str.replaceAll("&", "&amp;");
        str = str.replaceAll("\"", "&quot;");
        str = str.replaceAll(">", "&gt;");
        str = str.replaceAll("<", "&lt;");
        str = str.replaceAll("^\\s+", "");
        str = str.replaceAll("\\s+$", "");

        return str;
    }
}
{{< /highlight >}}

There's a separate `Main` class which creates a new instance of the `MifLexer`
class for processing the file passed in on the command line. I'd like to
eventually extend this class so that it handles command line options and
possibly even runs some XSLT's over the generated MIF XML.

{{< highlight java >}}
/*
 * Copyright 2007 Andrew Bruno <aeb@qnot.org>
 * Licensed under the Apache License, Version 2.0
 */

package org.qnot.mif2xml;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.FileReader;

public class Main {
    public static void main(String[] args) {
        if(args.length != 1) {
            System.err.println("Usage : mif2xml <inputfile>");
            System.exit(1);
        }

        try {
            MifLexer scanner = new MifLexer(new FileReader(args[0]));
            System.out.print("<?xml version=\"1.0\"?><mif>");
            scanner.yylex();
            System.out.print("</mif>");
        } catch(FileNotFoundException e) {
            System.out.println("File not found : "+args[0]);
        } catch(IOException e) {
            System.out.println("I/O error scanning file '"+args[0]+"': "+e.getMessage());
        } catch(Exception e) {
            System.out.println("Unexpected exception: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
{{< /highlight >}}

To run the code download the [executable
jar](https://github.com/downloads/aebruno/mif2xml-j/mif2xml-0.3.jar) and run
{{< highlight bash >}}
$ java -jar mif2xml-0.1.jar myfile.mif
{{< /highlight >}}

The MIF XML will be printed to stdout.

---
date: 2008-01-25 04:53:16+00:00
slug: creating-executable-jars-with-maven
title: Creating executable jars with Maven
categories:
  - Java
---

After wrestling with [Maven
assemblies](http://maven.apache.org/plugins/maven-assembly-plugin/) for while I
finally figured out how to build executable jars. The Maven assembly plugin
allows you to define ways to package up your project for distribution by
creating various assembly descriptor files. <!--more-->Here's a quick example of a Maven
assembly for building an executable jar (uberjar). For this example we'll
create a brand new project from scratch but it should be easy to see how to
integrate into an existing project.

First step lets create a test project:

```
$ mvn archetype:create -DgroupId=org.qnot.example -DartifactId=hello-world
$ cd hello-world
```

Next add a few dependencies to the project. In this example we'll add a few
libraries from jakarta commons. The <dependencies/> section in the pom.xml
should now look like this:

{{< highlight xml >}}
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>commons-cli</groupId>
      <artifactId>commons-cli</artifactId>
      <version>1.1</version>
    </dependency>
    <dependency>
      <groupId>commons-lang</groupId>
      <artifactId>commons-lang</artifactId>
      <version>2.3</version>
    </dependency>
  </dependencies>
{{< /highlight >}}

Create a META-INF/ directory to store the MANIFEST.MF file which defines the
main class in the executable jar.

```
$ mkdir -p src/main/resources/META-INF/
$ echo 'Main-Class: org.qnot.example.App' > MANIFEST.MF 
```

Create a src/assemble directory to store the assembly descriptor files

```
$ mkdir src/assemble
```

Next we'll create the actual assembly descriptor file which defines how to
package up the jar. Create the file src/assemble/exe.xml with the following
xml:

{{< highlight xml >}}
<assembly>
  <id>exe</id>
  <formats>
    <format>jar</format>
  </formats>
  <includeBaseDirectory>false</includeBaseDirectory>
  <dependencySets>
    <dependencySet>
      <outputDirectory></outputDirectory>
      <outputFileNameMapping></outputFileNameMapping>
      <unpack>true</unpack>
      <scope>runtime</scope>
      <includes>
        <include>commons-lang:commons-lang</include>
        <include>commons-cli:commons-cli</include>
      </includes>
    </dependencySet>
  </dependencySets>
  <fileSets>
    <fileSet>
      <directory>target/classes</directory>
      <outputDirectory></outputDirectory>
    </fileSet>
  </fileSets>
</assembly>
{{< /highlight >}}

Inside the `<dependecySets/>` is where you can add all the libraries you'd like
to include in the uberjar. These must also be defined in your pom.

Finally, add the maven-assembly-plugin to the pom:
{{< highlight xml >}}
  <build>
    <finalName>hello-world</finalName>
    <plugins>
      <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
        <configuration>
          <descriptors>
            <descriptor>src/assemble/exe.xml</descriptor>
          </descriptors>
          <archive>
            <manifestFile>src/main/resources/META-INF/MANIFEST.MF</manifestFile>
          </archive>
        </configuration>
      </plugin>
    </plugins>
  </build>
{{< /highlight >}}

To run the assembly and build the executable jar:

```
$ mvn assembly:assembly
$ java -jar target/hello-world-exe.jar
Hello World! 
```

I tested the hello-world example using the latest Maven release (2.0.8) and
maven-assembly-plugin-2.2-beta-1. If you run into any issues try and update
your Maven plugins by running:

```
$ mvn -U compile
```

You can download the example hello-world project
[here](/data/hello-world.tar.gz).

---
date: 2011-07-01 04:15:21+00:00
slug: passtab-store-passwords-in-your-wallet
title: passtab - store passwords in your wallet
categories:
  - Hacks
  - Java
  - passtab
  - passwords
---

Here's a quote from [Bruce
Schneier](http://www.schneier.com/blog/archives/2005/06/write_down_your.html)
that essentially sums up the motivation for this post:

> We're all good at securing small pieces of paper. I recommend that people write
> their passwords down on a small piece of paper, and keep it with their other
> valuable small pieces of paper: in their wallet.

I recently read an excellent [blog
post](http://blog.jgc.org/2010/12/write-your-passwords-down.html) by John
Graham-Cumming in which he presents a elegant system for writing down your
passwords using a [Tabula Recta](http://en.wikipedia.org/wiki/Tabula_recta). I
was inspired by this concept so I created a tool called
[passtab](https://github.com/aebruno/passtab) which aims to provide a
light-weight system for managing passwords based on his idea. <!--more-->This post is
about the general usage of passtab and presents some of the password management
capabilities. This is not your grandmothers password manager so if you're
looking for a nice GUI point and click application that's easy to use you can
stop reading right here. This is for hardcore folks who enjoy looking up their
passwords in archaic
[tablets](https://secure.wikimedia.org/wikipedia/en/wiki/Tabula_recta) invented
by ancient cryptographers with last names like
[Trithemius](https://secure.wikimedia.org/wikipedia/en/wiki/Johannes_Trithemius).
For the impatient, you can grab a copy of the latest version on
[github](https://github.com/aebruno/passtab/archives/master).  

**Introducing passtab**

[passtab](https://github.com/aebruno/passtab) is a light-weight system for
managing passwords using a Tabula Recta. passtab has two main features: 1.
generating random Tabula Recta's in PDF format for printing and storing in your
wallet 2. fetching passwords from the Tabula Recta (password managment). These
features are independent and you can use passtab to only generate PDFs or
optionally make use of the password management features. One unique benefit is
the ability to have both an electronic and paper copy of your passwords. You
can download the binary release of passtab at github
[here](https://github.com/aebruno/passtab/archives/master). Unpack the
distribution and run `./bin/passtab --help` for a list of options. If the
startup shell script doesn't work you can run `java -jar lib/passtab-uber.jar
--help`. The following sections illustrate some use cases of passtab.

**Generate a random Tabula Recta in PDF**

passtab can generate random Tabula Recta's in PDF format. 

```
$ ./bin/passtab --format pdf --output passtab.pdf
Jun 12, 2011 11:16:29 AM org.qnot.passtab.PassTab generate
INFO: Generating a random Tabula Recta (might take a while)...
$ ls *.pdf
passtab.pdf
```

Here's an [example PDF](/media/passtab.pdf) generated from passtab. You can now
print this PDF out and store in your wallet!

**How to use the Tabula Recta**

Here's a simple example (taken directly from the
[README](https://github.com/aebruno/passtab/blob/master/README)), suppose we
have the following Tabula Recta:
    
```
     | A B C D E F G H I J K L M N 
   --|----------------------------
   A | _ u } I ` } R ) a < L : a A 
   B | - o ( : p # O % . _ ; ' j L 
   C | w c ( c y 2 h y ~ N O * > w 
   D | o : R m L % V , d H r Y B j 
   E | 9 , < 0 J p a o ) O w 0 w # 
   F | C j i } i z 2 $ O R 5 @ T I 
   G | Q - E m 8 N c / + u W Y V > 
   H | , y } U Y i j i q w q c - 4 
   I | K j W H e ; I ? E 7 H v 2 + 
   J | g * 7 4 E } a h Y z < " : w 
   K | . _ } I / J k 1 a D ^ ; p K 
   L | ` < A L c z } } I P ? 4 y T 
   M | F D < 8 < 0 R B t 9 X o B 2 
   N | I r O E m o a + Y W w ; : 7
```

And suppose we want to get our password for logging into webmail at acme.com.
We decide to use the first and last letter of the domain name as the start
row/column of the password and we want a password 8 characters in length. So we
start at the intersection of 'A' and 'E' and read off 8 characters diagonally
resulting in the password: `'#h,)RWc`

Defining a scheme for selecting the starting row/column for a given password is
completely up to the user and can be as simple or as complex as one desires.
The direction for reading the password is also up to the user to define (left,
right, diagonally, etc.). See John Graham-Cumming's excellent [blog
post](http://blog.jgc.org/2010/12/write-your-passwords-down.html) for more
examples. 

This method is slightly more complex than just writing down your passwords on a
sheet of paper but the added complexity offers some advantages:

1. Can store _all_ your passwords on a single sheet of paper
2. If someone steals this sheet of paper they'll have a harder time figuring
   out what your passwords are
3. Allows you to use strong random passwords
4. If you want to change your passwords just re-generate a new Tabula Recta.
   Your scheme for selecting passwords can stay the same

passtab makes no assumptions about how passwords are read nor does it know
anything about your scheme (unless you configure it). Now that you don't have
to remember long random passwords anymore what _do_ you need to remember when
using a Tabula Recta? Well first, you need to come up with a method for finding
the starting position for a given password. In the example above this can be as
simple as using characters from a domain/host name. But the beauty is you can
be as creative as you want. A scheme that works for most of your passwords
would probably be ideal but you can certainly generate multiple Tabula Recta's
if you like. Once you have a way of coming up with a starting location you need
to define a method for reading off the password. In passtab this is called a
`sequence`. In the example above we simply read 8 characters diagonally. But
again you can be creative here. You could read 8 characters diagonally skipping
every 3rd character, etc. Lastly, you'll need to remember what to do if you hit
the edge of the Tabula Recta before the end of the password. For example, if
you start at Z:Z and want to read 8 characters diagonally you can't because you
reached the end of the Tabula Recta. In passtab this is called a `collision`.
In this case we could just continue reading following the edge.

Using the Tabula Recta allows you to make use of long secure random passwords
and only have to remember three simple things. You also have _all_ your
passwords on a single sheet of paper that fits in your wallet.

**Custom Alphabets**

In passtab, a Tabula Recta consists of two alphabets. The header alphabet and
the data alphabet. The header alphabet is used for the row and column heading
of the Tabula Recta and forms the basis for finding the starting location of
the passwords. The data alphabet is used to generate the contents of the Tabula
Recta and passtab will randomly pick characters from this alphabet using a
cryptographically secure random number generator. By default, passtab uses a
header alphabet of `0-9A-Z` and a data alphabet consisting of all printable
ASCII characters. It's important to keep in mind that the data alphabet
directly effects the
[entropy](https://secure.wikimedia.org/wikipedia/en/wiki/Password_strength#Entropy_as_a_measure_of_password_strength)
of your passwords. passtab allows you to customize these alphabets allowing you
to generate any kind of Tabula Recta, for example:

```
$ ./bin/passtab -b A,B,C,D -a 'a,b,c,d,1,2,3,4,!,@,#'
Jun 12, 2011 10:24:26 PM org.qnot.passtab.PassTab generate
INFO: Generating a random Tabula Recta (might take a while)...
  A B C D 
A d 1 @ 4 
B c 4 @ 2 
C b 3 3 ! 
D 1 a @ 4 
```

Here's a Tabula Recta using greek symbols as the header alphabet (here's the
[example PDF](/media/passtab-greek.pdf)):

```
$ ./bin/passtab -b 'Σ,Τ,Π,ρ,ϋ,ψ' -a 'a,b,c,d,1,2,3,4,!,@,#'
Jun 12, 2011 11:26:00 PM org.qnot.passtab.PassTab generate
INFO: Generating a random Tabula Recta (might take a while)...
  Σ Τ Π ρ ϋ ψ 
Σ 1 2 1 d d c 
Τ 1 2 b b @ c 
Π 1 # c 3 2 @ 
ρ 4 2 d 2 @ 3 
ϋ 2 3 b 1 ! b 
ψ d @ # c ! a
```

**Password Management**

So this is all well and great, but in reality it can be a huge pain to have to
look up your webmail password in a Tabula Recta that's on a sheet of paper in
your wallet _every time you login_. For this reason, passtab has some optional
features to help read passwords from the Tabula Recta. This allows you to have
both a hard copy of the Tabula Recta in your wallet and an electronic version
stored on your hard drive for quick access to your passwords. This obviously
comes with some security considerations and care must be taken to protect the
passtab database as you would any ssh private key for example. If someone got a
hold of the passtab database file they could brute force your Tabula Recta. I
ended up creating an encrypted thumb drive and store my passtab configuration
and database files on it. You could also use gpg to encrypt it or any other
method to protect it from the bad guys. This next section discusses the
password management features of passtab.

First some definitions:

- **Direction**: a `direction` to move on the Tabula Recta. Valid values are
  `N,S,E,W,NE,NW,SE,SW`
- **Sequence Item**: a `sequence item` consists of a `length` and `direction`.
  For example, `12:SE` would mean move 12 characters in the SE direction
  (diagonally)
- **Sequence**: a `sequence` is a list of `sequence items`. This allows you to
  define arbitrary sequences for reading passwords. For example, `4:SE,3:N,1:S`
  would mean read 4 characters SE (diagonally) followed by 3 characters N (up)
  followed by 1 character S (down)
- **Collision**: a `collision` defines what directions to move if we hit the
  edge of the Tabula Recta before the end of the password. You can define more
  than one direction and they will be tried in order. For example,
  N,NE,E,SE,S,SW,W,NW would mean if we hit a wall try those directions in order
  until we're able to move again

**Generate a Tabula Recta in PDF and save to a passtab database**

passtab can generate a Tabula Recta in PDF along with storing it in a passtab
database. The passtab database is stored in [JSON](http://json.org/) format and
can be easily accessed outside of passtab (any language that can read JSON
files). Again, you'll want to store that JSON file someplace safe. For example:

```
$ ./bin/passtab --dbsave --name mypasstab
Jun 12, 2011 10:48:33 PM org.qnot.passtab.PassTab generate
INFO: Generating a random Tabula Recta (might take a while)...
$ ls mypasstab.*
mypasstab.json  mypasstab.pdf
```

**Reading passwords from the passtab database**

Once we've created our passtab database we can now fetch passwords by telling
passtab the starting location and the sequence to read. For example, suppose we
want to read a password starting at row 'B' and column 'N' and we want a
password 10 characters in length reading diagonally:

```
$ ./bin/passtab -i mypasstab.json --getpass B:N --sequence 9:SE
o6,ZzH{e$@
```

Copy the password to the clipboard using xclip:

```
$ ./bin/passtab -i mypasstab.json --getpass B:N --sequence 9:SE --chomp | xclip
```

We used `9:SE` as our sequence because passtab includes the character at the
start location in the password. If we didn't want to include this character we
can optionally skip it like so:

```
$ ./bin/passtab -i mypasstab.json --getpass B:N --sequence 10:SE --skipstart
6,ZzH{e$@_
```

Define a list of directions to try in the event of a collision. This will try
the directions N,S,E,W in order until we can move again. Here we start at Z:Z
and can't move SE (diagonally) so we try N (up) which works so we move N (up)
until we hit another collision:

```
$ ./bin/passtab -i mypasstab.json --getpass Z:Z --sequence 9:SE --collision N,S,E,W
a((vy&0bV&
```

**Conclusion**

This post introduced a new tool called passtab for managing passwords using a
Tabula Recta. I'm sure it has plenty of bugs so use at your own risk and if by
chance you find it somewhat useful I'd be very interested in any feedback.   

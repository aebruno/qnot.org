#!/usr/bin/perl

use strict;
use Getopt::Long;
use RTF::Tokenizer;

my %opts = ();
GetOptions (\%opts, 'from=s', 'to=s');

my $filename = shift;

die "Please provide an rtf file to parse.\n" unless $filename;

my $tokenizer = RTF::Tokenizer->new( file => $filename);

while( my ( $type, $arg, $param ) = $tokenizer->get_token() ){
    last if $type eq 'eof';

    if($type eq 'control' and $arg eq 'revtbl') {
        my $match = 0;
        put($type, $arg, $param) if $opts{from} and $opts{to};

        my $brace = 1;

        while($brace > 0){
            my @attr = $tokenizer->get_token();

            $brace++ if $attr[0] eq 'group' and $attr[1] == 1;
            $brace-- if $attr[0] eq 'group' and $attr[1] == 0;

            if( $attr[0] eq 'text') {
                $attr[1] =~ s/;$//;

                if( $opts{from} and $opts{to} ){
                    if( $opts{from} eq $attr[1] ) {
                        $attr[1] = $opts{to};
                        $match = 1;
                    }

                    $attr[1] .= ';';
                    put( @attr);
                } else {
                    print $attr[1], "\n" unless $attr[1] eq 'Unknown';
                }
            } else {
                put(@attr) if $opts{from} and $opts{to};
            }
        }

        if($opts{from} and $opts{to} and !$match) {
            print STDERR "The author $opts{from} was not found in the document!\n";
        }
    } else {
        put($type, $arg, $param) if $opts{from} and $opts{to};
    }
}

sub put {
    my ($type, $arg, $param) = @_;

    if( $type eq 'group' ) {
        print $arg == 1 ? '{' : '}';
    } elsif( $type eq 'control' ) {
        print "\\$arg$param"; 
    } elsif( $type eq 'text' ) {
        print "\n$arg"; 
    }
}

__END__

=head1 NAME

revswapper - Swap Revision Authors

=head1 SYNOPSIS

revswapper [-from author -to new author] filename.rtf

=head1 OPTIONS

=over 4

=item B<-from>

The existing Author name.

=item B<-to>

The new Author name to replace with.

=back

=head1 DESCRIPTION

Swap revision authors within an rtf file. Called with no options will
list the current authors in the file. Prints output to STDOUT.

=head1 AUTHOR

Andrew Bruno <aeb@qnot.org>

=head1 COPYRIGHT

Copyright (C) 2004 Andrew Bruno

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

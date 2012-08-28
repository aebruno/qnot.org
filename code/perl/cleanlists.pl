#!/usr/bin/perl

use strict;
use RTF::Parser;

my $file = shift;

die "Please provide an rtf file to parse.\n" unless $file;

open(RTFIN, "< $file") or die "Failed  to open $file for reading: $!\n";

my $tokenizer = RTF::Tokenizer->new( file => \*RTFIN );

my @listoverride;
while(my ( $type, $arg, $param ) = $tokenizer->get_token()) {
    last if $type eq 'eof';

    if( $type eq 'control' and $arg eq 'listoverridetable' ) {
        my $brace = 1;

        while( $brace > 0 ) {
            my @attr = $tokenizer->get_token();

            $brace++ if $attr[0] eq 'group' and $attr[1] == 1; 
            $brace-- if $attr[0] eq 'group' and $attr[1] == 0; 

            if( $attr[0] eq 'control' and ($attr[1] eq 'listid' or $attr[1] eq 'ls')) {
                push( @listoverride, $attr[2] ); 
            }
        }
    }
}

seek(RTFIN, 0, 0);
my %list_map = @listoverride;

for my $key (keys %list_map) {
    my $matches = 0;

    while(<RTFIN>) {
        my @ls = $_ =~ m/\\(ls$list_map{$key})(?:\s|\\|\n|\})/g;

        $matches += scalar(@ls);
    }
    seek(RTFIN, 0, 0);

    if ($matches > 1) {
        delete $list_map{$key};
    }
}

seek(RTFIN, 0, 0);
$tokenizer->read_file( \*RTFIN );

while(my ( $type, $arg, $param ) = $tokenizer->get_token()) {
    last if $type eq 'eof';

    if( $type eq 'control' and ($arg eq 'listoverridetable' or $arg eq 'listtable') ) {
        put( $type, $arg, $param);
        my $brace = 1;

        my @listkeep;
        while( $brace > 0 ) {
            my @attr = $tokenizer->get_token();

            $brace++ if $attr[0] eq 'group' and $attr[1] == 1; 
            $brace-- if $attr[0] eq 'group' and $attr[1] == 0; 

            my @listitem;
            my $delete = 0;
            push( @listitem, \@attr);

            while( $brace > 1 ) {
                my @attr = $tokenizer->get_token();

                $brace++ if $attr[0] eq 'group' and $attr[1] == 1; 
                $brace-- if $attr[0] eq 'group' and $attr[1] == 0; 

                if( $attr[0] eq 'control' and $attr[1] eq 'listid') {
                    $delete = 1 if( exists $list_map{$attr[2]} ); 
                }

                push( @listitem, \@attr);
            }

            unless($delete) {
                push( @listkeep, \@listitem);
            }
        }

        for (@listkeep) {
            for (@$_) {
                put(@$_);
            }
        }
    } else {
        put( $type, $arg, $param );
    }
}

close(RTFIN);

sub put {
    my ($type, $arg, $param) = @_;

    if( $type eq 'group') {
        print $arg == 1 ? '{' : '}';
    } elsif( $type eq 'control' ) {
        print "\\$arg$param";
    } elsif( $type eq 'text') {
        print "\n$arg";
    }
}

__END__

=head1 NAME

cleanlists - Clean out unused list templates

=head1 SYNOPSIS

cleanlists filename.rtf

=head1 DESCRIPTION

Removes unused list templates. Prints ouput to STDOUT.

=head1 AUTHOR

Andrew Bruno <aeb@qnot.org>

=head1 COPYRIGHT

Copyright (C) 2004 Andrew Bruno

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

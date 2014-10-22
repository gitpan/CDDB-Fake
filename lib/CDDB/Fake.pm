# CDDB::Fake.pm -- CDDB File Faker
# RCS Info        : $Id: CDDB-Fake.pm,v 1.4 2003/09/08 20:37:44 jv Exp $
# Author          : Johan Vromans
# Created On      : Tue Mar 25 22:38:32 2003
# Last Modified By: Johan Vromans
# Last Modified On: Mon Sep  8 22:31:33 2003
# Update Count    : 95
# Status          : Unknown, Use with caution!

=head1 NAME

CDDB::Fake - Fake CDDB entries if you have none

=head1 SYNOPSIS

    use CDDB::Fake;
    my $cddb = CDDB::Fake->new("music/Egg/Egg/.nocddb");
    print "Artist: ", $cddb->artist, "\n";
    foreach my $track ( $cddb->tracks ) {
        print "Track ", $track->number, ": ", $track->title, "\n";
    }

=head1 DESCRIPTION

Sometimes there's no CDDB file available for a piece of music. For
example, when you created a collection of tracks from other albums. In
this case, a text file containing the name of the artist / album,
followed by a mere list of the track titles can be used as a
fall-back.

CDDB::Fake implements a part of the CDDB::File API based on manually
crafted fall-back files.

I've adopted the convention to name files with CDDB data C<.cddb>, and
the fake data C<.nocddb>.

For example, you can cut the results of a search at Gracenote
(cddb.com) and paste it into the file .nocddb. For example:

    Birelli Lagrene / Standards

       1. C'est Si Bon
       2. Softly, As in a Morning Sunrise
       3. Days of Wine and Roses
      ...
      12. Nuages

The titles may be optionally followed by trailing TABs (not spaces)
and a MM:SS time indicator.

A tool is included to generate a fake file from the names of the files
in the directory.

B<WARNING:> CDDB::Fake implements only a part of the CDDB::File API.

=cut

package CDDB::Fake;

$VERSION = "1.01";

use strict;
use warnings;
use Carp;

=head1 METHODS

=over 4

=item new I<file>

The new() package method takes the name of a file, and parses it. A
CDDB::Fake object is then created from the file data.

=cut

sub new {
    my ($pkg, $file) = @_;

    my $self = {};

    my $fh;
    if ( ref($file) ) {
	# For testing.
	$fh = $file;
    }
    else {
	open($fh, $file) or croak("$file: $!\n");
    }
    my $off = 150;
    my $state = 0;
    my $va = 0;
    while ( <$fh> ) {
	next unless /\S/;
	s/[\r\n]+$//;

	# State 0: Looking for artist/title.
	if ( $state == 0 ) {
	    if ( /^\s*(.+)\s+\/\s+(.*)/ ) {
		$self->{_artist} = _deblank($1);
		$self->{_title} = _deblank($2);
	    }
	    else {
		# Eponymous.
		$self->{_artist} = $self->{_title}  = _deblank($_);
	    }
	    $va = lc($self->{_artist}) eq "various";
	    $state++;
	    next;
	}

	# State 1: Processing tracks.
	if ( $state == 1 ) {
	    if ( /^\s*(\d+)\.?\s+(.*)/ ) {
		my ($tn, $tt, $tl) = (0+$1, $2);
		if ( $tt =~ /^(.*?)\t+ ?(\d+):(\d\d)\s*$/ ) {
		    $tt = _deblank($1);
		    $tl = 60 * $2 + $3;
		    $self->{_length} += $tl;
		}
		else {
		    $tt = _deblank($tt);
		}
		my $art = $self->{_artist};
		if ( $va ) {
		    if ( $tt =~ /^(.+?):\s+(.*)/ ) {
			$art = _deblank($1);
			$tt  = _deblank($2);
		    }
		    elsif ( $tt =~ /^(.+?)\s+\/\s+(.*)/ ) {
			$art = _deblank($1);
			$tt  = _deblank($2);
		    }
		}
		push(@{$self->{_tracks}},
		     CDDB::Fake::Track->new($art, $tn, $tt,
					    $tl, $off));
		$off += 75 * $tl if $tl;
		next;
	    }
	    else {
		$state++;
	    }
	}

	# State 2: Remainder (ext info).
	if ( $state == 2 ) {
	    $self->{_extd} = $_ . "\n";
	    $state++;
	    next;
	}

	# State 3: Rest of ext info.
	$self->{_extd} .= $_ . "\n";
    }

    bless $self, $pkg;
}

sub _deblank {
    my $t = shift;
    for ( $t ) {
	s/^\s+//;
	s/\s+$//;
	s/\s+/ /g;
	return $_;
    }
}

=item artist

Returns the name of the artist.

=cut

sub artist {
    my ($self) = @_;
    $self->{_artist};
}

=item title

Returns the name of the album.

=cut

sub title {
    my ($self) = @_;
    $self->{_title};
}

=item track_count

Returns the number of tracks.

=cut

sub track_count {
    my ($self) = @_;
    scalar(@{$self->{_tracks}});
}

=item tracks

Returns a list of track objects.

=cut

sub tracks {
    my ($self) = @_;
    @{$self->{_tracks}};
}

=item id

=item all_ids

Returns the (fake) id for this disc.

=cut

sub id { "00000000" }

sub all_ids { ("00000000") }

=item year

=item genre

=item submitted_by

=item processed_by

These methods return empty strings since the information is not
available in CDDB::Fake files.

=cut

sub year         { "" }
sub genre        { "" }
sub submitted_by { "" }
sub processed_by { "" }
sub revision     { 1  }

=item length

This method will return the accumulated length of all the tracks,
provided this information is present in the fake file.

=cut

sub length {
    my ($self) = @_;
    $self->{_length} || 0;
}

=item extd

Returns the extended disc information, that is everything that follows
the list of tracks in the fake file.

=cut

sub extd  {
    my ($self) = @_;
    $self->{_extd};
}

=back

=cut

package CDDB::Fake::Track;

sub new {
    my ($pkg, $disc, $num, $tt, $len, $off) = @_;
    bless [ $disc, $num, $tt, $len, $off ], $pkg;
}

=pod

Track objects provide the following methods:

=over 4

=item artist

The artist, usually the same as the artist of the disc.

=cut

sub artist { shift->[0] }

=item number

The track number, starting with 1.

=cut

sub number { shift->[1] }

=item title

The track title.

=cut

sub title  { shift->[2] }

=item length

The track length (in seconds).

This will be zero unless a track length was specified in the fake info.

=cut

sub length { shift->[3] }

=item offset

The track offset.

This will be bogus unless track offsets could be estimated using the
length information.

=cut

sub offset { shift->[4] }

=item extd

This method returns an empty string since the information is not
available in CDDB::Fake files.

=cut

sub extd { "" }

=head1 EXAMPLES

It is often handy to generalize the handling of real and fake files:

    use CDDB::File;	# the real one
    use CDDB::Fake;	# the fake one
    use Carp;

    # Return a CDDB::File object if a .cddb file is present, otherwise
    # return a CDDB::Fake onkect from a .nocddb file, if present.

    sub cddb_info($) {
	my $df = shift;
	croak("cddb_info(dir)\n") unless -d $df;
	return CDDB::File->new("$df/.cddb")   if -s "$df/.cddb";
	return CDDB::Fake->new("$df/.nocddb") if -s "$df/.nocddb";
	undef;
    }

=head1 SEE ALSO

L<CDDB::File>.

=head1 AUTHOR

Johan Vromans <jvromans@squirrel.nl>

=head1 COPYRIGHT

This programs is Copyright 2003, Squirrel Consultancy.

This program is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

=cut

1;


# CDDB::Fake.pm -- CDDB File Faker
# RCS Info        : $Id: CDDB-Fake.pm,v 1.2 2003/07/26 15:52:26 jv Exp $
# Author          : Johan Vromans
# Created On      : Tue Mar 25 22:38:32 2003
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jul 26 17:58:24 2003
# Update Count    : 37
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

The titles may be optionally followed by trailing TABs and a MM:SS
time indicator.

A tool is included to generate a fake file from the names of the files
in the directory.

B<WARNING:> CDDB::Fake implements only a part of the CDDB::File API.

=cut

package CDDB::Fake;

$VERSION = "1.00";

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
	open($fh, $file) or Carp::croak("$file: $!\n");
    }
    while ( <$fh> ) {
	next unless /\S/;
	s/[\r\n]+$//;
	if ( /^\s+(\d+)\.?\s+(.*)/ ) {
	    push(@{$self->{_tracks}}, CDDB::Fake::Track->new(0+$1, $2));
	    next;
	}
	if ( /^\s*(.+)\s+\/\s+(.*)/ && !$self->{_artist} ) {
	    $self->{_artist} = $1;
	    $self->{_title} = $2;
	    next;
	}
	if ( $self->{_artist} && $self->{_tracks} ) {
	    $self->{_extd} = join("\n", $_, <$fh>);
	    last;
	}
    }

    bless $self, $pkg;
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

In list context: returns a list of track objects.
In scalar context: returns a reference to this list.

=cut

sub tracks {
    my ($self) = @_;
    wantarray ? @{$self->{_tracks}} : $self->{_tracks};
}

=item id

Returns the (fake) id for this disc.

=cut

sub id {
    "00000000";
}

=item year

=item genre

=item length

These methods return undef since the information is not available in
CDDB::Fake files.

=cut

sub year   { undef }
sub genre  { undef }
sub length { undef }

=item extd

Returns the extended disc information, that is everything that follows
the list of tracks n the fake file.

=cut

sub extd  {
    my ($self) = @_;
    $self->{_extd};
}

=back

=cut

package CDDB::Fake::Track;

sub new {
    my ($pkg, $num, $tt, $len) = @_;
    if ( $tt =~ /^(.*?)\t+ ?(\d+):(\d\d)\s*$/ ) {
	$tt = $1;
	$len = 60 * $2 + $3;
    }
    bless [ $num, $tt, $len ], $pkg;
}

=pod

Track objects provide the following methods:

=over 4

=item number

The track number.

=cut

sub number { shift->[0] }

=item title

The track title.

=cut

sub title  { shift->[1] }

=item length

The track length (in seconds).

=cut

sub length { shift->[2] }

=head1 EXAMPLES

It is often handy to generalize the handling of real and fake files:

    use CDDB::File;	# the real one
    use CDDB::Fake;	# the fake one
    use Carp;

    # Return a CDDB::File object if a .cddb file is present, otherwise
    # return a CDDB::Fake onkect from a .nocddb file, if present.

    sub cddb_info($) {
	my $df = shift;
	Carp::croak("cddb_info(dir)\n") unless -d $df;
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


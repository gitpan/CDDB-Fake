use strict;
use Test::More tests => 14;
BEGIN { use_ok('CDDB::Fake') };

my $data;
eval {
     $data = CDDB::Fake->new(\*DATA);
};
ok($data, "load");
is($data->title, "Dick's Jazz Stuff", "title");
is($data->artist, "Dick Onstenk", "artist");
is($data->track_count, 6, "count");
is($data->length, 1788, "length");
ok($data->extd =~ /^Generated by/, "extd");

my $track = ($data->tracks)[1];
is($track->number, 2, "number1");
is($track->title, "Fly Me To The Moon", "title1");
is($track->length, 260, "length1");

$track = ($data->tracks)[5];
is($track->number, 6, "number5");
is($track->title, "Softly As In A Morning Sunrise", "title5");
is($track->length, 372, "length5");
is($track->offset, 106350, "offset5");

__DATA__
Dick Onstenk / Dick's Jazz Stuff

     1. Body And Soul			 3:17
     2. Fly Me To The Moon		 4:20
     3. Lover Man			 6:16
     4. Freddie Freeloader		 5:32
     5. Billie's Bounce			 4:11
     6. Softly As In A Morning Sunrise	 6:12

Generated by ls2nocddb 1.4* on Fri Jul 25 14:31:41 200
     7. Try to distract
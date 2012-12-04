#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-
use strict;
use Cv;
use File::Basename;

my $USE_ALPHA_CHANNEL = 1;
my $THRESHOLD_VALUE = 140;
# for noVaj.png EDGE Detection is not needed if we use alpha channel
my $EDGE_DETECT = 0;

my $CV_LOAD_IMAGE_ALL_CHANNELS = -1; 

my $filename = $ARGV[0] || "noVaj.png";
my $src = Cv->LoadImage($filename, 
		($USE_ALPHA_CHANNEL)?($CV_LOAD_IMAGE_ALL_CHANNELS):CV_LOAD_IMAGE_COLOR)
    or die "$0: can't loadimage $filename\n";
Cv->NamedWindow("Source", 1);
$src->ShowImage("Source");

my $dst2 = $src->new($src->sizes, CV_8UC1);
my $dst1 = $src->new($src->sizes, CV_8UC1);
my $dst = $src->new($src->sizes, CV_8UC1);
my $color_dst = $src->new($src->sizes, CV_8UC3);
my $storage = Cv::MemStorage->new;
use Data::Dumper;

if ($USE_ALPHA_CHANNEL) {
	my @channels = $src->split;
	warn scalar(@channels);
	# IFF we have an alpha channel go ahead and use it, otherwise
	# we are here in error
	if (@channels == 4) {
		# take solely the alpha channel
		$dst1 = $channels[3];
	} else {
		$USE_ALPHA_CHANNEL = 0; # disable it
		$EDGE_DETECT = 1; #enable edge detection
	}
} 
# ok this is a little complicated. If the image is grayscale (like a grayscale.png) then 
# don't convert it to grayscale
# but only do this if USE_ALPHA_CHANNEL is false.. which it could be if we didn't have
# enough channels
if (!$USE_ALPHA_CHANNEL) {
	if ($src->nChannels == 3) {
		$src->CvtColor(CV_BGR2GRAY, $dst1);
	} else {
		$dst1 = $src;
	}
}
Cv->NamedWindow("DST1", 1);
$dst->ShowImage("DST1");


$dst1->Threshold($dst2,$THRESHOLD_VALUE,255,0);
# edge detect
#$src->Canny(50, 200, 3, $dst);
if ($EDGE_DETECT) {
	warn "Edge Detecting";
	$dst2->Canny(50, 200, 3, $dst);
} else {
	$dst = $dst2;
}
Cv->NamedWindow("DST2", 1);
$dst->ShowImage("DST2");
# gray 2 RGB
$dst->CvtColor(CV_GRAY2BGR, $color_dst);

my $lines = $dst->HoughLines2( $storage, CV_HOUGH_PROBABILISTIC, 1, &CV_PI / 180, 
	10, # threshold (sensitivity)
	10, #minLineLength
	10,); #maxLineGap
for (my $i = 0; $i < $lines->total; $i++) {
	my ($x1, $y1, $x2, $y2) = unpack("i4", $lines->GetSeqElem($i));
	$color_dst->Line(
		[$x1, $y1], [$x2, $y2], CV_RGB(255, 0, 0), 3, CV_AA, 0,
	);
	# print the line segments
	print join("\t", $x1, $y1, $x2, $y2,$/);
}

Cv->NamedWindow("Source", 1);
$src->ShowImage("Source");
Cv->NamedWindow("Hough", 1);
$color_dst->ShowImage("Hough");
Cv->WaitKey;
# save the images
$color_dst->SaveImage("hough.png");
$dst->SaveImage("hough-gray.png");

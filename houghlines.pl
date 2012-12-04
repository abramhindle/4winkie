#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4; -*-
use strict;
use Cv;
use File::Basename;
use List::Util qw(min);

my $filename = "noVaj.png";
my $src = Cv->LoadImage($filename, 0)
    or die "$0: can't loadimage $filename\n";

my $dst = $src->new($src->sizes, CV_8UC1);
my $color_dst = $src->new($src->sizes, CV_8UC3);
my $storage = Cv::MemStorage->new;

# edge detect
$src->Canny(50, 200, 3, $dst);
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
}

Cv->NamedWindow("Source", 1);
$src->ShowImage("Source");
Cv->NamedWindow("Hough", 1);
$color_dst->ShowImage("Hough");
Cv->WaitKey;

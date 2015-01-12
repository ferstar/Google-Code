<?php
# ++++++++++++++++++++
# Stephen Repetski
# RIT Research Computing
# This file is the main display for the OSMF Flash player that will be shown to
#  clients in order to serve up videos and various other streams.
# ++++++++++++++++++++

	require_once('inc/config.php');
	require_once('inc/footer.php');

	# Set a few variables here that will be used for x/y dimensions of the video player
	$_x = array("min" => "320", "default" => "720", "max" => "1920");
	$_y = array("min" => "240", "default" => "480", "max" => "1080");

	# Pull variables from the input URL
	$x =				intval($_GET["x"]); 
	$y = 				intval($_GET["y"]);
	$app =			$_GET["app"];
	$hint = 		$_GET["hint"];
	$video =		$_GET["video"];

	#Default protocol to use
	$defprot = "rtmp";

	# Use some basic logic in order to determine the application if it happens not
	# to be sent in from the main logic page. This should only be used in case of
	# last resort, as it is not very fine-grained
	if (isset($app) != TRUE) {
		$sdp = '/sdp$/';
		$stream = '/stream$/';
		$smil = '/\.smil/';
		# Check to see what kind of video that we will be playing and modify the app and/or hint to match
		if (preg_match($sdp,$video) == TRUE || preg_match($stream,$video) == TRUE) { 
			$app = "live"; 
		} elseif (preg_match($smil,$video) == TRUE) { 
			$hint = "smil"; $defprot = $prot["http"];
		} else { $app = "vod"; $hint = "mp4"; }	
	}
	
	# If either $x or $y is less than the minimum accepted size, set it to the default
	if ($x < $_x["min"]) { $x = $_x["default"]; } elseif ($x > $_x["max"]) { $x = $_x["max"]; }
	if ($y < $_y["min"]) { $y = $_y["default"]; } elseif ($y > $_y["max"]) { $y = $_y["max"]; }

	# Check to see what type of item we're being passed.
	# If $app is 'vod', then we are receiving a video on demand
	# If $app is 'live' *and* $hint is 'smil', then this is a live multibitrate
	#   stream, and $url should be rewritten accordingly.
	# If neither of the two previous ifs were met, then we are apparently dealing
	#   with a simple live stream
	#
	# Example URL of a live multibitrate stream
	# http://brooklyn.rc.rit.edu:1935/live/_definst_/live/cleanroom-live.smil/manifest.f4m
	if ($hint == "ngrp") {
		$defprot = "http";
    $url = "$streamserver:$vidport/$app/$definst/$hint:${video}_all/manifest.f4m";
	} elseif ($hint == "smil") {
		$defprot = "http";
		# http://firehose.rc.rit.edu:1935/vod/_definst_/smil:vod/RIT-VintCerf-vod.smil/manifest.f4m
		$url = "$server:$vidport/$app/$definst/$hint:$video/manifest.f4m";
	} elseif ($app == "vod") {
		$url = "$server:$vidport/$app/$definst/$hint:$video";
		#		$url = "$streamserver:$port/$app/$definst/ngrp:${video}_all/manifest.f6m";
		# If none of the previous ifs match, then it should (hopefully) be safe to 
		# assume that the incoming multimedia stream is just a plain video, and we
		# can handle this fairly simply.
	} else { 
		$url = "$streamserver:$vidport/$app/$video";
	}
echo "<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' 'http://www.w3.org/TR/html4/loose.dtd'>
<html>
<head>\n\t<title>$video</title>
\t<link rel='stylesheet' type='text/css' href='http://$server/css/style.css' media='screen'></head>
<body id='video'>\n
<a href='.'>Home</a> | <b>$video</b><br />
<object width='$x' height='$y'>
	<param name='movie' value='$videoPlayer'></param>
	<param name='flashvars' value='src=$defprot://$url'></param>
	<param name='allowFullScreen' value='true'></param>
	<param name='allowscriptaccess' value='always'></param>

	<object width='$x' height='$y'>
		<param name='movie' value='$videoPlayer'></param>
		<param name='flashvars' value='src=$defprot://$url&playButtonOverlay=false&autoPlay=true'></param>
		<param name='allowFullScreen' value='true'></param>
		<param name='allowscriptaccess' value='always'></param>
		<embed src='$videoPlayer' type='application/x-shockwave-flash' allowscriptaccess='always' 
		allowfullscreen='true' width='$x' height='$y' flashvars='src=$defprot://$url&playButtonOverlay=false
		&autoPlay=true'></embed>
	</object>
</object>\n";
	footer();
echo "</body>\n";
echo "</html>";

?>

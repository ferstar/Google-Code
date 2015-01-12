<?php

require_once('config.php');

# Define sizes for the videos that we'd like to use. These arguments
# get passed through to the video display page and allow for different sizes
# based on the content.
$_1080  = "x=1920&amp;y=1080";
$_720   = "x=1280&amp;y=720";
$_480   = "x=720&amp;y=480";

# Recurse through the streams array
function eval_streams($streams, $directory, $os, $vidsrv) {
	echo "\n<table>\n";
	global $_480, $_720, $_1080;
	global $vidport, $streamserver, $definst;
	$app = "live";

	foreach ($streams as $value) {
		$hint = 'live';
		list ($mbrName, $mbrApp) = getName_mbrLive($value);
		# Check first to see if the file ends in .stream
		if (preg_match('/\.stream$/',$value)) {
			$video = substr($value,strlen($directory)+1);
			$full = explode("/",$value);
				$name = $full[count($full)-1];
			if ($os == "ios") {
				echo "\t<tr><td><a href='http://$streamserver:$vidport/$app/$video/playlist.m3u8'>$name</a></td>\n";
        echo "\t<td><a href='http://$streamserver:$vidport/$mbrApp/$definst/ngrp:${video}_all/playlist.m3u8'>var-ios</a></td></tr>\n";
			} elseif ($os == "mobile") {
				echo "\t<tr><td><a href='rtsp://$streamserver:$vidport/$app/$video'>$name</a></td></tr>\n";
			} else {
				echo "\t<tr><td>$name</td><td><a href='video.php?$_480&amp;app=$app&amp;video=$video'>(small)</a></td><br />\n";
				echo "\t<td><a href='video.php?$_720]&amp;app=$app&amp;video=$video'>(medium)</a></td>\n";
				echo "\t<td><a href='video.php?$_1080&amp;app=$app&amp;video=$video'>(large)</a></td>\n";
				#$hint = 'ngrp';
				#echo "\t<td><a href='video.php?app=$mbrApp&amp;hint=$hint&amp;video=$video'>(variable)</a></td>\n";
				echo "</tr>\n";
			}

		# If not ending in .stream, we can (safely?) assume that the file ends in .sdp.
		# This is the common file format for most of the live video streams to date.			
		} else {
			$video = substr($value,strlen($directory)+1);
			#Massage the filename so it looks happy
			$cmd = "awk 'NR == 2' $value";
			$exec = exec($cmd);
			$start = strstr($exec,"IP4 ");
			$end = substr($start,3);
	
			if ($os == "ios") {
				echo "\t<tr><td><a href='http://$streamserver:$vidport/$app/$video/playlist.m3u8'>$end</a></td>\n";
        echo "\t<td><a href='http://$streamserver:$vidport/$mbrApp/$definst/ngrp:${video}_all/playlist.m3u8'>variable-ios</a></td></tr>\n";
			} elseif ($os == "mobile") {
				echo "\t<tr><td><a href='rtsp://$streamserver:$vidport/$app/$video'>$end</a></td></tr>\n";
			} else {
				echo "\t<tr><td>$end</td>";
				echo "\t<td><a href='video.php?$_480&amp;app=$app&amp;video=$video'>(small)</a></td>\n";
				echo "\t<td><a href='video.php?$_720]&amp;app=$app&amp;video=$video'>(medium)</a></td>\n";
				echo "\t<td><a href='video.php?$_1080&amp;app=$app&amp;video=$video'>(large)</a></td>\n";
			#	$hint = 'ngrp';
			#	echo "\t<td><a href='video.php?app=$mbrApp&amp;hint=$hint&amp;video=$video'>(variable)</a></td>\n";
				echo "</tr>\n";
			}
		}
	}
	echo "</table>";
}

# ++++++++++++++++++++
# eval_videos
# Recurse through the array of video files and display them
# Use browser agent detection in order to display items differently for desktop vs mobile clients
# ++++++++++++++++++++
function eval_videos($videos, $directory, $os, $vidsrv) {
	global $vidport, $definst;
	$ffprobe="/usr/bin/ffprobe";
	$app = "vod";
	
	echo "<table border='0'>\n";
	# Loop through the array and iterate over each element
	foreach ($videos as $value) {
		# Take the full path to the video and separate it up on slashes
		# The last element of the array will end up being the filename, which we can
		# separate into the actual name as well as the type of file - the "hint"
		$fullpath = explode('/',$value);
		$file = explode(".",end($fullpath));
		$name = $file[0];
		$hint = $file[1];

		# Take a substring from the full path of the video name; everything past
		# the base path is what we want. This is used to pass to Wowza so that it can
		# cue up the video that we want to watch, relative to the Wowza content dir.
		$video = substr($value,strlen($directory)+1);

		# If the height and width are not picked up via ffprobe earlier, attempt to
		# see if the filename is something that we can use. If it is split up into 
		# three parts, we can pull off the last two bits and use them as width
		# and height
		$filename = explode("_",$name);
		if (count($filename) == 3) {
			# Set variables for ease of use; self-explanatory
			$name  = $filename[0];
			$width = $filename[1];
			$height = $filename[2];
		} else {
	    # Use ffprobe to get the width and height of the video
	    $width  = `$ffprobe -show_streams '$value' 2>/dev/null|grep width |cut -d'=' -f2`;
	    $height = `$ffprobe -show_streams '$value' 2>/dev/null|grep height|cut -d'=' -f2`;
		}

		// Display the codec profile and dimensions next to the filename
		$total = `$ffprobe $value 2>&1 |grep -e 'Video\:.*)'|cut -d: -f3|cut -d[ -f1|cut -d, -f1,3|sed -e 's/^[ \t]//;s/[ \t]$//'`;
		$time = `$ffprobe -show_streams '$value' 2>/dev/null|grep -i duration|head -n1|cut -d'=' -f2`;
		$duration = sec2hms($time);

		if (!isset($width) || !isset($height)) {
			$width = "720"; $height = "480";
		}
		if (!isset($total)) {
			$total = "${width} x ${height}";
		}

		if ($os == "ios") {
			echo "  <tr><td><a href='http://$vidsrv:$vidport/$app/_definst_/$video/playlist.m3u8'>$name</a>";
			echo "	($total)</td></tr>\n";
	  } elseif ($os == "mobile") {
		  echo "  <tr><td><a href='rtsp://$vidsrv:$vidport/$app/_definst_/$hint:$video'>$name</a>";
			echo "	($total)</td></tr>\n";
		} else {
			echo "  <tr><td><a href='video.php?app=$app&amp;x=$width&amp;y=$height&amp;hint=$hint&amp;video=$video'>$name ($duration)</a>";
			echo "	($total)</td>\n";
			echo "  <td><a href='rtsp://$vidsrv:$vidport/$app/_definst_/$hint:$video'>(mobile)</a></td>\n";
#		echo "  <td><a href='http://$vidsrv:$vidport/$app/_definst_/$video/playlist.m3u8'>(ios)</a></td></tr>\n";
		}
	} # End of iteration loop
	echo "</table>";
}

# Recurse through .smil files - multi-bitrate streams or videos
#++++++++++++++++++++
# eval_mbr
# Recurse through .smil files in the array and display them properly.
# These files contain multiple copies of the same file, but with different
# bitrates and other features that make the files larger or smaller in order
# to better fit peoples' bandwidth limitations.
#++++++++++++++++++++
function eval_mbr($videos, $directory, $os, $vidsrv) {
	$app = "smil";
	$hint = "smil";
	echo "<table>\n";
	global $streamserver, $vidport, $definst;

	# Loop through the array and iterate over each element
	foreach ($videos as $value) {
		$video = substr($value,strlen($directory)+1);

		# Entire path of the video
		# Example: /var/www/html/content/vod/video.mp4
		#$fullpath = explode('/',$value);
		$fullpath = explode('/',$video);
		$app = $fullpath[0];

		# Take the last section of the path and use it to determine filename
		$file = explode(".",end($fullpath));
		# Set the common name to display on the website
		$name  = $file[0];
	
#		$app2  = strrpos($name,"-");
#		# Name of the video file, minus the bits that we don't want
#		$name2 = substr($name,0,$app2);
#		# Application name to be sent through to video.php
#		$app3  = substr($name,($app2+1));
	
		if ($os == "ios") {
			echo "<tr><td><a href='http://$streamserver:$vidport/$app/$definst/ngrp:${video}_all/playlist.m3u8'>$name</a></td></tr>\n";
		} else {
			echo "<tr><td><a href='video.php?app=$app&amp;hint=$hint&amp;video=$video'>$name</a></td></tr>\n";
		}
	}
	echo "</table>";
}

?>

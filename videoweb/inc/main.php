<?php
# ++++++++++++++++++++
# Author: Stephen Repetski
# For: RIT Research Computing
# Purpose: This is the main display file that is used in order to trigger the functions
# within. This PHP script is used in order to display a listing of video streams as well as 
# on-demand videos, which are populated from a folder specified.
# ++++++++++++++++++++

function main() {
	global $server, $directory;

	$m = $_GET["m"];
	
	# Start defining the HTML document that will be displayed to the client. These lines are
	# needed for the HTML to properly render in the client.
	echo "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' \n
		\t'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>";
	echo "<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en'>\n";
	echo "<head><title>Research Computing: Live Streams and Recorded Content</title>\n";
	echo "<link rel='stylesheet' type='text/css' href='http://$server/css/style.css' media='screen' />\n
		</head>\n\n";
	echo "<body id='index'>\n";
	echo "<p><img src='http://rc.rit.edu/media/topbanner.jpg' alt='RIT Research Computing' /></p>\n";

	# Pull in an array of all the files that exist in the specified content directory
	$file = getFilesFromDir($directory);

	# Sort all the files to remove them from a per-folder sort to an overall sort
	natcasesort($file);
	
	# Simple .sdp files for individual streams
	$streams = array();
	# Individual videos
	$videos = array();
	# Multi-bitrate videos
	$mbr = array();
	# Multi-bitrate streams
	$live = array();

	if ($m == "mobile") { $mybrowser = "mobile"; }
	elseif ($m == "ios") { $mybrowser = "ios"; }
	elseif ($m == "default") { $mybrowser = "default"; }
	else {
		$mobile = mobile_device_detect(true,true,true,false,false,false,false,false,false);

		# Operating system agent detection. Use the get_browser function, along with
		# the mobile_device_detect function in order to determine if the client 
		# connecting to the site is on a mobile platform or not. With this information
		# we can set the $mybrowser variable, which will be sent to functions to inform
		# them of the clients' status so we can shape the page like we want.
		# The following line can be used for debugging.
		#print_r(get_browser(null, true));
		$browser = get_browser(null, true);
		if ($browser["platform"] == "iPhone OSX") {
			echo "\nFormatted to work better on Apple iOS devices";
			$mybrowser = "ios";
		} elseif ($browser["platform"] != "iPhone OSX" && $mobile[1] != "") {
			echo "Formatted to work better on mobile devices";
			$mybrowser = "mobile";
		} else {
			$mybrowser = "default";
		}
	}

	# Patterns to match by
	$sdp = '/\.sdp$/'; 
	$stream = '/\.stream$/';
	$mp4 = '/\.mp4$/';
	$smil = '/\.smil$/';
	
	# For each of the patterns that we search by, check to see if it matches the filename
	# If it does, push it onto the proper array of names which we'll be able to use later
	foreach ($file as $value) {
		# Check for .sdp files
		if (preg_match($sdp,$value) == TRUE) {
			array_push($streams, $value);
			array_push($live, $value);
		# Check for .stream files
		} elseif (preg_match($stream,$value) == TRUE) {
			array_push($streams, $value);
		# Check for .mp4 files (the only currently-supported video format
		} elseif (preg_match($mp4,$value) == TRUE) {
			array_push($videos, $value);
		# Check for .smil files (future advancement)
		} elseif (preg_match($smil,$value) == TRUE) {
			array_push($mbr, $value);
		}
	}

	# 
	# Display portion of index.php
	# This portion is used in order to display the streams, videos, and multibitrate
	# files that we are dealing with
	#
	# Display some introductory information about the streams
	echo "<h3>Streams</h3>\n";
	echo "<p>These streams consist of rebroadcasted live video that appears across campus\n";
	echo "\tat our various public nodes. Some of the videos may potentially come from off\n";
	echo "\tcampus at one of our many satellite locations as well. More are slated to be";
	echo "\tadded here in the future.</p>";

	eval_streams($streams, $directory, $mybrowser, $server);

	# Display some introductory information about the multi-bitrate streams
	echo "\n\n<h3>Multi-bitrate Video on Demand</h3>\n";
	echo "<p>In addition to the streams above, these streams (in testing) are ones that switch between bitrates according\n";
	echo "\tto what your network connection has been detected as. These should provide a more seamless user experience and make\n";
	echo "\twatching some of these videos more enjoyable.</p>";

	eval_mbr($mbr, $directory, $mybrowser, $server);

	# Display some introductory information about the videos
	echo "\n\n<h3>Video On Demand</h3>\n";
	echo "<p>These are various recorded videos that have been made public here for general consumption.</p>\n";

	eval_videos($videos, $directory, $mybrowser, $server);

	#	echo "\n\n<h3>Multi-bitrate Live Streams</h3>\n";
	#	eval_live($live, $directory, $mybrowser, $server);

	# Output some debugging information to better help us code the site
	# echo $_SERVER['HTTP_USER_AGENT']."\n";
	# echo php_uname('s');
	footer();
	echo "</body>\n";
	echo "</html>";
}

?>

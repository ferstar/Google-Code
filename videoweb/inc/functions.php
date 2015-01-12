<?php
# ++++++++++++++++++++
# Stephen Repetski
# RIT Research Computing
# Functions here are used for various parts of the media application. These
#  particular functions are those that are not directly shown or interact with
#  the client. They may be passed to other functions that then are displayed to 
#  the clients' screen, but not these.
# ++++++++++++++++++++

# ++++++++++++++++++++
# getFilesFromDir
#
# Recurse through all subfolders and put everything into a happy array
# Appears not to work for folders with capitalization in them?
# Returns an array with all of the files within the specified $dir
# ++++++++++++++++++++
function getFilesFromDir($dir) {
	$files = array();
	if ($handle = opendir($dir)) {
		while (false !== ($file = readdir($handle))) {
			if ($file != "." && $file != ".." && ! preg_match('/HIDE/',$file)) {
				# If the item is a directory, then recurse into it and find the files within it
				if(is_dir($dir . '/' . $file)) {
					$dir2 = $dir . '/' . $file;
					$files[] = getFilesFromDir($dir2);
				}
				# If the item is a file, add the full path as an element in the array
				else {
					$files[] = $dir . '/' . $file;
				}
			}
		}
		closedir($handle);
	}
	return array_flat($files);
}

# ++++++++++++++++++++
# array_flat
#
# Used in order to flatten arrays inside an array; used in conjunction
# with the previous function so that a single flat array is returned,
# instead of one with sub-arrays
# ++++++++++++++++++++
function array_flat($array) {
	foreach($array as $a) {
		if(is_array($a)) {
			@$tmp = array_merge($tmp, array_flat($a));
		}
		else {
			$tmp[] = $a;
		}
	}
	return @$tmp;
}

function getName_mbrLive($value) {
	global $directory;

	# Entire path of the video
	# Example: /var/www/html/content/vod/video.mp4
	$fullpath = explode('/',$value);
	# Take the last section of the path and use it to determine filename
	$file = explode(".",end($fullpath));
	# Set the common name to display on the website
	$name = $file[0];
	
	$fileonly = substr($value, strlen($directory));
	$app = explode('/',$fileonly);
	$app2 = $app[1];

	return array ($name, $app2);

}

# FFmpeg outputs video duration as a number of seconds, which really isn't
# all that useful. In order to turn this into something more user readable,
# we have this sec2hms function taking the seconds and turning that into
# hours, minutes, and seconds. The code below was found online, and all
# original comments of the code remain.
#
# If requested, the code includes this $padHours item, which will add a 0
# to the left of the numbers if requested, potentially fixing any alignment
# issue should one arise.
function sec2hms ($sec, $padHours = false) 
{
	// start with a blank string
	$hms = "";
    
	// do the hours first: there are 3600 seconds in an hour, so if we divide
	// the total number of seconds by 3600 and throw away the remainder, we're
	// left with the number of hours in those seconds
	$hours = intval(intval($sec) / 3600); 

	// add hours to $hms (with a leading 0 if asked for)
	$hms .= ($padHours) 
		? str_pad($hours, 2, "0", STR_PAD_LEFT). ":"
		: $hours. ":";
    
	// dividing the total seconds by 60 will give us the number of minutes
	// in total, but we're interested in *minutes past the hour* and to get
	// this, we have to divide by 60 again and then use the remainder
	$minutes = intval(($sec / 60) % 60); 

	// add minutes to $hms (with a leading 0 if needed)
	$hms .= str_pad($minutes, 2, "0", STR_PAD_LEFT). ":";

	// seconds past the minute are found by dividing the total number of seconds
	// by 60 and using the remainder
	$seconds = intval($sec % 60); 

	// add seconds to $hms (with a leading 0 if needed)
	$hms .= str_pad($seconds, 2, "0", STR_PAD_LEFT);

	// done!
	return $hms;
    
}

?>

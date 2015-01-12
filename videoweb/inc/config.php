<?php
# ++++++++++++++++++++
# Common Variables
# ++++++++++++++++++++
	$vidport = "1935";

	$definst = "_definst_";

# ++++++++++++++++++++
# index.php
# ++++++++++++++++++++
	# Define the hostname of the Wowza server that the streams will be coming from.
	# This is also used in order to know where the CSS and other various files come from
	$server = "firehose.rc.rit.edu";

	# Define the directory to look for content in, and get an array of all the files in the 
	# said directory. Everything in this directory $$$**MUST***$$$ be in the same relative location
	# as far as the Wowza server is concerned, otherwise nothing will work. This folder, however,
	# can simply be a symlink to the Wowza content directory, which should solve this problem if it
	# ever happens to come up.
	$directory='/var/www/html/content';

	# Allow for administrators to define a separate server for streams, if there is
	# another that potentially has different licensing or other items that we might
	# want for usefulness.
	$streamserver = "firehose.rc.rit.edu";

# ++++++++++++++++++++
# video.php
# ++++++++++++++++++++
	# HTTP Server
	$videoPlayer =	"http://$server/swf/StrobeMediaPlayback.swf";
?>

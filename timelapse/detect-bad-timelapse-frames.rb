#detect-bad-timelapse-frames.rb runs multiple algorithms across frames in a timelapse
#to remove frames that are deemed bad (Flickering of an image, completely greyed 
#out images,Images that did not completely render, etc...)
#@authors: David Villareal, Justin Peterson, TJ Boyle
#@Date: 06/18/13

require 'rubygems'
require 'chunky_png'
require 'miro'
require 'ruby-progressbar'

#Determines if a frame is less than 1MB in size
#If so returns true
def is_frame_too_small? (temp_string, pngimage)
	
	#file size of the .png file (in kb)	
	file_size = File.size(temp_string) / 2**10
		
	# if the file is < 1 MB, and is a .png file	
	if file_size < 1000 
	    return true

	end
	return false

end

#Checks for a bad frame by taking the RGB average of an 80X80 px sample
#of an image
def is_frame_too_grey?(string, pngimage, temp_directory)

    #Creates a ChunkyPNG image from the current image
    #crops the image to contain just the top right 80x80 pixels, and saves it
    image = ChunkyPNG::Image.from_file(string)
    cimage =image.crop(1840, 0, 80, 80)
    cimage.save("#{temp_directory}/#{pngimage}")

    #Creates a new colors object from the cropped image
    colors = Miro::DominantColors.new("#{temp_directory}/#{pngimage}")

    rgbs = colors.to_rgb

    #If the blue value of the sampled image is between 110 and 155,
	#copy it (while retaining directory structure) over to another folder
	if (rgbs[0][0] > 110 && rgbs[0][0] < 155) && (rgbs[0][1] > 110 && rgbs[0][1] < 155) && (rgbs[0][2] > 110 && rgbs[0][2] < 155)
        return true
    end

    return false

end

#Moves the bad images to a temp directory for later use
#(If we decide to improve the image searchign algorithm.)
def move_bad_image(temp_string, destination_directory)

	#Generate a destination directory
	temp_array = temp_string.split("/")
	destination_directory = destination_directory + temp_array[4] 
			
	#if this directory doesn't yet exist, make it
	if !(FileTest::directory?(destination_directory))
		Dir::mkdir(destination_directory)
	end
			
	#move bad timelapse images to new directory
	`sudo mv #{temp_string} #{destination_directory} `

end

#Main body of script.
#Go through every .png file in a timelapse directory,
#and move files to a seperate folder if they are deemed "bad."
def detect_bad_timelapse_frames 
	
	#initalize bad frame counter
	bad_frames = 0

	main_directory = ARGV[0] #timelapse root
	destination_directory = ARGV[1] #Destnation of bad frames
	temp_directory = ARGV[2] #Destination of temp thumbnails

	pngarray = Dir.glob("#{main_directory}**/*.png") # for all .png files
	
	#Track progress of frame checking
	status_bar = ProgressBar.create(:format => '%a |%b>>%i| %p%% %t', :total => pngarray.length)

	#iterate over each .png image with a string form of the images absolute path
	pngarray.each do |temp_string|
		status_bar.increment

		#name of a .png timelapse image
		string_array = temp_string.split("/")
		pngimage = string_array[string_array.length - 1]

		#if our checks detect a bad frame, move it
		if (is_frame_too_small? temp_string, pngimage) || (is_frame_too_grey? temp_string, pngimage, temp_directory)
			move_bad_image temp_string, destination_directory
			bad_frames += 1
		end
		
	end

	puts "------------------------------------------"
	puts " found " + bad_frames.to_s + " bad frames."
	puts "------------------------------------------"
end

detect_bad_timelapse_frames


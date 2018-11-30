
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

AIR_POINTS_LISTING_FOLDERPATH = "/Galaxy/DataBank/Catalyst/AirPoints"

class NSXAirPointsUtils

	# NSXAirPointsUtils::timeStringL22()
	def self.timeStringL22()
	    "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
	end

	# --------------------------------------------------------
	# Basic IO

	# NSXAirPointsUtils::getAirPointsFilepaths()
	def self.getAirPointsFilepaths()
		Dir.entries(AIR_POINTS_LISTING_FOLDERPATH)
			.select{|filename| filename[-5, 5]==".json" }
			.map{|filename| "#{AIR_POINTS_LISTING_FOLDERPATH}/#{filename}" }
	end

	# NSXAirPointsUtils::getAirPoints()
	def self.getAirPoints()
		NSXAirPointsUtils::getAirPointsFilepaths()
			.map{|filepath| JSON.parse(IO.read(filepath)) }
			.sort{|ap1, ap2| ap1["creation-unixtime"]<=>ap2["creation-unixtime"] }
	end

	# NSXAirPointsUtils::commitAirPointToDisk(airPoint)
	def self.commitAirPointToDisk(airPoint)
		filename = airPoint["filename"]
		filepath = "#{AIR_POINTS_LISTING_FOLDERPATH}/#{filename}"
		File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(airPoint)) }
	end

	# NSXAirPointsUtils::destroyAirPoint(airPoint)
	def self.destroyAirPoint(airPoint)
		filename = airPoint["filename"]
		filepath = "#{AIR_POINTS_LISTING_FOLDERPATH}/#{filename}"
		return if !File.exists?(filepath)
		FileUtils.rm(filepath)
	end

	# --------------------------------------------------------
	# Data

	# NSXAirPointsUtils::makeAirPoint(atlasReference, description)
	def self.makeAirPoint(atlasReference, description)
		{
			"uuid"              => SecureRandom.hex,
			"atlas-reference"   => atlasReference,
			"description"       => description,
			"creation-unixtime" => Time.new.to_i,
			"filename"          => "#{NSXAirPointsUtils::timeStringL22()}.json"
		}
	end

	# ------------------------------------------------------------------------------
	# User Interface

	# NSXAirPointsUtils::airPointToString(airPoint)
	def self.airPointToString(airPoint)
		"air point: #{airPoint["description"]} (atlas reference: #{airPoint["atlas-reference"]})"
	end

	# NSXAirPointsUtils::selectAirPointOrNull()
	def self.selectAirPointOrNull()
		airPoint = LucilleCore::selectEntityFromListOfEntitiesOrNull("air point:", NSXAirPointsUtils::getAirPoints(), lambda{ |airPoint| airPoint["description"] })
		airPoint
	end

	# NSXAirPointsUtils::airPointDive(airPoint)
	def self.airPointDive(airPoint)
		puts NSXAirPointsUtils::airPointToString(airPoint)
		command = LucilleCore::selectEntityFromListOfEntitiesOrNull("command:", ["open folder", "destroy"])
		return if command.nil?
		if command == "open folder" then
			atlasReference = airPoint["atlas-reference"]
			folderpath = `atlas locate #{atlasReference}`.strip
			if File.exists?(folderpath) then
				system("open '#{folderpath}'")
			else
				puts "Could not find the folder path for atlas reference #{atlasReference}"
				LucilleCore::pressEnterToContinue()
			end
		end
		if command == "destroy" then
			if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this air point? ") then
				NSXAirPointsUtils::destroyAirPoint(airPoint)
			end
		end
	end

	# NSXAirPointsUtils::airPointsDive()
	def self.airPointsDive()
		airPoint = NSXAirPointsUtils::selectAirPointOrNull()
		return if airPoint.nil?
		NSXAirPointsUtils::airPointDive(airPoint)
	end

end

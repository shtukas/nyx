# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::total24hours(uuid)
    Ping::totalToday(uuid)
=end

require_relative "../OpenCycles/OpenCycles.rb"

require_relative "NSXStructureBuilder.rb"

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::performInterfaceDisplay(displayObjects)
    def self.performInterfaceDisplay(displayObjects)

        displayTime = Time.new.to_f

        system("clear")

        executors = []

        position = 0
        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

        puts ""
        puts "-> Todo items done today: #{Ping::totalToday("AEBAFC58-A70B-4623-A9C9-A00FF6BAAD0A")}".green
        puts "-> Diligence (24h): #{(100*Ping::total24hours("DC9DF253-01B5-4EF8-88B1-CA0250096471").to_f/86400).round(2)}%".green
        verticalSpaceLeft = verticalSpaceLeft - 3

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1
        NSXStructureBuilder::structure().each{|item|
            puts "[#{position.to_s.rjust(3)}] #{item["text"]}"
            executors[position] = item["lambda"]
            position = position + 1
            verticalSpaceLeft = verticalSpaceLeft - 1
        }

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        OpenCycles::getOpenCyclesClaims().each{|claim|
            dataentity = DataEntities::getDataEntityByUuidOrNull(claim["entityuuid"])
            next if dataentity.nil?
            puts ("[#{position.to_s.rjust(3)}] [opencycle] #{DataEntities::dataEntityToString(dataentity)}").yellow
            executors[position] = lambda { OpenCycles::openClaimTarget(claim) }
            verticalSpaceLeft = verticalSpaceLeft - 1
            position = position + 1
        }

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 and (calendarreport.lines.to_a.size + 2) < verticalSpaceLeft then
            puts ""
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 1 )
        end

        lucille = IO.read("/Users/pascal/Desktop/Lucille.txt").strip
        if lucille != "" then
            contents = lucille
                            .lines
                            .select{|line|  line.strip != ""}
                            .take_while{|line| line.strip != "@separator:8fc7bdc6-991e-4deb-bb4b-b1e620ba5610" }
                            .map{|line| "              #{line}" }
                            .join()
                            .rstrip
            puts ""
            puts "Lucille.txt ☀️"
            puts contents.green
            verticalSpaceLeft = verticalSpaceLeft - ( NSXDisplayUtils::verticalSize(contents) + 2 )
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        displayObjects.each_with_index{|object, indx|
            break if object.nil?
            break if verticalSpaceLeft <= 0
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, indx==0, position)
            puts displayStr
            executors[position] = lambda { NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object) }
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
            break if displayObjects[indx+1].nil?
            break if ( verticalSpaceLeft - NSXDisplayUtils::verticalSize(NSXDisplayUtils::objectDisplayStringForCatalystListing(displayObjects[indx+1], indx==0, position)) ) < 0
        }

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            if (Time.new.to_f - displayTime) < 5 then
                return NSXCatalystUI::performInterfaceDisplay(displayObjects)
            end
            return
        end

        if command[0,1] == "'" and  NSXMiscUtils::isInteger(command[1,999]) then
            position = command[1,999].to_i
            executors[position].call()
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(displayObjects[0], command)
    end

    # NSXCatalystUI::importFromLucilleInbox()
    def self.importFromLucilleInbox()
        getNextLocationAtTheInboxOrNull = lambda {
            Dir.entries("/Users/pascal/Desktop/Lucille-Inbox")
                .reject{|filename| filename[0, 1] == '.' }
                .map{|filename| "/Users/pascal/Desktop/Lucille-Inbox/#{filename}" }
                .first
        }
        while (location = getNextLocationAtTheInboxOrNull.call()) do
            if File.basename(location).include?("'") then
                basename2 = File.basename(location).gsub("'", ",")
                location2 = "#{File.dirname(location)}/#{basename2}"
                FileUtils.mv(location, location2)
                next
            end
            target = CatalystStandardTargets::locationToFileOrFolderTarget(location)
            item = {
                "uuid"         => SecureRandom.uuid,
                "creationtime" => Time.new.to_f,
                "projectname"  => "Inbox",
                "projectuuid"  => "44caf74675ceb79ba5cc13bafa102509369c2b53",
                "description"  => File.basename(location),
                "target"       => target
            }
            puts JSON.pretty_generate(item)
            filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/items2/#{item["uuid"]}.json"
            File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
            LucilleCore::removeFileSystemLocation(location)
        end
    end

    # NSXCatalystUI::standardUILoop()
    def self.standardUILoop()
        loop {
            if STARTING_CODE_HASH != NSXEstateServices::locationHashRecursively(CATALYST_CODE_FOLDERPATH) then
                puts "Code change detected. Exiting."
                return
            end
            NSXCatalystUI::importFromLucilleInbox()
            NSXCuration::curation()
            objects = NSXCatalystObjectsOperator::getCatalystListingObjectsOrdered()
            NSXCatalystUI::performInterfaceDisplay(objects)
        }
    end
end



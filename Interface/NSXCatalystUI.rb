# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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

# ------------------------------------------------------------------------

class NSXCatalystUI

    # NSXCatalystUI::performInterfaceDisplay(displayObjects)
    def self.performInterfaceDisplay(displayObjects)

        displayTime = Time.new.to_f

        system("clear")

        verticalSpaceLeft = NSXMiscUtils::screenHeight()-3

        content = IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Interface/Interface-Top.txt").strip
        if content.size > 0 then
            content = content.lines.select{|line| line.strip.size > 0 }.join().green
            puts ""
            puts content
            verticalSpaceLeft = verticalSpaceLeft - ( content.lines.to_a.size + 1 )
        end

        # displayObjectsForListing is being consumed while displayObjects should remain static
        displayObjectsForListing = displayObjects.map{|object| object.clone }
        focusobject = displayObjectsForListing.first

        calendarreport = `/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/calendar-report`.strip
        if calendarreport.size > 0 and (calendarreport.lines.to_a.size + 2) < verticalSpaceLeft then
            puts ""
            puts "🗓️"
            puts calendarreport
            verticalSpaceLeft = verticalSpaceLeft - ( calendarreport.lines.to_a.size + 2 )
        end

        puts ""
        verticalSpaceLeft = verticalSpaceLeft - 1

        position = 0
        while !displayObjectsForListing[position].nil? and ( verticalSpaceLeft > 0 or displayObjectsForListing.any?{|object| object["isRunning"] } ) do
            object = displayObjectsForListing[position-1]
            displayStr = NSXDisplayUtils::objectDisplayStringForCatalystListing(object, position == 0, position+1)
            puts displayStr
            verticalSpaceLeft = verticalSpaceLeft - NSXDisplayUtils::verticalSize(displayStr)
            position = position + 1
        end

        if displayObjects.size==0 then
            puts ""
            puts "No objects found"
            print "--> "
            command = STDIN.gets().strip
            NSXGeneralCommandHandler::processCatalystCommandManager(nil, command)
            return
        end

        # -----------------------------------------------------------------------------------

        puts ""
        print "--> "
        command = STDIN.gets().strip
        if command=='' then
            if (Time.new.to_f - displayTime) < 5 then
                return NSXCatalystUI::performInterfaceDisplay(displayObjects)
            end
            return
        end

        # -----------------------------------------------------------------------------------

        if command.start_with?("'") then
            position = command[1,9].strip.to_i
            return if position==0
            return if position > displayObjects.size
            object = displayObjects[position-1]
            NSXDisplayUtils::doPresentObjectInviteAndExecuteCommand(object)
            return
        end

        NSXGeneralCommandHandler::processCatalystCommandManager(focusobject, command)
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



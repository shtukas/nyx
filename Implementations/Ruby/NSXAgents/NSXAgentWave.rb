#!/usr/bin/ruby

# encoding: UTF-8
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'drb/drb'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "#{CATALYST_DATA_FOLDERPATH}/Wave-Data"

# ----------------------------------------------------------------------

class NSXWaveFolderProbe

    # NSXWaveFolderProbe::nonDotFilespathsAtFolder(folderpath)
    def self.nonDotFilespathsAtFolder(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1]!="." }
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    # NSXWaveFolderProbe::folderpath2metadata(folderpath)
    def self.folderpath2metadata(folderpath)

        metadata = {}

        # --------------------------------------------------------------------
        # Trying to read a description file

        getDescriptionFilepathMaybe = lambda{|folderpath|
            filepaths = NSXWaveFolderProbe::nonDotFilespathsAtFolder(folderpath)
            if filepaths.any?{|filepath| File.basename(filepath).include?("description.txt") } then
                filepaths.select{|filepath| File.basename(filepath).include?("description.txt") }.first
            else
                nil
            end
        }

        getDescriptionFromDescriptionFileMaybe = lambda{|folderpath|
            filepathOpt = getDescriptionFilepathMaybe.call(folderpath)
            if filepathOpt then
                IO.read(filepathOpt).strip
            else
                nil
            end
        }

        descriptionOpt = getDescriptionFromDescriptionFileMaybe.call(folderpath)
        if descriptionOpt then
            metadata["contents"] = descriptionOpt
            if descriptionOpt.start_with?("http") then
                metadata["target-type"] = "url"
                metadata["url"] = descriptionOpt
                return metadata
            end
        end

        # --------------------------------------------------------------------
        #

        files = NSXWaveFolderProbe::nonDotFilespathsAtFolder(folderpath)
                .select{|filepath| !File.basename(filepath).start_with?('wave') }
                .select{|filepath| !File.basename(filepath).start_with?('catalyst') }

        fileIsOpenable = lambda {|filepath|
            File.basename(filepath)[-4,4]==".txt" or
            File.basename(filepath)[-4,4]==".eml" or
            File.basename(filepath)[-4,4]==".jpg" or
            File.basename(filepath)[-4,4]==".png" or
            File.basename(filepath)[-4,4]==".gif" or
            File.basename(filepath)[-7,7]==".webloc"
        }

        openableFiles = files
                .select{|filepath| fileIsOpenable.call(filepath) }


        filesWithoutTheDescription = files
                .select{|filepath| !File.basename(filepath).include?('description.txt') }

        extractURLFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            line = contents.lines.first.strip
            line = NSXMiscUtils::simplifyURLCarryingString(line)
            return nil if !line.start_with?("http")
            line
        }

        extractLineFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            contents.lines.first.strip
        }

        if files.size==0 then
            metadata["target-type"] = "virtually-empty-wave-folder"
            if metadata["contents"].nil? then
                metadata["contents"] = folderpath
            end
            metadata["folderpath2metadata:case"] = "b6e8ac55"
            return metadata
        end

        if files.size==1 and ( url = extractURLFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "url"
            metadata["url"] = url
            if metadata["contents"].nil? then
                metadata["contents"] = url
            end
            metadata["folderpath2metadata:case"] = "95e7dd30"
            return metadata
        end

        if files.size==1 and ( line = extractLineFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "line"
            metadata["text"] = line
            if metadata["contents"].nil? then
                metadata["contents"] = line
            end
            metadata["folderpath2metadata:case"] = "a888e991"
            return metadata
        end

        if files.size==1 and openableFiles.size==1 then
            filepath = files.first
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filepath
            if metadata["contents"].nil? then
                metadata["contents"] = File.basename(filepath)
            end
            metadata["folderpath2metadata:case"] = "54b1a4b5"
            return metadata
        end

        if files.size==1 and openableFiles.size!=1 then
            filepath = files.first
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["contents"].nil? then
                metadata["contents"] = "One non-openable file in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "439bba64"
            return metadata
        end

        if files.size > 1 and filesWithoutTheDescription.size==1 and fileIsOpenable.call(filesWithoutTheDescription.first) then
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filesWithoutTheDescription.first
            if metadata["contents"].nil? then
                metadata["contents"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "29d2dc25"
            return metadata
        end

        if files.size > 1 then
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["contents"].nil? then
                metadata["contents"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "f6a683b0"
            return metadata
        end
    end

    # NSXWaveFolderProbe::openActionOnMetadata(metadata)
    def self.openActionOnMetadata(metadata)
        if metadata["target-type"]=="folder" then
            if File.exists?(metadata["target-location"]) then
                system("open '#{metadata["target-location"]}'")
            else
                puts "Error: folder #{metadata["target-location"]} doesn't exist."
                LucilleCore::pressEnterToContinue()
            end
        end
        if metadata["target-type"]=="openable-file" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="line" then

        end
        if metadata["target-type"]=="url" then
            if NSXMiscUtils::isLucille18() then
                system("open '#{metadata["url"]}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{metadata["url"]}'")
            end
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then

        end
    end
end

class NSXWaveUtils

    # NSXWaveUtils::makeScheduleObjectInteractivelyEnsureChoice()
    def self.makeScheduleObjectInteractivelyEnsureChoice()

        scheduleTypes = ['sticky', 'date', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes, lambda{|entity| entity })

        schedule = nil
        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            schedule = {
                "uuid"      => SecureRandom.hex,
                "@"         => "sticky",
                "from-hour" => fromHour
            }
        end
        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "@"    => type,
                "repeat-value" => value
            }
        end
        schedule
    end

    # NSXWaveUtils::scheduleToAnnounce(schedule)
    def self.scheduleToAnnounce(schedule)
        if schedule['@'] == 'sticky' then
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return "sticky, from: #{schedule['from-hour']}"
        end
        if schedule['@'] == 'every-n-hours' then
            return "every-n-hours  #{"%6.1f" % schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-n-days' then
            return "every-n-days   #{"%6.1f" % schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            return "every-this-day-of-the-month: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            return "every-this-day-of-the-week: #{schedule['repeat-value']}"
        end
        JSON.generate(schedule)
    end

    # NSXWaveUtils::scheduleToDoNotShowDatetime(objectuuid, schedule)
    def self.scheduleToDoNotShowDatetime(objectuuid, schedule)
        if schedule['@'] == 'sticky' then
            return LucilleCore::datetimeAtComingMidnight()
        end
        if schedule['@'] == 'every-n-hours' then
            return Time.at(Time.new.to_i+3600*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-n-days' then
            return Time.at(Time.new.to_i+86400*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
           return Time.at(cursor).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            mapping = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday]!=schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            return Time.at(cursor).to_s
        end
    end

    # NSXWaveUtils::scheduleToMetric(schedule)
    def self.scheduleToMetric(schedule)

        # One Offs

        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? ( 0.90 + NSXMiscUtils::traceToMetricShift(schedule["uuid"]) ) : 0
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.80 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.80 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        1
    end

    # NSXWaveUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
    def self.catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
            next if !File.file?(path)
            next if File.basename(path)!='catalyst-uuid'
            thisUUID = IO.read(path).strip
            next if thisUUID!=uuid
            return File.dirname(path)
        end
        nil
    end

    # NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
    def self.catalystUUIDToItemFolderPathOrNull(uuid)
        storedValue = KeyValueStore::getOrNull(nil, "9f4e1f2e-0bab-4a56-9de7-7976805ca04d:#{uuid}")
        if storedValue then
            path = JSON.parse(storedValue)[0]
            if !path.nil? then
                uuidFilepath = "#{path}/catalyst-uuid"
                if File.exist?(uuidFilepath) and IO.read(uuidFilepath).strip == uuid then
                    return path
                end
            end
        end
        #puts "NSXWaveUtils::catalystUUIDToItemFolderPathOrNull, looking for #{uuid}"
        maybepath = NSXWaveUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        if maybepath then
            KeyValueStore::set(nil, "9f4e1f2e-0bab-4a56-9de7-7976805ca04d:#{uuid}", JSON.generate([maybepath]))
        end
        maybepath
    end

    # NSXWaveUtils::catalystUUIDsEnumerator()
    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    # NSXWaveUtils::timestring22ToFolderpath(timestring22)
    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    # NSXWaveUtils::writeScheduleToDisk(uuid, schedule)
    def self.writeScheduleToDisk(uuid, schedule)
        folderpath = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        return if !File.exists?(folderpath)
        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    # NSXWaveUtils::readScheduleFromWaveItemOrNull(uuid)
    def self.readScheduleFromWaveItemOrNull(uuid)
        folderpath = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return nil if folderpath.nil?
        filepath =
            if File.exists?("#{folderpath}/wave-schedule.json") then
                "#{folderpath}/wave-schedule.json"
            elsif File.exists?("#{folderpath}/catalyst-schedule.json") then
                "#{folderpath}/catalyst-schedule.json"
            else
                nil
            end
        return nil if filepath.nil?
        schedule = JSON.parse(IO.read(filepath))
    end

    # NSXWaveUtils::makeNewSchedule()
    def self.makeNewSchedule()
        NSXWaveUtils::makeScheduleObjectInteractivelyEnsureChoice()
    end

    # NSXWaveUtils::archiveWaveItem(uuid)
    def self.archiveWaveItem(uuid)
        return if uuid.nil?
        folderpath = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        NSXMiscUtils::moveLocationToCatalystBin(folderpath)
    end

    # NSXWaveUtils::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # NSXWaveUtils::objectUUIDToAnnounce(folderProbeMetadata,schedule)
    def self.objectUUIDToAnnounce(folderProbeMetadata,schedule)
        "[#{NSXWaveUtils::scheduleToAnnounce(schedule)}] #{NSXWaveUtils::extractFirstLineFromText(folderProbeMetadata["contents"])}"
    end

    # NSXWaveUtils::makeCatalystObjectOrNull(objectuuid)
    def self.makeCatalystObjectOrNull(objectuuid)
        location = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
        return nil if location.nil?
        schedule = NSXWaveUtils::readScheduleFromWaveItemOrNull(objectuuid)
        if schedule.nil? then
            NSXStreamsUtils::issueNewStreamItem(
                NSXStreamsUtils::makeSchedule("inbox"), 
                NSX2GenericContentUtils::issueItemLocationMoveOriginal(location), 
                NSXStreamsUtils::getNewStreamOrdinal()
            )
            return nil
        end
        folderProbeMetadata = NSXWaveFolderProbe::folderpath2metadata(location)
        announce = NSXWaveUtils::objectUUIDToAnnounce(folderProbeMetadata, schedule)
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        object = {}
        object['uuid'] = objectuuid
        object["agentuid"] = NSXAgentWave::agentuid()
        object["contentItem"] = contentItem
        object["metric"] = NSXWaveUtils::scheduleToMetric(schedule)
        object["commands"] = ["open", "done", "<uuid>", "loop", "recast", "description: <description>", "folder", "destroy"]
        object["defaultCommand"] = "done"
        object['schedule'] = schedule
        object["item-data"] = {}
        object["item-data"]["folderpath"] = location
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object
    end

    # NSXWaveUtils::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentWave::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXWaveUtils::performDone2(objectuuid)
    def self.performDone2(objectuuid)
        object = NSXWaveUtils::getObjectByUUIDOrNull(objectuuid)
        return if object.nil?
        schedule = object['schedule']
        datetime = NSXWaveUtils::scheduleToDoNotShowDatetime(objectuuid, schedule)
        NSXDoNotShowUntilDatetime::setDatetime(objectuuid, datetime)
    end

    # NSXWaveUtils::setItemDescription(objectuuid, description)
    def self.setItemDescription(objectuuid, description)
        folderpath = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
        return if folderpath.nil?
        File.open("#{folderpath}/description.txt", "w"){|f| f.write(description) }
    end

end

class NSXAgentWave

    # NSXAgentWave::agentuid()
    def self.agentuid()
        "283d34dd-c871-4a55-8610-31e7c762fb0d"
    end

    # NSXAgentWave::getObjects()
    def self.getObjects()
        NSXAgentWave::getAllObjects()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .reverse
    end

    # NSXAgentWave::getAllObjects()
    def self.getAllObjects()
        NSXWaveUtils::catalystUUIDsEnumerator()
            .map{|uuid| NSXWaveUtils::makeCatalystObjectOrNull(uuid) }
    end

    def self.processObjectAndCommand(objectuuid, command)

        if command == 'open' then
            object = NSXWaveUtils::getObjectByUUIDOrNull(objectuuid)
            return if object.nil?
            metadata = object["item-data"]["folder-probe-metadata"]
            NSXWaveFolderProbe::openActionOnMetadata(metadata)
            return
        end

        if command == 'done' then
            NSXWaveUtils::performDone2(objectuuid)
            return
        end

        if command == 'recast' then
            schedule = NSXWaveUtils::makeNewSchedule()
            NSXWaveUtils::writeScheduleToDisk(objectuuid, schedule)
            return
        end

        if command.start_with?('description:') then
            _, description = NSXStringParser::decompose(command)
            if description.nil? then
                puts "usage: description: <description>"
                LucilleCore::pressEnterToContinue()
                return
            end
            NSXWaveUtils::setItemDescription(objectuuid, description)
            return
        end

        if command == 'folder' then
            location = NSXWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
            return
        end

        if command == 'destroy' then
            if NSXMiscUtils::hasXNote(objectuuid) then
                puts "You cannot destroy a wave with an active note"
                LucilleCore::pressEnterToContinue()
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                NSXWaveUtils::archiveWaveItem(objectuuid)
                return
            end
            return
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentWave",
            "agentuid"    => NSXAgentWave::agentuid(),
        }
    )
rescue
end

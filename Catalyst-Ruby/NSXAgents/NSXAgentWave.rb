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
require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require "/Users/pascal/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "#{CATALYST_COMMON_DATABANK_CATALYST_INSTANCE_FOLDERPATH}/Agents-Data/Wave"

# ----------------------------------------------------------------------

class NSXAgentWaveUtils

    # NSXAgentWaveUtils::makeScheduleObjectInteractivelyEnsureChoice()
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

    # NSXAgentWaveUtils::scheduleToAnnounce(schedule)
    def self.scheduleToAnnounce(schedule)
        if schedule['@'] == 'sticky' then
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return "sticky, from: #{schedule['from-hour']}"
        end
        if schedule['@'] == 'every-n-hours' then
            return "every-n-hours: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-n-days' then
            return "every-n-days: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            return "every-this-day-of-the-month: #{schedule['repeat-value']}"
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            return "every-this-day-of-the-week: #{schedule['repeat-value']}"
        end
        JSON.generate(schedule)
    end

    # NSXAgentWaveUtils::scheduleToDoNotShowDatetime(objectuuid, schedule)
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

    # NSXAgentWaveUtils::scheduleToMetric(schedule)
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
            return 0.75 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.75 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.73 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.73 + NSXMiscUtils::traceToMetricShift(schedule["uuid"])
        end
        1
    end

    # NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
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

    # NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
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
        #puts "NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull, looking for #{uuid}"
        maybepath = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        if maybepath then
            KeyValueStore::set(nil, "9f4e1f2e-0bab-4a56-9de7-7976805ca04d:#{uuid}", JSON.generate([maybepath]))
        end
        maybepath
    end

    # NSXAgentWaveUtils::catalystUUIDsEnumerator()
    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    # NSXAgentWaveUtils::timestring22ToFolderpath(timestring22)
    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    # NSXAgentWaveUtils::writeScheduleToDisk(uuid, schedule)
    def self.writeScheduleToDisk(uuid, schedule)
        folderpath = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        return if !File.exists?(folderpath)
        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    # NSXAgentWaveUtils::readScheduleFromWaveItemOrNull(uuid)
    def self.readScheduleFromWaveItemOrNull(uuid)
        folderpath = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
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

    # NSXAgentWaveUtils::makeNewSchedule()
    def self.makeNewSchedule()
        NSXAgentWaveUtils::makeScheduleObjectInteractivelyEnsureChoice()
    end

    # NSXAgentWaveUtils::archiveWaveItem(uuid)
    def self.archiveWaveItem(uuid)
        return if uuid.nil?
        folderpath = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        NSXMiscUtils::moveLocationToCatalystBin(folderpath)
    end

    # NSXAgentWaveUtils::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # NSXAgentWaveUtils::objectUUIDToAnnounce(folderProbeMetadata,schedule)
    def self.objectUUIDToAnnounce(folderProbeMetadata,schedule)
        "[#{NSXAgentWaveUtils::scheduleToAnnounce(schedule)}] #{NSXAgentWaveUtils::extractFirstLineFromText(folderProbeMetadata["contents"])}"
    end

    # NSXAgentWaveUtils::makeCatalystObjectOrNull(objectuuid)
    def self.makeCatalystObjectOrNull(objectuuid)
        location = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
        return nil if location.nil?
        schedule = NSXAgentWaveUtils::readScheduleFromWaveItemOrNull(objectuuid)
        if schedule.nil? then
            genericItem = NSXGenericContents::issueItemLocationMoveOriginal(location)
            NSXStreamsUtils::issueNewStreamItem(CATALYST_INBOX_STREAMUUID, genericItem, NSXMiscUtils::getNewEndOfQueueStreamOrdinal())
            return nil
        end
        folderProbeMetadata = NSXFolderProbe::folderpath2metadata(location)
        announce = NSXAgentWaveUtils::objectUUIDToAnnounce(folderProbeMetadata, schedule)
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        object = {}
        object['uuid'] = objectuuid
        object["agentuid"] = NSXAgentWave::agentuid()
        object["contentItem"] = contentItem
        object["metric"] = NSXAgentWaveUtils::scheduleToMetric(schedule)
        object["commands"] = ["open", "done", "<uuid>", "loop", "recast", "description: <description>", "folder", "destroy"]
        object["defaultCommand"] = "done"
        object['schedule'] = schedule
        object["item-data"] = {}
        object["item-data"]["folderpath"] = location
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object
    end

    # NSXAgentWaveUtils::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXAgentWave::getAllObjects()
            .select{|object| object["uuid"] == objectuuid }
            .first
    end

    # NSXAgentWaveUtils::performDone(object)
    def self.performDone(object)
        uuid = object['uuid']
        schedule = object['schedule']
        datetime = NSXAgentWaveUtils::scheduleToDoNotShowDatetime(uuid, schedule)
        NSXDoNotShowUntilDatetime::setDatetime(uuid, datetime)
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
        NSXAgentWaveUtils::catalystUUIDsEnumerator()
            .map{|uuid| NSXAgentWaveUtils::makeCatalystObjectOrNull(uuid) }
    end

    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        object = NSXAgentWaveUtils::getObjectByUUIDOrNull(objectuuid)
        return if object.nil?
        schedule = object['schedule']
        if command=='open' then
            metadata = object["item-data"]["folder-probe-metadata"]
            NSXFolderProbe::openActionOnMetadata(metadata)
            return
        end

        if command=='done' then
            NSXAgentWaveUtils::performDone(object)
            if isLocalCommand then
                NSXMultiInstancesWrite::sendEventToDisk({
                    "instanceName" => NSXMiscUtils::instanceName(),
                    "eventType"    => "MultiInstanceEventType:CatalystObjectUUID+Command",
                    "payload"      => {
                        "objectuuid" => objectuuid,
                        "command"    => "done"
                    }
                })
            end
            return
        end

        if command=='recast' then
            schedule = NSXAgentWaveUtils::makeNewSchedule()
            NSXAgentWaveUtils::writeScheduleToDisk(objectuuid, schedule)
            return
        end

        if command.start_with?('description:') then
            _, description = NSXStringParser::decompose(command)
            if description.nil? then
                puts "usage: description: <description>"
                LucilleCore::pressEnterToContinue()
            end
            folderpath = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            File.open("#{folderpath}/description.txt", "w"){|f| f.write(description) }
            return
        end

        if command=='folder' then
            location = NSXAgentWaveUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
            return
        end

        if command=='destroy' then
            if NSXMiscUtils::hasXNote(objectuuid) then
                puts "You cannot destroy a wave with an active note"
                LucilleCore::pressEnterToContinue()
                return
            end
            if isLocalCommand then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                    NSXAgentWaveUtils::archiveWaveItem(objectuuid)
                    NSXMultiInstancesWrite::sendEventToDisk({
                        "instanceName" => NSXMiscUtils::instanceName(),
                        "eventType"    => "MultiInstanceEventType:CatalystObjectUUID+Command",
                        "payload"      => {
                            "objectuuid" => objectuuid,
                            "command"    => "done"
                        }
                    })
                    return
                end
            else
                NSXAgentWaveUtils::archiveWaveItem(objectuuid)
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


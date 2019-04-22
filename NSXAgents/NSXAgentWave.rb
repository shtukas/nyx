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
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave"

# ----------------------------------------------------------------------

# WaveSchedules::scheduleToAnnounce(schedule)
# WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule)
# WaveSchedules::scheduleToDoNotShowDatetime(objectuuid, schedule)
# WaveSchedules::scheduleToMetric(schedule)

class WaveSchedules

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

    def self.scheduleOfTypeDateIsInTheFuture(schedule)
        schedule['date'] > DateTime.now.to_date.to_s
    end

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

    # NSXMiscUtils::metricForNewObjects(unixtime
    def self.metricForNewObjects(unixtime)
        ageInHours = (Time.new.to_f - unixtime).to_f/3600
        0.6 + 0.2*(1-Math.exp(-ageInHours.to_f/6))
    end

    def self.scheduleToMetric(schedule)

        # One Offs

        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? 0.95 : 0
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.85
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.85
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.70
        end
        if schedule['@'] == 'every-n-days' then
            return 0.70
        end
        1
    end
end

class NSXAgentWave

    # NSXAgentWave::agentuuid()
    def self.agentuuid()
        "283d34dd-c871-4a55-8610-31e7c762fb0d"
    end

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

    # NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
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
        #puts "NSXAgentWave::catalystUUIDToItemFolderPathOrNull, looking for #{uuid}"
        maybepath = NSXAgentWave::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        if maybepath then
            KeyValueStore::set(nil, "9f4e1f2e-0bab-4a56-9de7-7976805ca04d:#{uuid}", JSON.generate([maybepath]))
        end
        maybepath
    end

    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    def self.writeScheduleToDisk(uuid, schedule)
        folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        return if !File.exists?(folderpath)
        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    def self.readScheduleFromWaveItemOrNull(uuid)
        folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
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

    def self.makeNewSchedule()
        WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
    end

    # NSXAgentWave::archiveWaveItem(uuid)
    def self.archiveWaveItem(uuid)
        return if uuid.nil?
        folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        NSXMiscUtils::moveLocationToCatalystBin(folderpath)
    end

    def self.commands(schedule)
        commands = ["open", "done", "<uuid>", "loop", "recast", "description: <description>", "folder", "destroy"]
        commands
    end

    # NSXAgentWave::defaultExpression(objectuuid, folderProbeMetadata, schedule)
    def self.defaultExpression(objectuuid, folderProbeMetadata, schedule)
        if folderProbeMetadata["target-type"] == "openable-file" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-hours" then
            return "open; done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-days" then
            return "open; done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-month" then
            return "open; done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-week" then
            return "open; done"
        end 
        if folderProbeMetadata["target-type"] == "url" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "folder" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "line" and schedule["@"] == "sticky" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "line" and schedule["@"] == "every-n-hours" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "line" and schedule["@"] == "every-n-days" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "line" and schedule["@"] == "every-this-day-of-the-month" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "line" and schedule["@"] == "every-this-day-of-the-week" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "sticky" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-n-hours" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-n-days" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-this-day-of-the-month" then
            return "done"
        end
        if folderProbeMetadata["target-type"] == "virtually-empty-wave-folder" and schedule["@"] == "every-this-day-of-the-week" then
            return "done"
        end
        nil
    end

    # NSXAgentWave::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # NSXAgentWave::objectUUIDToAnnounce(folderProbeMetadata,schedule)
    def self.objectUUIDToAnnounce(folderProbeMetadata,schedule)
        "[#{WaveSchedules::scheduleToAnnounce(schedule)}] #{NSXAgentWave::extractFirstLineFromText(folderProbeMetadata["contents"])}"
    end

    # NSXAgentWave::objectUUIDToBody(folderProbeMetadata,schedule)
    def self.objectUUIDToBody(folderProbeMetadata,schedule)
        if folderProbeMetadata["contents"].lines.size>1 then
            "[#{WaveSchedules::scheduleToAnnounce(schedule)}]\n#{folderProbeMetadata["contents"]}"
        else
            "[#{WaveSchedules::scheduleToAnnounce(schedule)}] #{folderProbeMetadata["contents"]}"
        end
    end

    # NSXAgentWave::removeWaveMetadataFilesAtLocation(location)
    def self.removeWaveMetadataFilesAtLocation(location)
        # Removing wave files.
        Dir.entries(location)
            .select{|filename| (filename.start_with?('catalyst-') or filename.start_with?('wave-')) and !filename.include?("description") }
            .map{|filename| "#{location}/#{filename}" }
            .each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }
    end
    
    # NSXAgentWave::makeCatalystObjectOrNull(objectuuid)
    def self.makeCatalystObjectOrNull(objectuuid)
        location = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(objectuuid)
        return nil if location.nil?
        schedule = NSXAgentWave::readScheduleFromWaveItemOrNull(objectuuid)
        if schedule.nil? then
            genericItem = NSXGenericContents::issueItemLocationMoveOriginal(location)
            NSXStreamsUtils::issueNewStreamItem("03b79978bcf7a712953c5543a9df9047", genericItem, NSXMiscUtils::makeStreamItemOrdinal())
            return nil
        end
        folderProbeMetadata = NSXFolderProbe::folderpath2metadata(location)
        metric = WaveSchedules::scheduleToMetric(schedule)
        object = {}
        object['uuid'] = objectuuid
        object["agentuid"] = self.agentuuid()
        object['metric'] = metric + NSXMiscUtils::traceToMetricShift(objectuuid)
        object['announce'] = NSXAgentWave::objectUUIDToAnnounce(folderProbeMetadata, schedule)
        object['body'] = NSXAgentWave::objectUUIDToBody(folderProbeMetadata, schedule)
        object['commands'] = NSXAgentWave::commands(schedule)
        object["defaultExpression"] = NSXAgentWave::defaultExpression(objectuuid, folderProbeMetadata, schedule)
        object['schedule'] = schedule
        object["item-data"] = {}
        object["item-data"]["folderpath"] = location
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object
    end

    # NSXAgentWave::getObjects()
    def self.getObjects()
        NSXAgentWave::getAllObjects()
            .reject{|object| NSXDoNotShowUntilDatetime::getFutureDatetimeOrNull(object['uuid']) }
            .sort{|o1, o2| o1["metric"]<=>o2["metric"] }
            .reverse
    end

    # NSXAgentWave::getAllObjects()
    def self.getAllObjects()
        NSXAgentWave::catalystUUIDsEnumerator()
            .map{|uuid| NSXAgentWave::makeCatalystObjectOrNull(uuid) }
    end

    def self.performDone(object)
        uuid = object['uuid']
        schedule = object['schedule']
        datetime = WaveSchedules::scheduleToDoNotShowDatetime(uuid, schedule)
        NSXDoNotShowUntilDatetime::setDatetime(uuid, datetime)
    end

    def self.disconnectMaybeEmailWaveCatalystItemFromEmailClientMetadata(uuid)
        folderpath = catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        if File.exist?("#{folderpath}/email-metatada-emailuid.txt") then
            puts "You are recasting an email, removing file email-metatada-emailuid.txt"
            LucilleCore::pressEnterToContinue()
            FileUtils.rm("#{folderpath}/email-metatada-emailuid.txt")
        end
    end

    def self.processObjectAndCommand(object, command)
        uuid = object['uuid']
        schedule = object['schedule']

        if command=='open' then
            metadata = object["item-data"]["folder-probe-metadata"]
            NSXFolderProbe::openActionOnMetadata(metadata)
        end

        if command=='done' then
            self.performDone(object)
            NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
        end

        if command=='recast' then
            NSXAgentWave::disconnectMaybeEmailWaveCatalystItemFromEmailClientMetadata(uuid)
            schedule = NSXAgentWave::makeNewSchedule()
            NSXAgentWave::writeScheduleToDisk(uuid, schedule)
            NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
        end

        if command.start_with?('description:') then
            _, description = NSXStringParser::decompose(command)
            if description.nil? then
                puts "usage: description: <description>"
                LucilleCore::pressEnterToContinue()
            end
            uuid = object["uuid"]
            folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
            File.open("#{folderpath}/description.txt", "w"){|f| f.write(description) }
            NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
        end

        if command=='folder' then
            location = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
        end

        if command=='destroy' then
            if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                NSXAgentWave::archiveWaveItem(uuid)
            end
        end
    end
end


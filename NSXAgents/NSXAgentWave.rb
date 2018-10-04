#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
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

# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave"
WAVE_DROPOFF_FOLDERPATH = "/Users/pascal/Desktop/Wave-DropOff"

# ----------------------------------------------------------------------

# WaveSchedules::makeScheduleObjectTypeNew()
# WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
# WaveSchedules::scheduleToAnnounce(schedule)
# WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule)
# WaveSchedules::scheduleToDoNotShowDatetime(objectuuid, schedule)
# WaveSchedules::scheduleToMetric(schedule)

class WaveSchedules

    def self.makeScheduleObjectTypeNew()
        {
            "uuid" => SecureRandom.hex,
            "@"    => "new",
            "unixtime" => Time.new.to_f
        }
    end

    def self.makeScheduleObjectInteractivelyEnsureChoice()

        scheduleTypes = ['new', 'sticky', 'date', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes, lambda{|entity| entity })

        schedule = nil
        if scheduleType=='new' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "@"    => "new",
                "unixtime" => Time.new.to_i
            }
        end
        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            schedule = {
                "uuid"      => SecureRandom.hex,
                "@"         => "sticky",
                "from-hour" => fromHour
            }
        end
        if scheduleType=='date' then
            puts "date:"
            puts "    format: YYYY-MM-DD"
            puts "    format: +<integer, nb of days>"
            print "> "
            date = STDIN.gets().strip
            if date[0, 1] == '+' then
                shift = date[1,99].to_i
                date = (DateTime.now+shift).to_date.to_s
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "@"    => "ondate",
                "date" => date
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

        if schedule['@'] == 'new' then
            return "new"
        end
        if schedule['@'] == 'sticky' then
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return "sticky, from: #{schedule['from-hour']}"
        end
        if schedule['@'] == 'ondate' then
            return "ondate: #{schedule['date']}"
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

    def self.scheduleToMetric(schedule)

        # One Offs

        if schedule['@'] == 'new' then
            return CommonsUtils::unixtimeToMetricNS1935(schedule['unixtime'])
        end
        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? 0.9 : 0
        end
        if schedule['@'] == 'ondate' then
            if WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule) then
                return 0
            else
                return 0.77
            end
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.78
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.78
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78
        end
        1
    end
end

# WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid)
# WaveEmailSupport::allEmailUIDs()

class WaveEmailSupport
    def self.emailUIDToCatalystUUIDOrNull(emailuid)
        NSXAgentWave::catalystUUIDsEnumerator()
            .each{|uuid|
                folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
                next if folderpath.nil?
                emailuidfilepath = "#{folderpath}/email-metatada-emailuid.txt"
                next if !File.exist?(emailuidfilepath)
                next if IO.read(emailuidfilepath).strip != emailuid
                return uuid
            }
        nil
    end
    def self.allEmailUIDs()
        NSXAgentWave::catalystUUIDsEnumerator()
            .map{|uuid|
                folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
                if folderpath then
                    emailuidfilepath = "#{folderpath}/email-metatada-emailuid.txt"
                    if File.exist?(emailuidfilepath) then
                        IO.read(emailuidfilepath).strip
                    else
                        nil
                    end
                else
                    nil
                end
            }
            .compact
    end
end

# WaveDevOps::collectWave()

class WaveDevOps
    def self.collectWave()
        Dir.entries(WAVE_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{WAVE_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                uuid = SecureRandom.hex(4)
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                folderpath = NSXAgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
                NSXAgentWave::writeScheduleToDisk(uuid, schedule)
                if File.file?(sourcelocation) then
                    FileUtils.cp(sourcelocation,folderpath)
                else
                    FileUtils.cp_r(sourcelocation,folderpath)
                end
                LucilleCore::removeFileSystemLocation(sourcelocation)
            }
    end
end

# NSXAgentWave::agentuuid()
# NSXAgentWave::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
# NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
# NSXAgentWave::catalystUUIDsEnumerator()
# NSXAgentWave::timestring22ToFolderpath(timestring22)
# NSXAgentWave::writeScheduleToDisk(uuid, schedule)
# NSXAgentWave::readScheduleFromWaveItemOrNull(uuid)
# NSXAgentWave::makeNewSchedule()
# NSXAgentWave::archiveWaveItem(uuid)
# NSXAgentWave::commands(schedule)
# NSXAgentWave::makeCatalystObjectOrNull(objectuuid)
# NSXAgentWave::objectUUIDToAnnounce(object,schedule)
# NSXAgentWave::removeWaveMetadataFilesAtLocation(location)
# NSXAgentWave::getObjects()
# NSXAgentWave::processObjectAndCommand(object, command)

class NSXAgentWave

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

    def self.catalystUUIDToItemFolderPathOrNull(uuid)
        storedValue = KeyValueStore::getOrNull(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}")
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
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}", JSON.generate([maybepath])) if maybepath
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

    def self.archiveWaveItem(uuid)
        return if uuid.nil?
        folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        retrun if !File.exists?(folderpath)
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        FileUtils.mv("#{folderpath}",targetFolder)
    end

    def self.commands(schedule)
        commands = ["open", "done", "<uuid>", "loop", "recast", "description:", "folder", "destroy"]
        commands
    end

    def self.defaultExpression(objectuuid, folderProbeMetadata, schedule)
        if folderProbeMetadata["target-type"] == "openable-file" then
            return "open"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-hours" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-n-days" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-month" then
            return "open done"
        end
        if folderProbeMetadata["target-type"] == "url" and schedule["@"] == "every-this-day-of-the-week" then
            return "open done"
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

    def self.objectUUIDToAnnounce(folderProbeMetadata,schedule)
        "[#{WaveSchedules::scheduleToAnnounce(schedule)}] #{folderProbeMetadata["announce"]}"
    end

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
            schedule = WaveSchedules::makeScheduleObjectTypeNew()
            File.open("#{location}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
        end
        folderProbeMetadata = NSXFolderProbe::folderpath2metadata(location)
        metric = WaveSchedules::scheduleToMetric(schedule)
        announce = NSXAgentWave::objectUUIDToAnnounce(folderProbeMetadata, schedule)
        object = {}
        object['uuid'] = objectuuid
        object["agent-uid"] = self.agentuuid()
        object['metric'] = metric + CommonsUtils::traceToMetricShift(objectuuid)
        object['announce'] = announce
        object['commands'] = NSXAgentWave::commands(schedule)
        object["default-expression"] = NSXAgentWave::defaultExpression(objectuuid, folderProbeMetadata, schedule)
        object['schedule'] = schedule
        object["item-data"] = {}
        object["item-data"]["folderpath"] = location
        object["item-data"]["folder-probe-metadata"] = folderProbeMetadata
        object
    end

    def self.getObjects()
        WaveDevOps::collectWave()
        NSXAgentWave::catalystUUIDsEnumerator().map{|uuid|
            NSXAgentWave::makeCatalystObjectOrNull(uuid)
        }
    end

    def self.doneObjectWithRepeatSchedule(object)
        uuid = object['uuid']
        schedule = object['schedule']
        datetime = WaveSchedules::scheduleToDoNotShowDatetime(uuid, schedule)
        NSXDoNotShowUntilDatetime::setDatetime(uuid, datetime)
    end

    def self.doneObjectWithOneOffTask(object)
        NSXAgentWave::archiveWaveItem(object['uuid'])
    end

    def self.performDone(object)
        uuid = object['uuid']
        schedule = object['schedule']
        if ["new", 'ondate'].include?(schedule['@']) then
            self.doneObjectWithOneOffTask(object)
        end
        if ['sticky', 'every-n-hours', 'every-n-days', 'every-this-day-of-the-month', 'every-this-day-of-the-week'].include?(schedule['@']) then
            self.doneObjectWithRepeatSchedule(object)
        end
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
            return ["nothing"]
        end

        if command=='done' then
            self.performDone(object)
            newobject = NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
            if newobject then
                return ["update", newobject]
            else
                return ["remove", object["uuid"]]
            end
        end

        if command=='recast' then
            NSXAgentWave::disconnectMaybeEmailWaveCatalystItemFromEmailClientMetadata(uuid)
            schedule = NSXAgentWave::makeNewSchedule()
            NSXAgentWave::writeScheduleToDisk(uuid, schedule)
            newobject = NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
            if newobject then
                return ["update", newobject]
            else
                return ["remove", object["uuid"]]
            end
        end

        if command == 'description:' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uuid = object["uuid"]
            folderpath = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
            File.open("#{folderpath}/description.txt", "w"){|f| f.write(description) }
            newobject = NSXAgentWave::makeCatalystObjectOrNull(object["uuid"])
            if newobject then
                return ["update", newobject]
            else
                return ["remove", object["uuid"]]
            end
        end

        if command=='folder' then
            location = NSXAgentWave::catalystUUIDToItemFolderPathOrNull(uuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
            return ["nothing"]
        end

        if command=='destroy' then
            if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                NSXAgentWave::archiveWaveItem(uuid)
                return ["remove", object["uuid"]]
            else
                return ["nothing"]
            end
        end
        ["nothing"]
    end
end

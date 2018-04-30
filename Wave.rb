#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'json'

=begin

  -- reading the string and building the object
     dataset = IO.read($dataset_location)
     JSON.parse(dataset)

  -- printing the string
     file.puts JSON.pretty_generate(dataset)

=end

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

require_relative "Commons.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/LucilleOS/Librarian/Librarian-Exported-Functions.rb"

# ----------------------------------------------------------------------

WAVE_DATABANK_WAVE_FOLDER_PATH = "/Galaxy/DataBank/Catalyst/Wave"
WAVE_TIME_COMMITMENT_BASE_METRIC = 0.3
WAVE_TIME_COMMITMENT_RUN_METRIC = 2.2
WAVE_DROPOFF_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Wave/Wave-DropOff"

# ----------------------------------------------------------------------

# WaveTimelineUtils::catalystActiveOpsLineFolderPath()
# WaveTimelineUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
# WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
# WaveTimelineUtils::catalystUUIDsEnumerator()
# WaveTimelineUtils::timestring22ToFolderpath(timestring22)
# WaveTimelineUtils::writeScheduleToDisk(uuid,schedule)
# WaveTimelineUtils::readScheduleFromWaveItemOrNull(uuid)
# WaveTimelineUtils::extractCatalystDescriptionAtWaveItem(uuid)
# WaveTimelineUtils::extractCatalystShellDescriptionAtWaveItem(uuid)
# WaveTimelineUtils::extractNaturalObjectLocationPathAtWaveItem(uuid)
# WaveTimelineUtils::makeNewSchedule()
# WaveTimelineUtils::archiveWaveItems(uuid)
# WaveTimelineUtils::commands(schedule)
# WaveTimelineUtils::extractFirstURLOrNUll(string)
# WaveTimelineUtils::objectuuidToCatalystObject(objectuuid)
# WaveTimelineUtils::getCatalystObjects()
# WaveTimelineUtils::objectUUIDToAnnounce(object,schedule)
# WaveTimelineUtils::removeWaveMetadataFilesAtLocation(location)

class WaveTimelineUtils

    def self.catalystActiveOpsLineFolderPath()
        "#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active"
    end

    def self.catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        Find.find(WaveTimelineUtils::catalystActiveOpsLineFolderPath()) do |path|
            next if !File.file?(path)
            next if File.basename(path)!='catalyst-uuid'
            thisUUID = IO.read(path).strip
            next if thisUUID!=uuid
            return File.dirname(path)
        end        
        nil
    end

    def self.catalystUUIDToItemFolderPathOrNull(uuid)
        storedValue = KeyValueStore::getOrNull(nil, "ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}")
        if storedValue then
            path = JSON.parse(storedValue)[0]
            if !path.nil? then
                uuidFilepath = "#{path}/catalyst-uuid"
                if File.exist?(uuidFilepath) and IO.read(uuidFilepath).strip == uuid then
                    return path
                end
            end
        end
        #puts "WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull, looking for #{uuid}"
        maybepath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
        KeyValueStore::set(nil, "ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}", JSON.generate([maybepath]))
        maybepath
    end

    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find(WaveTimelineUtils::catalystActiveOpsLineFolderPath()) do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WaveTimelineUtils::catalystActiveOpsLineFolderPath()}/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    def self.writeScheduleToDisk(uuid,schedule)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::writeScheduleToDisk for uuid: #{uuid}" if folderpath.nil?

        # There is in principle no reason why the following test would be there, but when 
        # I manually remove a folder and press [enter], since [enter] updates catalyst-schedule.json the program crashes.
        return if !File.exists?(folderpath)

        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    def self.readScheduleFromWaveItemOrNull(uuid)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::readScheduleFromWaveItemOrNull for uuid: #{uuid}" if folderpath.nil?
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

    def self.extractCatalystDescriptionAtWaveItem(uuid)

        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::extractCatalystDescriptionAtWaveItem for uuid: #{JSON.generate([uuid])}" if folderpath.nil?

        descriptionFilepath = "#{folderpath}/catalyst-description.txt"
        return IO.read(descriptionFilepath).strip if File.exists?(descriptionFilepath)

        getFiles = lambda {|folderpath|
            Dir.entries(folderpath)
            .select{|filename| filename[0, 1] != '.' }
            .select{|filename| filename[0, 4] != 'wave' }
            .select{|filename| filename[0, 8] != 'catalyst' }
        }
        files = getFiles.call(folderpath)

        getTextFiles = lambda {|folderpath|
            Dir.entries(folderpath)
            .select{|filename| filename[0, 4] != 'wave' }
            .select{|filename| filename[0, 8] != 'catalyst' }
            .select{|filename| filename[-4,4] == '.txt' }
        }
        textfiles = getTextFiles.call(folderpath)

        # below: If there is only one file and that file is the text file and this text file has only one non empty line, use that as the description.

        if files.size==0 then
            return "empty item"
        end

        if files.size == 1 and textfiles.size == 1 then
            text = IO.read("#{folderpath}/#{textfiles[0]}")
            if text.lines.select{|line| line.strip.size>0 }.count==1 then
                return text.lines.first.strip
            end
        end

        if files.size>1 then
            "\n" + files.map{|file| "          "+file }.join("\n")
        else
            files[0]
        end
    end

    def self.extractCatalystShellDescriptionAtWaveItem(uuid)

        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::extractCatalystShellDescriptionAtWaveItem for uuid: #{uuid}" if folderpath.nil?

        descriptionFilepath = "#{folderpath}/catalyst-description.txt"
        return IO.read(descriptionFilepath).strip if File.exists?(descriptionFilepath)

        getFiles = lambda {|folderpath|
            Dir.entries(folderpath)
            .select{|filename| filename[0, 4] != 'wave' }
            .select{|filename| filename[0, 1] != '.' }
            .select{|filename| filename[0, 8] != 'catalyst' }
        }
        files = getFiles.call(folderpath)

        getTextFiles = lambda {|folderpath|
            Dir.entries(folderpath)
            .select{|filename| filename[0, 4] != 'wave' }
            .select{|filename| filename[0, 8] != 'catalyst' }
            .select{|filename| filename[-4,4] == '.txt' }
        }
        textfiles = getTextFiles.call(folderpath)

        # below: If there is only one file and that file is the text file and this text file has only one non empty line, use that as the description.

        if files.size == 1 and textfiles.size == 1 then
            text = IO.read("#{folderpath}/#{textfiles[0]}")
            if text.lines.select{|line| line.strip.size>0 }.count==1 then
                return text.lines.first.strip
            end
        end

        if files.size>0 then
            "\n" + files.join("\n")
        else
            files[0]
        end    
    end

    def self.extractNaturalObjectLocationPathAtWaveItem(uuid)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::extractNaturalObjectLocationPathAtWaveItem for uuid: #{uuid}" if folderpath.nil?

        filepath = "#{folderpath}/wave-target-filename.txt"
        return  "#{folderpath}/#{IO.read(filepath).strip}" if File.exists?(filepath)

        filepath = "#{folderpath}/catalyst-natural-target.txt"
        return  "#{folderpath}/#{IO.read(filepath).strip}" if File.exists?(filepath)

        filepath = "#{folderpath}/catalyst-description.txt"
        if File.exists?(filepath) then
            description =  IO.read("#{folderpath}/catalyst-description.txt").strip
            if File.exists?("#{folderpath}/#{description}") then
                File.open("#{folderpath}/wave-target-filename.txt",'w'){|f| f.write(description) }
            end
        end
        return filepath if File.exists?(filepath) 

        getFiles = lambda {|folderpath|
            Dir.entries("#{folderpath}")
            .select{|filename| filename[0, 1] != '.' }
            .select{|filename| filename[0, 8] != 'catalyst' }
            .select{|filename| filename[0, 4] != 'wave' }
        }
        files = getFiles.call(folderpath)
        if files.size == 1 then
            return "#{folderpath}/#{files[0]}"
        end               

        "#{folderpath}"
    end

    def self.makeNewSchedule()
        WaveSchedules::makeScheduleObjectInteractivelyOrNull()
    end

    def self.archiveWaveItems(uuid)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        return if folderpath.nil?
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
        FileUtils.mkpath(targetFolder)
        FileUtils.mv("#{folderpath}",targetFolder)
    end

    def self.commands(schedule)
        ['open', 'done', '<uuid>', 'recast', 'folder', 'destroy', ">stream", '>lib']
    end

    def self.defaultExpression(announce, schedule)
        if schedule["@"].start_with?("every") then
            if announce.include?("http") then
                "open done"
            else
                "done"
            end
        else
            "open done"
        end
    end

    def self.extractFirstURLOrNUll(string)
        return nil if !string.include?('http')
        while string.include?('http') and !string.start_with?('http') do
            string = string[1,string.length]
        end
        if string.include?(' ') then
            string = string[0,string.index(' ')]
        end
        string
    end

    def self.objectuuidToCatalystObject(objectuuid)
        location = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
        if location.nil? then
            puts "Could not find location for uuid: #{location}"
            exit
        end
        schedule = WaveTimelineUtils::readScheduleFromWaveItemOrNull(objectuuid)
        if schedule.nil? then
            puts "Could not find schedule for location: #{location}"
            exit
        end
        metric = WaveSchedules::scheduleToMetric(schedule)
        announce = WaveTimelineUtils::objectUUIDToAnnounce(objectuuid, schedule)
        object = {}
        object['uuid'] = objectuuid
        object['metric'] = metric
        object['announce'] = announce
        object['commands'] = WaveTimelineUtils::commands(schedule)
        object["default-expression"] = WaveTimelineUtils::defaultExpression(announce, schedule)
        object['command-interpreter'] = lambda {|object, command| WaveInterface::interpreter(object, command) }
        object['schedule'] = schedule
        object
    end

    def self.getCatalystObjects()
        WaveTimelineUtils::catalystUUIDsEnumerator()
            .map{|objectuuid| WaveTimelineUtils::objectuuidToCatalystObject(objectuuid) }
    end

    def self.objectUUIDToAnnounce(objectuuid,schedule)
        output = []        
        p4 = WaveTimelineUtils::extractCatalystDescriptionAtWaveItem(objectuuid)
        p4 = p4.size==0 ? "" : " #{p4}"
        p5 = WaveSchedules::scheduleToAnnounce(schedule)
        p6 = 
            if schedule["do-not-show-until-datetime"] and ( schedule["do-not-show-until-datetime"] > Time.new.to_s ) then
                " (not shown until #{schedule["do-not-show-until-datetime"]})"
            else
                ""
            end
        "{#{p5}}#{p4}#{p6}"    
    end

    def self.removeWaveMetadataFilesAtLocation(location)
        # Removing wave files.
        Dir.entries(location)
            .select{|filename| (filename.start_with?('catalyst-') or filename.start_with?('wave-')) and !filename.include?("description") }
            .map{|filename| "#{location}/#{filename}" }
            .each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }
    end

end

# WaveSchedules::makeScheduleObjectNew()
# WaveSchedules::makeScheduleObjectInteractivelyOrNull()
# WaveSchedules::scheduleToAnnounce(schedule)
# WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule)
# WaveSchedules::cycleSchedule(schedule)
# WaveSchedules::traceToRealInUnitInterval(trace)
# WaveSchedules::traceToMetricShift(trace)
# WaveSchedules::scheduleToMetric(schedule)

class WaveSchedules

    def self.makeScheduleObjectNew()
        {
            "uuid" => SecureRandom.hex,
            "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
            "@"    => "new",
            "unixtime" => Time.new.to_i
        }
    end

    def self.makeScheduleObjectInteractivelyOrNull()

        scheduleTypes = ['new', 'today', 'sticky', 'date', 'repeat']
        scheduleType = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes, lambda{|entity| entity })

        schedule = nil
        if scheduleType=='new' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "new",
                "unixtime" => Time.new.to_i
            }
        end
        if scheduleType=='today' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "today",
                "unixtime" => Time.new.to_i
            }
        end
        if scheduleType=='sticky' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "sticky"
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
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "ondate",
                "date" => date
            }
        end
        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

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
                value = LucilleCore::interactivelySelectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
            end
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => type,
                "repeat-value" => value
            }
        end
        schedule
    end

    def self.scheduleToAnnounce(schedule)

        raise "WaveSchedules::scheduleToAnnounce doesn't accept null schedules" if schedule.nil?

        if schedule['@'] == 'new' then
            return "new"
        end
        if schedule['@'] == 'today' then
            return "today"
        end          
        if schedule['@'] == 'sticky' then
            return "sticky"
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

    def self.cycleSchedule(schedule)

        raise "WaveSchedules::cycleSchedule doesn't accept null schedules" if schedule.nil?

        # The "do-not-show-until-datetime" kills the metric

        if schedule['@'] == 'sticky' then
            schedule["do-not-show-until-datetime"] = LucilleCore::datetimeAtComingMidnight()
        end
        if schedule['@'] == 'every-n-hours' then
            schedule["do-not-show-until-datetime"] = Time.at(Time.new.to_i+3600*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-n-days' then
            schedule["do-not-show-until-datetime"] = Time.at(Time.new.to_i+86400*schedule['repeat-value'].to_f).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            schedule["do-not-show-until-datetime"] = Time.at(cursor).to_s
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            mapping = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday]!=schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            schedule["do-not-show-until-datetime"] = Time.at(cursor).to_s
        end

        schedule
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+trace.gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.000001*WaveSchedules::traceToRealInUnitInterval(trace)
    end

    def self.scheduleToMetric(schedule)

        # Special Circumstances

        if schedule["do-not-show-until-datetime"] and schedule["do-not-show-until-datetime"] > Time.new.to_s then
            return 0
        end

        if schedule['metric'] then
            return schedule['metric'] # set by wave emails
        end

        # One Offs

        if schedule['@'] == 'new' then
            age = schedule['unixtime'] - DateTime.parse("#{Time.new.to_s[0, 10]} 00:00:00").to_time.to_i
            # newer items (bigger age) have a lower metric
            return 0.820 + 0.010*Math.atan( -age.to_f/86400 )
        end
        if schedule['@'] == 'today' then
            return 0.8 - 0.05*Math.exp( -0.1*(Time.new.to_i-schedule['unixtime']).to_f/86400 )
        end
        if schedule['@'] == 'sticky' then # shows up once a day
            return 1.5 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'ondate' then
            if WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule) then
                return 0
            else
                return 0.77 + WaveSchedules::traceToMetricShift(schedule['uuid'])
            end
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.78 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.78 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        1
    end
end

# WaveDevOps::today()
# WaveDevOps::getArchiveSizeInMegaBytes()
# WaveDevOps::getFirstDiveFirstLocationAtLocation(location)
# WaveDevOps::archivesGarbageCollection(verbose): Int # number of items removed
# WaveDevOps::collectWaveObjects()

class WaveDevOps

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getArchiveSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    WaveDevOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.archivesGarbageCollection(verbose)
        answer = 0
        while WaveDevOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = WaveDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
            answer = answer + 1
        end
        answer
    end

    def self.collectWaveObjects()
        Dir.entries(WAVE_DROPOFF_FOLDERPATH)
            .select{|filename| filename[0, 1] != '.' }
            .map{|filename| "#{WAVE_DROPOFF_FOLDERPATH}/#{filename}" }
            .each{|sourcelocation|
                uuid = SecureRandom.hex(4)
                description = 
                    if sourcelocation[-4,4] == '.txt' and IO.read(sourcelocation).lines.to_a.size == 1 then
                        IO.read(sourcelocation).strip
                    else
                        File.basename(sourcelocation)
                    end
                schedule = WaveSchedules::makeScheduleObjectNew()
                folderpath = WaveTimelineUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
                File.open("#{folderpath}/catalyst-description.txt", 'w') {|f| f.write(description) }
                WaveTimelineUtils::writeScheduleToDisk(uuid,schedule)
                if File.file?(sourcelocation) then
                    FileUtils.cp(sourcelocation,folderpath)
                else
                    FileUtils.cp_r(sourcelocation,folderpath)
                end
                File.open("#{folderpath}/wave-target-filename.txt", 'w') {|f| f.write(File.basename(sourcelocation)) }
                LucilleCore::removeFileSystemLocation(sourcelocation)
            }
    end
end

# WaveInterface::getCatalystObjects()
# WaveInterface::interpreter(object, command): (directive, value)
    # (null, false)
    # (null, true)
    # ("object-to-display", object)

class WaveInterface

    def self.getCatalystObjects()
        WaveDevOps::collectWaveObjects()
        WaveTimelineUtils::getCatalystObjects()
    end

    def self.interpreter(object, command)

        xobject1 = WaveInterface::getCatalystObjects().select{|object| object['uuid']==command }.first
        if xobject1 then
            return ["object-to-display", xobject1]
        end      

        # ------------------------------------------
        # 

        schedule = object['schedule']
        objectuuid = object['uuid']

        if command=='open' then
            objectuuid = object['uuid']
            naturalobjectlocation = WaveTimelineUtils::extractNaturalObjectLocationPathAtWaveItem(objectuuid)
            if File.file?(naturalobjectlocation) and naturalobjectlocation[-4,4] == '.txt' and IO.read(naturalobjectlocation).strip.lines.to_a.size == 1 and IO.read(naturalobjectlocation).strip.start_with?('http') then
                url = IO.read(naturalobjectlocation).strip
                system("open -a Safari '#{url}'")
                return
            end            
            if File.file?(naturalobjectlocation) then
                system("open '#{naturalobjectlocation}'")
                return
            end
            puts "Opening #{naturalobjectlocation}"
            system("open '#{naturalobjectlocation}'")
        end

        if command=='done' then

            if schedule['@'] == 'new' then
                WaveTimelineUtils::archiveWaveItems(objectuuid)        
            end
            if schedule['@'] == 'today' then
                WaveTimelineUtils::archiveWaveItems(objectuuid)
            end
            if schedule['@'] == 'queue' then
                WaveTimelineUtils::archiveWaveItems(objectuuid)
            end
            if schedule['@'] == 'sticky' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
            if schedule['@'] == 'check' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
            if schedule['@'] == 'ondate' then
                WaveTimelineUtils::archiveWaveItems(objectuuid)        
            end
            if schedule['@'] == 'every-n-hours' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
            if schedule['@'] == 'every-n-days' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
            if schedule['@'] == 'every-this-day-of-the-month' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
            if schedule['@'] == 'every-this-day-of-the-week' then
                schedule = WaveSchedules::cycleSchedule(schedule)
                WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            end
        end

        if command=='recast' then
            schedule = object['schedule']
            objectuuid = object['uuid']
            schedule = WaveTimelineUtils::makeNewSchedule()
            WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
        end

        if command=='folder' then
            location = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
        end

        if command=='destroy' then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Do you want to destroy this item ? : ") then
                WaveTimelineUtils::archiveWaveItems(objectuuid)                       
            end
        end

        if command=='>stream' then
            sourcelocation = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            targetfolderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/strm2/#{LucilleCore::timeStringL22()}"
            FileUtils.mv(sourcelocation, targetfolderpath)
            WaveTimelineUtils::removeWaveMetadataFilesAtLocation(targetfolderpath)
            WaveTimelineUtils::archiveWaveItems(objectuuid) 
        end

        if command=='>lib' then
            
            puts "I am copying the wave folder to the Desktop and will rename it to a new atlas reference"

            # Selection of the new atlas reference
            atlasreference = "atlas-#{SecureRandom.hex(8)}"

            puts "atlas reference: #{atlasreference}"

            # Copying the wave folder to the Desktop                    
            sourcelocation = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            staginglocation = "/Users/pascal/Desktop/#{atlasreference}"
            LucilleCore::copyFileSystemLocation(sourcelocation, staginglocation)

            # Removing wave files.
            WaveTimelineUtils::removeWaveMetadataFilesAtLocation(staginglocation)

            puts "Data moved to the staging folder (Desktop), edit and press [Enter]"
            LucilleCore::pressEnterToContinue()

            LibrarianExportedFunctions::librarianUserInterface_makeNewPermanodeInteractive(staginglocation, nil, nil, atlasreference, nil, nil)

            # Copying the staging folder to the timeline
            targetparentlocation = R136CoreUtils::getNewUniqueDataTimelineIndexSubFolderPathReadyToUse()

            LucilleCore::copyFileSystemLocation(staginglocation, targetparentlocation)

            LucilleCore::removeFileSystemLocation(staginglocation)

            puts "Archiving the Wave item"
            WaveTimelineUtils::archiveWaveItems(objectuuid) 
        end
 
        nil
    end
end



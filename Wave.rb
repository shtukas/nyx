#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/xstore.rb"
=begin

    Xcache::set(key, value)
    Xcache::getOrNull(key)
    Xcache::getOrDefaultValue(key, defaultValue)
    Xcache::destroy(key)

    XcacheSets::values(setuid)
    XcacheSets::insert(setuid, valueuid, value)
    XcacheSets::remove(setuid, valueuid)

    XStore::set(repositorypath, key, value)
    XStore::getOrNull(repositorypath, key)
    XStore::getOrDefaultValue(repositorypath, key, defaultValue)
    XStore::destroy(repositorypath, key)

    XStoreSets::values(repositorypath, setuid)
    XStoreSets::insert(repositorypath, setuid, valueuid, value)
    XStoreSets::remove(repositorypath, setuid, valueuid)

    Xcache and XStore have identical interfaces
    Xcache is XStore with a repositorypath defaulting to x-space

=end

require "/Galaxy/LucilleOS/Misc-Resources/Ruby-Libraries/LucilleCore.rb"

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

require_relative "CatalystCore.rb"
require_relative "Wave-TodaySectionManagement.rb"
require_relative "Projects.rb"

# ----------------------------------------------------------------------

DATABANK_WAVE_FOLDER_PATH = "/Galaxy/DataBank/Wave"

# ----------------------------------------------------------------------

class WaveTimelineUtils

    # WaveTimelineUtils::catalystActiveOpsLineFolderPath()
    def self.catalystActiveOpsLineFolderPath()
        "#{DATABANK_WAVE_FOLDER_PATH}/02-OpsLine-Active"
    end

    # WaveTimelineUtils::catalystArchiveOpsLineFolderPath()
    def self.catalystArchiveOpsLineFolderPath()
        "#{DATABANK_WAVE_FOLDER_PATH}/01-OpsLine-Archives"
    end

    # WaveTimelineUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(uuid)
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

    # WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
    def self.catalystUUIDToItemFolderPathOrNull(uuid)
        storedValue = Xcache::getOrNull("ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}")
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
        Xcache::set("ed459722-ca2e-4139-a7c0-796968ef5b66:#{uuid}", JSON.generate([maybepath]))
        maybepath
    end

    # WaveTimelineUtils::catalystUUIDsEnumerator()
    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find(WaveTimelineUtils::catalystActiveOpsLineFolderPath()) do |path|
                next if !File.file?(path)
                next if File.basename(path) != 'catalyst-uuid'
                uuids << IO.read(path).strip
            end
        end
    end

    # WaveTimelineUtils::timestring22ToFolderpath(timestring22)
    def self.timestring22ToFolderpath(timestring22) # 20170923-143534-341733
        "#{WaveTimelineUtils::catalystActiveOpsLineFolderPath()}/#{timestring22[0, 4]}/#{timestring22[0, 6]}/#{timestring22[0, 8]}/#{timestring22}"
    end

    # WaveTimelineUtils::writeScheduleToDisk(uuid,schedule)
    def self.writeScheduleToDisk(uuid,schedule)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::writeScheduleToDisk for uuid: #{uuid}" if folderpath.nil?

        # There is in principle no reason why the following test would be there, but when 
        # I manually remove a folder and press [enter], since [enter] updates catalyst-schedule.json the program crashes.
        return if !File.exists?(folderpath)

        LucilleCore::removeFileSystemLocation("#{folderpath}/catalyst-schedule.json")
        File.open("#{folderpath}/wave-schedule.json", 'w') {|f| f.write(JSON.pretty_generate(schedule)) }
    end

    # WaveTimelineUtils::readScheduleFromWaveItemOrNull(uuid)
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

    # WaveTimelineUtils::extractCatalystDescriptionAtWaveItem(uuid)
    def self.extractCatalystDescriptionAtWaveItem(uuid)

        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::extractCatalystDescriptionAtWaveItem for uuid: #{uuid}" if folderpath.nil?

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

    # WaveTimelineUtils::extractCatalystShellDescriptionAtWaveItem(uuid)
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

    # WaveTimelineUtils::extractOriginSystemAtWaveItemOrNull(uuid)
    def self.extractOriginSystemAtWaveItemOrNull(uuid)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::extractOriginSystemAtWaveItemOrNull for uuid: #{uuid}" if folderpath.nil?
        filepath = "#{folderpath}/catalyst-origin.txt"
        return nil if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # WaveTimelineUtils::extractNaturalObjectLocationPathAtWaveItem(uuid)
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

    # WaveTimelineUtils::makeNewSchedule()
    def self.makeNewSchedule()
        WaveSchedules::makeScheduleObjectInteractivelyOrNull()
    end

    # WaveTimelineUtils::archiveWaveItems(uuid)
    def self.archiveWaveItems(uuid)
        folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(uuid)
        raise "[error] WaveTimelineUtils::archiveWaveItems for uuid: #{uuid}" if folderpath.nil?
        time = Time.new
        targetFolder = "#{WaveTimelineUtils::catalystArchiveOpsLineFolderPath()}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
        FileUtils.mkpath(targetFolder)
        FileUtils.mv("#{folderpath}",targetFolder)

        # And here we do something else:
        # If the uuid was the uuid of a section of the Today+Calendar file, we remove it now 
        TodaySectionManagement::removeSectionFromFile(uuid)
    end

    # WaveTimelineUtils::commands(schedule)
    def self.commands(schedule)
        if schedule['@'] == 'project' then
            return ['start', 'stop', '<uuid>', 'recast', 'folder', '(+)datetimecode', 'destroy']
        end
        ['open', 'done', '<uuid>', 'recast', 'folder', '(+)datetimecode', 'destroy', '>todolist', '>lib']
    end

    # WaveTimelineUtils::extractFirstURLOrNUll(string)
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

    # WaveTimelineUtils::defaultCommandsOrNull(announce, schedule)
    def self.defaultCommandsOrNull(announce, schedule)

        if schedule['default-commands'] then
            return schedule['default-commands'] # When a schedule carry default commands, then the object gets them by default.
        end

        repeatTypes = ['every-n-hours', 'every-n-days', 'every-this-day-of-the-month', 'every-this-day-of-the-week']
        if repeatTypes.include?(schedule['@']) and WaveTimelineUtils::extractFirstURLOrNUll(announce) then
            return ["shell: open #{WaveTimelineUtils::extractFirstURLOrNUll(announce)}", 'done']
        end

        if schedule['@']=='sticky' and WaveTimelineUtils::extractFirstURLOrNUll(announce) then
            return ["shell: open #{WaveTimelineUtils::extractFirstURLOrNUll(announce)}", 'done']
        end

        if repeatTypes.include?(schedule['@']) then
            return ['done']
        end
        nil
    end

    # WaveTimelineUtils::objectuuidToCatalystObject(objectuuid)
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

        metric = 
            if File.exists?("#{location}/metric") then
                IO.read("#{location}/metric").to_f
            else
                WaveSchedules::scheduleToMetric(schedule)
            end
        
        description  = WaveTimelineUtils::extractCatalystDescriptionAtWaveItem(objectuuid)

        originSystem = WaveTimelineUtils::extractOriginSystemAtWaveItemOrNull(objectuuid)
        if originSystem.nil? then
            originSystem = ""
        else
            originSystem = "#{originSystem}"
        end

        object = {}
        object['uuid'] = objectuuid
        object['owner'] = 'wave'
        object['metric'] = metric
        object['announce'] = WaveTimelineUtils::objectToAnnounceShell_shortVersion(object, schedule)
        object['commands'] = WaveTimelineUtils::commands(schedule)
        object['default-commands'] = WaveTimelineUtils::defaultCommandsOrNull(object['announce'], schedule)
        object['command-interpreter'] = lambda {|object, command| WaveInterface::interpreter(object, command) }
        object['schedule'] = schedule
        object
    end

    # WaveTimelineUtils::getCatalystObjects()
    def self.getCatalystObjects()
        WaveTimelineUtils::catalystUUIDsEnumerator()
            .map{|objectuuid| WaveTimelineUtils::objectuuidToCatalystObject(objectuuid) }
    end

    # WaveTimelineUtils::objectToAnnounceShell_shortVersion(object,schedule)
    def self.objectToAnnounceShell_shortVersion(object,schedule)
        output = []        
        p3 = WaveTimelineUtils::extractOriginSystemAtWaveItemOrNull(object['uuid'])
        p3 = p3.nil? ? "" : " #{p3}"
        p4 = WaveTimelineUtils::extractCatalystDescriptionAtWaveItem(object['uuid'])
        p4 = p4.size==0 ? "" : " #{p4}"
        p5 = WaveSchedules::scheduleToAnnounce(schedule)
        p6 = 
            if schedule["do-not-show-until-datetime"] and ( schedule["do-not-show-until-datetime"] > Time.new.to_s ) then
                " (not shown until #{schedule["do-not-show-until-datetime"]})"
            else
                ""
            end
        "[#{object['uuid']}] (#{( "%.3f" % object['metric'] )}) {#{p5}}#{p3}#{p4}#{p6}"    
    end
end

class WaveSchedules

    # WaveSchedules::scheduleUtils_distanceBetweenTwoDatesInDays(trace)
    def self.scheduleUtils_distanceBetweenTwoDatesInDays(date1,date2)
        (DateTime.parse("#{date1} 00:00:00").to_time.to_f - DateTime.parse("#{date2} 00:00:00").to_time.to_f).abs.to_f/86400
    end

    # WaveSchedules::makeScheduleObjectNew()
    def self.makeScheduleObjectNew()
        {
            "uuid" => SecureRandom.hex,
            "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
            "@"    => "new",
            "unixtime" => Time.new.to_i
        }
    end

    # WaveSchedules::makeScheduleObjectInteractivelyOrNull()
    def self.makeScheduleObjectInteractivelyOrNull()

        scheduleTypes = ['new','today','project','sticky','date','repeat']
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
        if scheduleType=='project' then
            schedule = {
                "uuid" => SecureRandom.hex,
                "type" => "schedule-7da672d1-6e30-4af8-a641-e4760c3963e6",
                "@"    => "project",
                "hours-per-week" => LucilleCore::askQuestionAnswerAsString("Hours per week: ").to_f
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

    # WaveSchedules::scheduleToAnnounce(schedule)
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
        if schedule['@'] == 'project' then
            return "project (#{schedule['hours-per-week']} hours/week)"
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

    # WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule)
    def self.scheduleOfTypeDateIsInTheFuture(schedule)
        schedule['date'] > DateTime.new.to_date.to_s
    end

    # WaveSchedules::cycleSchedule(schedule)
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

    # WaveSchedules::traceToRealInUnitInterval(trace)
    def self.traceToRealInUnitInterval(trace)
        ( '0.'+trace.gsub(/[^\d]/, '') ).to_f
    end

    # WaveSchedules::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.000001*WaveSchedules::traceToRealInUnitInterval(trace)
    end

    # WaveSchedules::scheduleToMetric(schedule)
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
            unixtime = schedule['unixtime'] ? schedule['unixtime'] : Time.new.to_i
            return 0.850 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'today' then
            return 0.7 - 0.01*Math.exp( -0.1*(Time.new.to_i-schedule['unixtime']).to_f/86400 )
        end
        if schedule['@'] == 'sticky' then # shows up once a day
            return 0.7 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'ondate' then
            if WaveSchedules::scheduleOfTypeDateIsInTheFuture(schedule) then
                return 0
            else
                return 0.70 + WaveSchedules::scheduleUtils_distanceBetweenTwoDatesInDays(schedule['date'], Time.new.to_s[0,10]).to_f/1000 + WaveSchedules::traceToMetricShift(schedule['uuid'])
            end
        end

        # Projects

        if schedule['@'] == 'project' then
            return DRbObject.new(nil, "druby://:10423").metric(schedule['uuid'], schedule['hours-per-week'], 0.3, 2.2)
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.7 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.7 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.7 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.7 + WaveSchedules::traceToMetricShift(schedule['uuid'])
        end
        1
    end
end

class WaveDevOps

    # WaveDevOps::today()
    def self.today()
        DateTime.now.to_date.to_s
    end

    # WaveDevOps::getArchiveSizeInMegaBytes()
    def self.getArchiveSizeInMegaBytes()
        LucilleCore::locationRecursiveSize("#{DATABANK_WAVE_FOLDER_PATH}/01-OpsLine-Archives").to_f/(1024*1024)
    end

    # WaveDevOps::getFirstDiveFirstLocationAtLocation(location)
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

    # WaveDevOps::archivesGarbageCollection(verbose)
    def self.archivesGarbageCollection(verbose)
        currentsize = WaveDevOps::getArchiveSizeInMegaBytes()
        while currentsize > 1024 do # Gigabytes of Archives
            location = WaveDevOps::getFirstDiveFirstLocationAtLocation("#{DATABANK_WAVE_FOLDER_PATH}/01-OpsLine-Archives")
            break if location == "#{DATABANK_WAVE_FOLDER_PATH}/01-OpsLine-Archives"
            currentsize = currentsize - (LucilleCore::locationRecursiveSize(location).to_f/(1024*1024))
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
        end
    end
end

class WaveInterface

    # WaveInterface::getCatalystObjects()
    def self.getCatalystObjects()
        WaveTimelineUtils::getCatalystObjects()
    end

    # WaveInterface::interpreter(object, command)
    def self.interpreter(object, command)

        if command.include?(";") then
            command
                .split(";")
                .map{|c| c.strip}
                .each{|c|
                    WaveInterface::interpreter(object, c)
                }
            return
        end

        xobject1 = WaveInterface::getCatalystObjects().select{|object| object['uuid']==command }.first
        if xobject1 then
            puts xobject1['announce']
            puts xobject1['commands'].join(", ").red
            print "---> "
            command = STDIN.gets().strip
            WaveInterface::interpreter(xobject1,command)
            return
        end      

        # ------------------------------------------
        # 

        schedule = object['schedule']
        objectuuid = object['uuid']      

        if command[0, 1] == '+' then
            code = command.strip
            datetime = LucilleCore::datetimeSpecification2232ToDatetime(code)
            schedule = object['schedule']
            schedule["do-not-show-until-datetime"] = datetime
            schedule.delete("metric")
            #puts JSON.pretty_generate(schedule)
            WaveTimelineUtils::writeScheduleToDisk(object['uuid'],schedule)
            return
        end 

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
            return
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

            return
        end

        if command=='recast' then
            schedule = object['schedule']
            objectuuid = object['uuid']
            schedule = WaveTimelineUtils::makeNewSchedule()
            WaveTimelineUtils::writeScheduleToDisk(objectuuid, schedule)
            return
        end

        if command=='folder' then
            location = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            puts "Opening folder #{location}"
            system("open '#{location}'")
            return
        end

        if command=='destroy' then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Do you want to destroy this item ? : ") then
                WaveTimelineUtils::archiveWaveItems(objectuuid)                       
            end
            return
        end

        if command=='>todolist' then
            listname = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("listname: ", ProjectsCore::getProjectsNames(),lambda{ |name| name })
            xsource = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(objectuuid)
            xtarget = "#{TODOLISTS_FOLDERPATH}/#{listname}/#{LucilleCore::timeStringL22()}"
            FileUtils.mkpath(xtarget)
            FileUtils.cp_r(xsource,xtarget)

            # Removing wave files.
            Dir.entries(xtarget)
                .select{|filename| filename.start_with?('catalyst-') or filename.start_with?('wave-') }
                .map{|filename| "#{xtarget}/#{filename}" }
                .each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }

            puts "Item has been copied as todolist item"
            WaveTimelineUtils::archiveWaveItems(objectuuid)
            puts "Item has been wave archived"            
            return
        end

        if command=='>lib' then
            puts "I am copying the wave folder to the Desktop and will rename it to a new atlas reference"

            # Selection of the new atlas reference
            atlasreference = "atlas-#{SecureRandom.hex(8)}"

            # Copying the wave folder to the Desktop                    
            sourcelocation = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNullUseTheForce(objectuuid)
            staginglocation = "/Users/pascal/Desktop/#{atlasreference}"
            LucilleCore::copyFileSystemLocation(sourcelocation, staginglocation)

            # Removing wave files.
            Dir.entries(staginglocation)
                .select{|filename| filename.start_with?('catalyst-') or filename.start_with?('wave-') }
                .map{|filename| "#{staginglocation}/#{filename}" }
                .each{|filepath| LucilleCore::removeFileSystemLocation(filepath) }

            puts "Done. I am now moving you to the Librarian's user interface"

            system("librarian the-atlas-reference-general-loop #{atlasreference}")

            puts "Done. I am now moving the item to the librarian timeline"
            librariantargetfolder = `librarian make-parent-folder-for-new-item`.strip
            LucilleCore::copyFileSystemLocation(staginglocation, librariantargetfolder)
            LucilleCore::removeFileSystemLocation(staginglocation)

            puts "Archiving the Wave item"
            WaveTimelineUtils::archiveWaveItems(objectuuid) 
   
            return
        end

        if command=='start' then
            DRbObject.new(nil, "druby://:10423").start(schedule['uuid'])
            return
        end 

        if command=='stop' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(schedule['uuid'])
            return
        end  
    end
end



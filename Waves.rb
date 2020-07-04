
# require_relative "Waves.rb"

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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "Common.rb"

require_relative "DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require_relative "Bosons.rb"
require_relative "NyxGenericObjectInterface.rb"
require_relative "NyxObjects.rb"

# ----------------------------------------------------------------------

class Waves

    # Waves::traceToRealInUnitInterval(trace)
    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # Waves::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*Waves::traceToRealInUnitInterval(trace)
    end

    # Waves::isLucille18()
    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end

    # Waves::makeScheduleObjectInteractivelyOrNull()
    def self.makeScheduleObjectInteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntitiesOrNull("schedule type: ", scheduleTypes, lambda{|entity| entity })

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

    # Waves::unixtimeAtComingMidnight()
    def self.unixtimeAtComingMidnight()
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00").to_time.to_i
    end

    # Waves::scheduleToDoNotShowUnixtime(uuid, schedule)
    def self.scheduleToDoNotShowUnixtime(uuid, schedule)
        if schedule['@'] == 'sticky' then
            return Waves::unixtimeAtComingMidnight() + 6*3600
        end
        if schedule['@'] == 'every-n-hours' then
            return Time.new.to_i+3600*schedule['repeat-value'].to_f
        end
        if schedule['@'] == 'every-n-days' then
            return Time.new.to_i+86400*schedule['repeat-value'].to_f
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != schedule['repeat-value'] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            mapping = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday]!=schedule['repeat-value'] do
                cursor = cursor + 3600
            end
            return cursor
        end
    end

    # Waves::scheduleToMetric(object, schedule)
    def self.scheduleToMetric(object, schedule)
        return 0 if !DoNotShowUntil::isVisible(object["uuid"])
        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? ( 0.82 + Waves::traceToMetricShift(schedule["uuid"]) ) : 0
        end
        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.80 + Waves::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.80 + Waves::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78 + Waves::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78 + Waves::traceToMetricShift(schedule["uuid"])
        end
        1
    end

    # Waves::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # Waves::announce(text, schedule)
    def self.announce(text, schedule)
        "[#{Waves::scheduleToAnnounce(schedule)}] #{Waves::extractFirstLineFromText(text)}"
    end

    # Waves::scheduleToAnnounce(schedule)
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

    # Waves::makeCatalystObject(wave)
    def self.makeCatalystObject(wave)
        uuid = wave["uuid"]
        schedule = wave["schedule"]
        announce = Waves::announce(wave["description"], schedule)
        object = {}
        object['uuid'] = uuid
        object["body"] = "[wave] " + announce
        object["metric"] = Waves::scheduleToMetric(wave, schedule)
        object["commands"] = ["done"]
        object["execute"] = lambda { |input| 
            if input == ".." then
                Waves::openAndRunProcedure(wave)
                return
            end
            if input == "done" then
                Waves::performDone(wave)
                return
            end
            Waves::waveDive(wave)
        }
        object['schedule'] = schedule
        object["x-wave"] = wave
        object
    end

    # Waves::performDone(wave)
    def self.performDone(wave)
        unixtime = Waves::scheduleToDoNotShowUnixtime(wave["uuid"], wave['schedule'])
        DoNotShowUntil::setUnixtime(wave["uuid"], unixtime)
    end

    # Waves::commitToDisk(wave)
    def self.commitToDisk(wave)
        NyxObjects::put(wave)
    end

    # Waves::issueWave(uuid, description, schedule)
    def self.issueWave(uuid, description, schedule)
        wave = {
            "uuid"             => uuid,
            "nyxNxSet"         => "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "schedule"         => schedule
        }
        Waves::commitToDisk(wave)
        wave
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        schedule = Waves::makeScheduleObjectInteractivelyOrNull()
        return nil if schedule.nil?
        Waves::issueWave(LucilleCore::timeStringL22(), line, schedule)
    end

    # Waves::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # Waves::waves()
    def self.waves()
        NyxObjects::getSet("7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4")
    end

    # Waves::waveToString(wave)
    def self.waveToString(wave)
        "[wave] #{wave["description"]}"
    end

    # Waves::catalystObjects()
    def self.catalystObjects()
        Waves::waves()
            .map{|obj| Waves::makeCatalystObject(obj) }
    end

    # Waves::openItem(wave)
    def self.openItem(wave)
        text = wave["description"]
        puts text
        if text.lines.to_a.size == 1 and text.start_with?("http") then
            url = text
            if Waves::isLucille18() then
                system("open '#{url}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{url}'")
            end
            return
        end
        if text.lines.to_a.size > 1 then
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # Waves::openAndRunProcedure(wave)
    def self.openAndRunProcedure(wave)
        Waves::openItem(wave)
        if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
            Waves::performDone(wave)
        end
    end

    # Waves::waveDive(wave)
    def self.waveDive(wave)
        loop {

            wave = Waves::getOrNull(wave["uuid"])
            return if wave.nil?

            CatalystCommon::horizontalRule(false)

            puts Waves::waveToString(wave)
            puts "uuid: #{wave["uuid"]}"

            unixtime = DoNotShowUntil::getUnixtimeOrNull(wave["uuid"])
            if unixtime then
                puts "DoNotShowUntil: #{Time.at(unixtime).to_s}"
            end

            menuitems = LCoreMenuItemsNX1.new()

            CatalystCommon::horizontalRule(true)

            menuitems.item(
                "start",
                lambda {
                    Waves::openItem(wave)
                    if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                        Waves::performDone(wave)
                    end
                }
            )

            menuitems.item(
                "open",
                lambda { Waves::openItem(wave) }
            )

            menuitems.item(
                "done",
                lambda { Waves::performDone(wave) }
            )

            menuitems.item(
                "description",
                lambda { 
                    description = CatalystCommon::editTextUsingTextmate(wave["description"])
                    return if description.nil?
                    wave["description"] = description
                    Waves::commitToDisk(wave)
                }
            )

            menuitems.item(
                "recast",
                lambda { 
                    schedule = Waves::makeScheduleObjectInteractivelyOrNull()
                    return if schedule.nil?
                    wave["schedule"] = schedule
                    Waves::commitToDisk(wave)
                }
            )

            menuitems.item(
                "destroy",
                lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                        NyxObjects::destroy(wave["uuid"])
                    end
                }
            )

            CatalystCommon::horizontalRule(true)

            status = menuitems.prompt()
            break if !status

        }
    end

    # Waves::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Waves::waves()
            .select{|wave|
                wave["description"].downcase.include?(pattern.downcase)
            }
            .map{|wave|
                {
                    "description"   => "[wave] #{wave["description"]}",
                    "referencetime" => wave["creationUnixtime"],
                    "dive"          => lambda { Waves::waveDive(wave) }
                }
            }
    end

    # Waves::main()
    def self.main()
        loop {
            puts "Waves 🌊"
            options = [
                "new wave",
                "waves dive"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "new wave" then
                Waves::issueNewWaveInteractivelyOrNull()
            end
            if option == "waves dive" then
                obj = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", Waves::waves(), lambda {|wave| Waves::waveToString(wave) })
                next if obj.nil?
                ops = ["edit description", "recast"]
                op = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ops)
                next if op.nil?
                if op == "edit description" then
                    obj["description"] = CatalystCommon::editTextUsingTextmate(obj["description"])
                    Waves::commitToDisk(obj)
                end
                if op == "recast" then
                    schedule = Waves::makeScheduleObjectInteractivelyOrNull()
                    next if schedule.nil?
                    obj["schedule"] = schedule
                    Waves::commitToDisk(obj)
                end
            end
        }
    end
end





# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Waves/Waves.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

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
        object["application"] = "Waves"
        object["body"] = "[wave] "+announce
        object["metric"] = Waves::scheduleToMetric(wave, schedule)
        object['schedule'] = schedule
        object["execute"] = lambda { Waves::waveDive(wave) }
        object["x-wave"] = wave
        object
    end

    # Waves::performDone2(obj)
    def self.performDone2(obj)
        unixtime = Waves::scheduleToDoNotShowUnixtime(obj["uuid"], obj['schedule'])
        DoNotShowUntil::setUnixtime(obj["uuid"], unixtime)
    end

    # Waves::issueWaves(uuid, description, schedule)
    def self.issueWaves(uuid, description, schedule)
        obj = {
            "uuid"             => uuid,
            "nyxType"          => "wave-12ed27da-b5e4-4e6e-940f-2c84071cca58",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "schedule"         => schedule
        }
        NyxIO::commitToDisk(obj)
        obj
    end

    # Waves::waves()
    def self.waves()
        NyxIO::objects("wave-12ed27da-b5e4-4e6e-940f-2c84071cca58")
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

    # Waves::openProcedure(wave)
    def self.openProcedure(wave)
        Waves::openItem(wave)
        if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
            Waves::performDone2(wave)
        end
    end

    # Waves::waveDive(wave)
    def self.waveDive(wave)
        puts Waves::waveToString(wave).green
        uuid = wave["uuid"]
        options = ['start', 'open', 'done', 'recast', 'description', 'destroy']
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        if option == 'start' then
            Waves::openItem(wave)
            if LucilleCore::askQuestionAnswerAsBoolean("-> done ? ", true) then
                Waves::performDone2(wave)
            end
            return
        end
        if option == 'open' then
            Waves::openProcedure(wave)
            return
        end
        if option == 'done' then
            Waves::performDone2(wave)
            return
        end
        if option == 'recast' then
            schedule = Waves::makeScheduleObjectInteractivelyOrNull()
            return if schedule.nil?
            wave["schedule"] = schedule
            NyxIO::commitToDisk(wave)
            return
        end
        if option == 'description' then
            wave["description"] = CatalystCommon::editTextUsingTextmate(wave["description"])
            NyxIO::commitToDisk(wave)
            return
        end
        if option == 'destroy' then
            if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item ? : ") then
                NyxIO::destroy(wave["uuid"])
                return
            end
            return
        end
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
end




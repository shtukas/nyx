
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

# ----------------------------------------------------------------------
=begin

(zeta file)
    uuid     : String
    schedule : String # Serialised JSON
    text     : string # Possibly multi lines

(schedule) 

{
    "uuid"      => SecureRandom.hex,
    "@"         => "sticky",
    "from-hour" => Integer
}

{
    "uuid" => SecureRandom.hex,
    "@"    => (repeat type),
    "repeat-value" => value
}

(repeat type):
    - every-n-hours               -> value: Float
    - every-n-days                -> value: Float
    - every-this-day-of-the-week  -> value: 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    - every-this-day-of-the-month -> value: String Length:2

=end

# ----------------------------------------------------------------------

class NSXWaveUtils

    # NSXWaveUtils::waveFolderPath()
    def self.waveFolderPath()
        "#{CatalystCommon::catalystFolderpath()}/Wave"
    end

    # NSXWaveUtils::makeScheduleObjectInteractivelyOrNull()
    def self.makeScheduleObjectInteractivelyOrNull()

        scheduleTypes = ['sticky', 'date', 'repeat']
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

    # NSXWaveUtils::unixtimeAtComingMidnight()
    def self.unixtimeAtComingMidnight()
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00").to_time.to_i
    end

    # NSXWaveUtils::scheduleToDoNotShowUnixtime(uuid, schedule)
    def self.scheduleToDoNotShowUnixtime(uuid, schedule)
        if schedule['@'] == 'sticky' then
            return NSXWaveUtils::unixtimeAtComingMidnight() + 6*3600
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

    # NSXWaveUtils::scheduleToMetric(schedule)
    def self.scheduleToMetric(schedule)

        # One Offs

        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? ( 0.82 + NSXMiscUtils::traceToMetricShift(schedule["uuid"]) ) : 0
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

    # NSXWaveUtils::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # NSXWaveUtils::announce(text, schedule)
    def self.announce(text, schedule)
        "[#{NSXWaveUtils::scheduleToAnnounce(schedule)}] #{NSXWaveUtils::extractFirstLineFromText(text)}"
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

    # NSXWaveUtils::defaultCommand(announce)
    def self.defaultCommand(announce)
        "open"
    end

    # NSXWaveUtils::claimToCatalystObject(claim)
    def self.claimToCatalystObject(claim)
        uuid = claim["uuid"]
        schedule = claim["schedule"]
        announce = NSXWaveUtils::announce(claim["description"], schedule)
        contentItem = {
            "type" => "line",
            "line" => "💫 "+announce
        }
        object = {}
        object['uuid'] = uuid
        object["contentItem"] = contentItem
        object["metric"] = NSXWaveUtils::scheduleToMetric(schedule)
        object["commands"] = ["open", "edit", "done", "description", "recast", "destroy"]
        object["defaultCommand"] = NSXWaveUtils::defaultCommand(announce)
        object['schedule'] = schedule
        object["shell-redirects"] = {
            "open"        => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing open '#{uuid}'",
            "done"        => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing done '#{uuid}'",
            "description" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing description '#{uuid}'",
            "recast"      => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing recast '#{uuid}'",
            "destroy"     => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing destroy '#{uuid}'"
        }
        object["x-interface:isWave"] = true
        object
    end

    # NSXWaveUtils::performDone2(claim)
    def self.performDone2(claim)
        unixtime = NSXWaveUtils::scheduleToDoNotShowUnixtime(claim["uuid"], claim['schedule'])
        DoNotShowUntil::setUnixtime(claim["uuid"], unixtime)
    end

    # NSXWaveUtils::getCatalystObjects()
    def self.getCatalystObjects()
        WaveNextGen::claims()
            .map{|claim| NSXWaveUtils::claimToCatalystObject(claim) }
    end
end
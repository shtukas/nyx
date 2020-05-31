
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

# ----------------------------------------------------------------------

class Wave

    # Wave::traceToRealInUnitInterval(trace)
    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # Wave::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*Wave::traceToRealInUnitInterval(trace)
    end

    # Wave::isLucille18()
    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end

    # Wave::pathToClaims()
    def self.pathToClaims()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Wave/Claims"
    end

    # Wave::waveFolderPath()
    def self.waveFolderPath()
        "#{CatalystCommon::catalystFolderpath()}/Wave"
    end

    # Wave::makeScheduleObjectInteractivelyOrNull()
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

    # Wave::unixtimeAtComingMidnight()
    def self.unixtimeAtComingMidnight()
        DateTime.parse("#{(DateTime.now.to_date+1).to_s} 00:00:00").to_time.to_i
    end

    # Wave::scheduleToDoNotShowUnixtime(uuid, schedule)
    def self.scheduleToDoNotShowUnixtime(uuid, schedule)
        if schedule['@'] == 'sticky' then
            return Wave::unixtimeAtComingMidnight() + 6*3600
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

    # Wave::scheduleToMetric(schedule)
    def self.scheduleToMetric(schedule)

        # One Offs

        if schedule['@'] == 'sticky' then # shows up once a day
            # Backward compatibility
            if schedule['from-hour'].nil? then
                schedule['from-hour'] = 6
            end
            return Time.new.hour >= schedule['from-hour'] ? ( 0.82 + Wave::traceToMetricShift(schedule["uuid"]) ) : 0
        end

        # Repeats

        if schedule['@'] == 'every-this-day-of-the-month' then
            return 0.80 + Wave::traceToMetricShift(schedule["uuid"])
        end

        if schedule['@'] == 'every-this-day-of-the-week' then
            return 0.80 + Wave::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-hours' then
            return 0.78 + Wave::traceToMetricShift(schedule["uuid"])
        end
        if schedule['@'] == 'every-n-days' then
            return 0.78 + Wave::traceToMetricShift(schedule["uuid"])
        end
        1
    end

    # Wave::extractFirstLineFromText(text)
    def self.extractFirstLineFromText(text)
        return "" if text.size==0
        text.lines.first
    end

    # Wave::announce(text, schedule)
    def self.announce(text, schedule)
        "[#{Wave::scheduleToAnnounce(schedule)}] #{Wave::extractFirstLineFromText(text)}"
    end

    # Wave::scheduleToAnnounce(schedule)
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

    # Wave::defaultCommand(announce)
    def self.defaultCommand(announce)
        "start"
    end

    # Wave::makeCatalystObject(obj)
    def self.makeCatalystObject(obj)
        uuid = obj["uuid"]
        schedule = obj["schedule"]
        announce = Wave::announce(obj["description"], schedule)
        contentItem = {
            "type" => "line",
            "line" => "💫 "+announce
        }
        object = {}
        object['uuid'] = uuid
        object["application"] = "Wave"
        object["contentItem"] = contentItem
        object["metric"] = Wave::scheduleToMetric(schedule)
        object["commands"] = ["start", "open", "edit", "done", "description", "recast", "destroy"]
        object["defaultCommand"] = Wave::defaultCommand(announce)
        object['schedule'] = schedule
        object["shell-redirects"] = {
            "start"       => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing start '#{uuid}'",
            "open"        => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing open '#{uuid}'",
            "done"        => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing done '#{uuid}'",
            "description" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing description '#{uuid}'",
            "recast"      => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing recast '#{uuid}'",
            "destroy"     => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/x-catalyst-objects-processing destroy '#{uuid}'"
        }
        object["x-interface:isWave"] = true
        object
    end

    # Wave::performDone2(obj)
    def self.performDone2(obj)
        unixtime = Wave::scheduleToDoNotShowUnixtime(obj["uuid"], obj['schedule'])
        DoNotShowUntil::setUnixtime(obj["uuid"], unixtime)
    end

    # Wave::getCatalystObjects()
    def self.getCatalystObjects()
        Wave::objects()
            .map{|obj| Wave::makeCatalystObject(obj) }
    end

    # Wave::objects()
    def self.objects()
        Dir.entries(Wave::pathToClaims())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Wave::pathToClaims()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationUnixtime"] <=> c2["creationUnixtime"] }
    end

    # Wave::getObjectByUUIDOrNUll(uuid)
    def self.getObjectByUUIDOrNUll(uuid)
        filepath = "#{Wave::pathToClaims()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Wave::save(obj)
    def self.save(obj)
        uuid = obj["uuid"]
        File.open("#{Wave::pathToClaims()}/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(obj)) }
    end

    # Wave::destroy(obj)
    def self.destroy(obj)
        uuid = obj["uuid"]
        filepath = "#{Wave::pathToClaims()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Wave::makeObject(uuid, description, schedule)
    def self.makeObject(uuid, description, schedule)
        {
            "uuid"             => uuid,
            "nyxType"          => "wave-12ed27da-b5e4-4e6e-940f-2c84071cca58",
            "creationUnixtime" => Time.new.to_f,
            "description"      => description,
            "schedule"         => schedule
        }
    end

    # Wave::issueObject(uuid, description, schedule)
    def self.issueObject(uuid, description, schedule)
        obj = Wave::makeObject(uuid, description, schedule)
        Wave::save(obj)
    end
end




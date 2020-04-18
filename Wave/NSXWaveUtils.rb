
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

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Zeta.rb"
=begin
    Zeta::makeNewFile(filepath)
    Zeta::set(filepath, key, value)
    Zeta::getOrNull(filepath, key)
    Zeta::destroy(filepath, key)
=end

# ----------------------------------------------------------------------
=begin

(zeta file)
    uuid     : String
    schedule : String # Serialised JSON
    text     : string # description, possibly multi lines

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
        "/Users/pascal/Galaxy/DataBank/Catalyst/Wave"
    end

    # NSXWaveUtils::makeScheduleObjectInteractively()
    def self.makeScheduleObjectInteractively()

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

    # NSXWaveUtils::catalystUUIDToItemFilepathOrNull(uuid)
    def self.catalystUUIDToItemFilepathOrNull(uuid)
        filepath = "#{NSXWaveUtils::waveFolderPath()}/Items/#{uuid}.zeta"
        return nil if !File.exists?(filepath)
        filepath
    end

    # NSXWaveUtils::catalystUUIDsEnumerator()
    def self.catalystUUIDsEnumerator()
        Enumerator.new do |uuids|
            Find.find("#{NSXWaveUtils::waveFolderPath()}/Items") do |path|
                next if !File.file?(path)
                next if File.basename(path)[-5, 5] != '.zeta'
                uuids << File.basename(path)[0, File.basename(path).size-5]
            end
        end
    end

    # NSXWaveUtils::writeScheduleToZetaFile(uuid, schedule)
    def self.writeScheduleToZetaFile(uuid, schedule)
        filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(uuid)
        return if filepath.nil?
        Zeta::set(filepath, "schedule", JSON.generate(schedule))
    end

    # NSXWaveUtils::readScheduleFromWaveItemOrNull(uuid)
    def self.readScheduleFromWaveItemOrNull(uuid)
        filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(uuid)
        return nil if filepath.nil?
        schedule = Zeta::getOrNull(filepath, "schedule")
        return nil if schedule.nil?
        JSON.parse(schedule)
    end

    # NSXWaveUtils::makeNewSchedule()
    def self.makeNewSchedule()
        NSXWaveUtils::makeScheduleObjectInteractively()
    end

    # NSXWaveUtils::sendItemToBin(uuid)
    def self.sendItemToBin(uuid)
        return if uuid.nil?
        filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(uuid)
        return nil if filepath.nil?
        NSXMiscUtils::moveLocationToCatalystBin(filepath)
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

    # NSXWaveUtils::makeCatalystObjectOrNull(objectuuid)
    def self.makeCatalystObjectOrNull(objectuuid)
        filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(objectuuid)
        return nil if filepath.nil?
        schedule = NSXWaveUtils::readScheduleFromWaveItemOrNull(objectuuid)
        text = Zeta::getOrNull(filepath, "text") || "[default description]"
        announce = NSXWaveUtils::announce(text, schedule)
        contentItem = {
            "type" => "line",
            "line" => announce
        }
        object = {}
        object['uuid'] = objectuuid
        object["contentItem"] = contentItem
        object["metric"] = NSXWaveUtils::scheduleToMetric(schedule)
        object["commands"] = ["open", "done",  "recast", "destroy"]
        object["defaultCommand"] = "open+done"
        object['schedule'] = schedule
        object["shell-redirects"] = {
            "open"     => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/catalyst-objects-processing open '#{objectuuid}'",
            "done"     => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/catalyst-objects-processing done '#{objectuuid}'",
            "recast"   => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/catalyst-objects-processing recast '#{objectuuid}'",
            "destroy"  => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Wave/catalyst-objects-processing destroy '#{objectuuid}'"
        }
        object
    end

    # NSXWaveUtils::getObjectByUUIDOrNull(objectuuid)
    def self.getObjectByUUIDOrNull(objectuuid)
        NSXWaveUtils::getCatalystObjects()
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

    # NSXWaveUtils::setItemDescription(uuid, description)
    def self.setItemDescription(uuid, description)
        filepath = NSXWaveUtils::catalystUUIDToItemFilepathOrNull(uuid)
        return if filepath.nil?
        Zeta::set(filepath, "text", description)
    end

    # NSXWaveUtils::getCatalystObjects()
    def self.getCatalystObjects()
        NSXWaveUtils::catalystUUIDsEnumerator()
            .map{|uuid| NSXWaveUtils::makeCatalystObjectOrNull(uuid) }
    end

end
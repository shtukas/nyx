
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class NSXMiscUtils

    # NSXMiscUtils::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    # NSXMiscUtils::traceToMetricShift(trace)
    def self.traceToMetricShift(trace)
        0.001*NSXMiscUtils::traceToRealInUnitInterval(trace)
    end

    # NSXMiscUtils::isLucille18()
    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"] == "Lucille18"
    end

    # NSXMiscUtils::spawnNewWaveItem(description): String (uuid)
    def self.spawnNewWaveItem(description)
        uuid = NSXMiscUtils::timeStringL22()
        filepath = "#{NSXWaveUtils::waveFolderPath()}/Items/#{uuid}.zeta"
        Zeta::makeNewFile(filepath)
        Zeta::set(filepath, "uuid", uuid)
        schedule = NSXWaveUtils::makeScheduleObjectInteractively()
        Zeta::set(filepath, "schedule", JSON.generate(schedule))
        Zeta::set(filepath, "text", description)
        uuid
    end

    # NSXMiscUtils::moveLocationToCatalystBin(location)
    def self.moveLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        targetFolder = CatalystCommon::newBinArchivesFolderpath()
        FileUtils.mv(location,targetFolder)
    end
end

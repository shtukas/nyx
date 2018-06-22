
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Constants.rb"

# ---------------------------------------------------------------------

# EventsMaker::destroyCatalystObject(uuid)
# EventsMaker::catalystObject(object)
# EventsMaker::doNotShowUntilDateTime(uuid, datetime)
# EventsMaker::fKeyValueStoreSet(key, value)

class EventsMaker
    def self.destroyCatalystObject(uuid)
        {
            "event-type"  => "Catalyst:Destroy-Catalyst-Object:1",
            "event-time"  => Time.new.to_f,
            "object-uuid" => uuid
        }
    end

    def self.catalystObject(object)
        {
            "event-type" => "Catalyst:Catalyst-Object:1",
            "event-time" => Time.new.to_f,
            "object"     => object
        }
    end

    def self.doNotShowUntilDateTime(uuid, datetime)
        {
            "event-type"  => "Catalyst:Metadata:DoNotShowUntilDateTime:1",
            "event-time"  => Time.new.to_f,
            "object-uuid" => uuid,
            "datetime"    => datetime
        }
    end

    def self.fKeyValueStoreSet(key, value)
        {
            "event-type" => "Flock:KeyValueStore:Set:1",
            "event-time" => Time.new.to_f,
            "key"        => key,
            "value"      => value
        }
    end

    def self.fKeyValueStoreDelete(key)
        {
            "event-type" => "Flock:KeyValueStore:Delete:1",
            "event-time" => Time.new.to_f,
            "key"        => key
        }
    end
end

# EventsManager::pathToActiveEventsIndexFolder()
# EventsManager::commitEventToTimeline(event)
# EventsManager::eventsEnumerator()

class EventsManager
    def self.pathToActiveEventsIndexFolder()
        folder1 = "#{CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}"
        FileUtils.mkpath folder1 if !File.exists?(folder1)
        LucilleCore::indexsubfolderpath(folder1)
    end

    def self.commitEventToTimeline(event)
        folderpath = EventsManager::pathToActiveEventsIndexFolder()
        filepath = "#{folderpath}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(event)) }
        EventsTrace::issueTrace()
    end

    def self.eventsEnumerator()
        Enumerator.new do |events|
            Find.find(CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE) do |path|
                if File.directory?(path) then
                    if Dir.entries(path).select{|filename| filename[0,1]!="." }.size==0 then
                        LucilleCore::removeFileSystemLocation(path)
                    end
                    next
                end
                next if File.basename(path)[-5,5] != '.json'
                event = JSON.parse(IO.read(path))
                event[":filepath:"] = path
                events << event
            end
        end
    end
end

# EventsTrace::issueTrace()
# EventsTrace::isConsistent()

class EventsTrace
    @@trace = nil
    # Class used to monitor which instance has done the last commit
    # Cache management
    def self.issueTrace()
        trace = SecureRandom.hex
        File.open("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Events-Trace", "w"){|f| f.write(trace) }
        @@trace = trace
    end
    def self.readTraceFromDisk()
        if !File.exist?("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Events-Trace") then
            EventsTrace::issueTrace()
        end
        IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Events-Trace").strip
    end
    def self.isConsistent()
        # Here we are simply checking that the trace in memory is the same as the trace on disk
        @@trace == EventsTrace::readTraceFromDisk()
    end
end
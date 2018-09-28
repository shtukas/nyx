
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require_relative "Constants.rb"

# ---------------------------------------------------------------------

# EventsMaker::destroyCatalystObject(uuid)
# EventsMaker::catalystObject(object)
# EventsMaker::doNotShowUntilDateTime(uuid, datetime)

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

end

# EventsManager::pathToActiveEventsIndexFolder()
# EventsManager::commitEventToTimeline(event)
# EventsManager::eventsAsTimeOrderedArray()
# EventsManager::filepaths()

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
    end

    def self.eventsAsTimeOrderedArray()
        enum = Enumerator.new do |events|
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
        enum.to_a.sort{|e1,e2| e1["event-time"]<=>e2["event-time"] }
    end
    
    def self.filepaths()
        enum = Enumerator.new do |filepaths|
            Find.find(CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE) do |path|
                next if File.basename(path)[-5,5] != '.json'
                filepaths << path
            end
        end
        enum.to_a
    end
end

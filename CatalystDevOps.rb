
# encoding: UTF-8


# CatalystDevOps::today()
# CatalystDevOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystDevOps::getFilepathAgeInDays(filepath)

# CatalystDevOps::getArchiveTimelineSizeInMegaBytes()
# CatalystDevOps::archivesTimelineGarbageCollectionStandard(): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollection(): Array[String]

# CatalystDevOps::eventsTimelineGarbageCollection()

class CatalystDevOps

    def self.today()
        DateTime.now.to_date.to_s
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
                    CatalystDevOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------
    # Archives

    def self.getArchiveTimelineSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.archivesTimelineGarbageCollectionStandard()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        lines
    end

    def self.archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes)
        lines = []
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        line
    end

    def self.archivesTimelineGarbageCollection()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH
            CatalystDevOps::archivesTimelineGarbageCollectionFast(CatalystDevOps::getArchiveTimelineSizeInMegaBytes())
                .each{|line| lines << line }
        end
        lines
    end

    # -------------------------------------------
    # Events Timeline

    def self.canRemoveEvent(head, tail)
        if head["event-type"] == "Catalyst:Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object"]["uuid"] }
        end
        if head["event-type"] == "Catalyst:Destroy-Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object-uuid"] }
        end
        if head["event-type"] == "Catalyst:Metadata:DoNotShowUntilDateTime:1" then
            return DateTime.parse(head["datetime"]).to_time.to_i < Time.new.to_i
        end
        if head["event-type"] == "Flock:KeyValueStore:Set:1" then
            return tail.any?{|e| e["event-type"]=="Flock:KeyValueStore:Set:1" and e["key"]==head["key"] }
        end
        raise "Don't know how to garbage collect head: \n#{JSON.pretty_generate(head)}"
    end

    def self.eventsTimelineGarbageCollection()
        lines = []
        events = EventsManager::eventsEnumerator().to_a
        while events.size>=2 do
            event = events.shift
            if CatalystDevOps::canRemoveEvent(event, events) then
                eventfilepath = event[":filepath:"]
                lines << eventfilepath
                FileUtils.rm(eventfilepath)
            end
        end
        lines
    end
end
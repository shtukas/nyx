# encoding: UTF-8

class Nx60Queue

    # Nx60Queue::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop/Nx60-Queue"
    end

    # Nx60Queue::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Nx60Queue::repositoryFolderpath())
    end

    # Nx60Queue::getDescriptionOrNull(filepath)
    def self.getDescriptionOrNull(filepath)
        KeyValueStore::getOrNull(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{filepath}")
    end

    # Nx60Queue::setDescription(filepath, description)
    def self.setDescription(filepath, description)
        KeyValueStore::set(nil, "ca23acc1-6596-4e8e-b9e7-714ae3c7b0f8:#{filepath}", description)
    end

    # Nx60Queue::announce(filepath)
    def self.announce(filepath)
        description = Nx60Queue::getDescriptionOrNull(filepath)
        if description then
            "[quee] #{description}"
        else
            "[quee] #{File.basename(filepath)}"
        end
    end

    # Nx60Queue::ensureDescription(filepath)
    def self.ensureDescription(filepath)
        if Nx60Queue::getDescriptionOrNull(filepath).nil? then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            Nx60Queue::setDescription(filepath, description)
        end
    end

    # Nx60Queue::access(filepath)
    def self.access(filepath)
        system("open '#{filepath}'")
        operations = [
            "done",
            "hide for one hour",
            "hide until this evening",
            "hide until tomorrow morning",
            "move to Nx50s"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return if operation.nil?
        if operation == "done" then
            FileUtils.rm(filepath)
        end
        if operation == "hide for one hour" then
            unixtime = Time.new.to_i+3600
            DoNotShowUntil::setUnixtime(filepath, unixtime)
            Nx60Queue::ensureDescription(filepath)
        end
        if operation == "hide until this evening" then
            unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) - 3600*8
            DoNotShowUntil::setUnixtime(filepath, unixtime)
            Nx60Queue::ensureDescription(filepath)
        end
        if operation == "hide until tomorrow morning" then
            unixtime = Utils::unixtimeAtComingMidnightAtGivenTimeZone(Utils::getLocalTimeZone()) + 3600*9
            DoNotShowUntil::setUnixtime(filepath, unixtime)
            Nx60Queue::ensureDescription(filepath)
        end
        if operation == "move to Nx50s" then
            Nx50s::locationToNx50(filepath)
            FileUtils.rm(filepath)
        end
    end

    # Nx60Queue::ns16s()
    def self.ns16s()
        Nx60Queue::filepaths().map{|filepath|
            {
                "uuid"     => filepath,
                "announce" => Nx60Queue::announce(filepath),
                "access"   => lambda { Nx60Queue::access(filepath) },
                "done"     => lambda {}
            }
        }
    end
end

# encoding: UTF-8

class NxTriages

    # NxTriages::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTriage/#{uuid}.json"
    end

    # NxTriages::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTriage")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxTriages::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxTriages::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxTriages::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxTriages::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTriages::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTriages::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
        Ticks::emit()
    end

    # --------------------------------------------------
    # Makers

    # NxTriages::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx113 = Nx113Make::aionpoint(location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTriage",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        NxTriages::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTriages::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(triage) #{item["description"]}#{nx113str}"
    end

    # --------------------------------------------------
    # Operations

    # NxTriages::access(item)
    def self.access(item)
        puts NxTriages::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTriages::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTriages::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTriages::getOrNull(item["uuid"])
    end

    # NxTriages::probe(item)
    def self.probe(item)
        loop {
            actions = ["access", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTriages::access(item)
            end
            if action == "destroy" then
                NxTriages::destroy(item["uuid"])
                PolyActions::garbageCollectionAfterItemDeletion(item)
                return
            end
        }
    end
end

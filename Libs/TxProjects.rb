# encoding: UTF-8

class TxProjects

    # TxProjects::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/TxProject/#{uuid}.json"
    end

    # TxProjects::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TxProject")
            .select{|filepath| filepath[-5, 5] == ".json" }
    end

    # TxProjects::items()
    def self.items()
        TxProjects::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxProjects::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = TxProjects::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxProjects::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = TxProjects::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxProjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = TxProjects::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # TxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39
        }
        TxProjects::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxProjects::toString(item)
    def self.toString(item)
        percentage = 100 * Ax39::completionRatio(item["uuid"], item["ax39"])
        "(project) #{item["description"]} (#{percentage} %)"
    end

    # TxProjects::listingItems()
    def self.listingItems()
        TxProjects::items()
            .select{|item| Ax39::completionRatio(item["uuid"], item["ax39"]) < 1 }
    end

    # --------------------------------------------------
    # Operations

    # TxProjects::start(item)
    def self.start(item)
        puts "TxProjects::start: not implemented yet"
    end

    # TxProjects::stop(item)
    def self.stop(item)
        puts "TxProjects::stop: not implemented yet"
    end

end

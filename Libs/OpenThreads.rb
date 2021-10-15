# encoding: UTF-8

class OpenThreadsPoints

    # --------------------------------------------------
    # IO

    # OpenThreadsPoints::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Items/OpenThreadsPoints"
    end

    # OpenThreadsPoints::commitFloatToDisk(float)
    def self.commitFloatToDisk(float)
        filename = "#{float["uuid"]}.json"
        filepath = "#{OpenThreadsPoints::itemsFolderPath()}/#{filename}"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(float)) }
    end

    # OpenThreadsPoints::items()
    def self.items()
        LucilleCore::locationsAtFolder(OpenThreadsPoints::itemsFolderPath())
            .select{|location| location[-5, 5] == ".json" }
            .map{|location| JSON.parse(IO.read(location)) }
            .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
    end

    # OpenThreadsPoints::getNxFloatByUUIDOrNull(uuid)
    def self.getNxFloatByUUIDOrNull(uuid)
        filename = "#{uuid}.json"
        filepath = "#{OpenThreadsPoints::itemsFolderPath()}/#{filename}"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # OpenThreadsPoints::destroy(item)
    def self.destroy(item)
        filename = "#{item["uuid"]}.json"
        filepath = "#{OpenThreadsPoints::itemsFolderPath()}/#{filename}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Making

    # OpenThreadsPoints::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        uuid = LucilleCore::timeStringL22()

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        unixtime = Time.new.to_f

        coreDataId = CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()

        float = {
          "uuid"        => uuid,
          "unixtime"    => unixtime,
          "description" => description,
          "coreDataId"  => coreDataId,
          "domain"      => "(eva)"
        }

        OpenThreadsPoints::commitFloatToDisk(float)

        float
    end

    # --------------------------------------------------
    # Operations

    # OpenThreadsPoints::toString(item)
    def self.toString(item)
        "[float] #{item["description"]}"
    end

    # OpenThreadsPoints::accessContent(item)
    def self.accessContent(item)
        if item["coreDataId"].nil? then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
            return
        end
        CoreData::accessWithOptionToEdit(item["coreDataId"])
    end

    # --------------------------------------------------

    # OpenThreadsPoints::run(nxfloat)
    def self.run(nxfloat)
        puts OpenThreadsPoints::toString(nxfloat)
        OpenThreadsPoints::accessContent(nxfloat)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{OpenThreadsPoints::toString(nxfloat)}' ? ") then
            OpenThreadsPoints::destroy(nxfloat)
        end
    end

    # OpenThreadsPoints::nx19s()
    def self.nx19s()
        OpenThreadsPoints::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => OpenThreadsPoints::toString(item),
                "lambda"   => lambda { OpenThreadsPoints::run(item) }
            }
        }
    end
end

class OpenThreadsDesktopFolders

    # OpenThreadsDesktopFolders::runFolder(folderpath)
    def self.runFolder(folderpath)
        system("clear")
        puts "(fldr) #{File.basename(folderpath)}".green
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue("> Press [enter] to exit folder visit: ")
    end

    # OpenThreadsDesktopFolders::items(domain)
    def self.items(domain)

        return [] if domain != "(work)" 

        getFolderUnixtime = lambda{|folderpath|
            filepath = "#{folderpath}/.unixtime-784971ed"
            if !File.exists?(filepath) then
                File.open(filepath, "w") {|f| f.puts(Time.new.to_f)}
            end
            IO.read(filepath).strip.to_f
        }

        LucilleCore::locationsAtFolder("/Users/pascal/Desktop/Open Threads")
            .map{|folderpath|
                announce = "[fldr] #{File.basename(folderpath)}"
                {
                    "unixtime"     => getFolderUnixtime.call(folderpath),
                    "announce"     => announce,
                    "run"          => lambda{ OpenThreadsDesktopFolders::runFolder(folderpath) },
                }
            }
    end
end

class OpenThreads

    # OpenThreads::objects(domain)
    def self.objects(domain)

        o1 = OpenThreadsPoints::items()
                .map{|float|
                    {
                        "unixtime" => float["unixtime"],
                        "announce" => OpenThreadsPoints::toString(float).gsub("float", "floa"),
                        "run"      => lambda { OpenThreadsPoints::run(float)}
                    }
                }

        o2 = OpenThreadsDesktopFolders::items(domain)

        (o1+o2).sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        
        #{
        #    "announce"
        #    "run"
        #}
    end

    # OpenThreads::ns19s()
    def self.ns19s()
        OpenThreads::objects(domain).map{|item|
            {
                "uuid"     => SecureRandom.uuid,
                "announce" => item["announce"],
                "lambda"   => lambda { item["run"].call() }
            }
        }
    end
end

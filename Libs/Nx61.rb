# encoding: UTF-8

class Nx61s

    # Nx61s::itemsFolderPath()
    def self.itemsFolderPath()
        "/Users/pascal/Galaxy/Current/Nx61s-Work-Floating-Items"
    end

    # Nx61s::folderpathForUUIDOrNull(uuid)
    def self.folderpathForUUIDOrNull(uuid)
        LucilleCore::locationsAtFolder(Nx61s::itemsFolderPath()).each{|folderpath|
            itemfilepath = "#{folderpath}/.item-6e1aa42b"
            next if !File.exists?(itemfilepath)
            item = JSON.parse(IO.read(itemfilepath))
            return folderpath if item["uuid"] == uuid
        }
        nil
    end

    # Nx61s::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        uuid = item["uuid"]
        folderpath = Nx61s::folderpathForUUIDOrNull(uuid)
        if folderpath.nil? then
            folderpath = "#{Nx61s::itemsFolderPath()}/#{item["description"]}"
            FileUtils.mkdir(folderpath)
            itemfilepath = "#{folderpath}/.item-6e1aa42b"
            File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item))}
        end
        if File.basename(folderpath) != item["description"] then
            f2 = "#{Nx61s::itemsFolderPath()}/#{item["description"]}"
            FileUtils.mv(folderpath, f2)
        end
    end

    # Nx61s::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        folderpath = Nx61s::folderpathForUUIDOrNull(uuid)
        return nil if folderpath.nil?
        itemfilepath = "#{folderpath}/.item-6e1aa42b"
        item = JSON.parse(IO.read(itemfilepath))
        if item["description"] != File.basename(folderpath) then
            item["description"] = File.basename(folderpath)
            File.open("#{folderpath}/.item-6e1aa42b", "w"){|f|  f.puts(JSON.pretty_generate(item))}
        end
        item
    end

    # Nx61s::items()
    def self.items()
        LucilleCore::locationsAtFolder(Nx61s::itemsFolderPath())
            .map{|folderpath|
                itemfilepath = "#{folderpath}/.item-6e1aa42b"
                if !File.exists?(itemfilepath) then
                    item = {
                        "uuid"        => SecureRandom.uuid,
                        "unixtime"    => Time.new.to_f,
                        "description" => File.basename(folderpath),
                        "domain"      => "(work)"
                    }
                    File.open(itemfilepath, "w"){|f| f.puts(JSON.pretty_generate(item))}
                end
                item = JSON.parse(IO.read(itemfilepath))
                if item["description"] != File.basename(folderpath) then
                    item["description"] = File.basename(folderpath)
                    File.open("#{folderpath}/.item-6e1aa42b", "w"){|f|  f.puts(JSON.pretty_generate(item))}
                end
                item
            }
            .sort{|x1, x2|  x1["unixtime"] <=> x2["unixtime"]}
    end

    # Nx61s::destroy(item)
    def self.destroy(item)
        uuid = item["uuid"]
        folderpath = Nx61s::folderpathForUUIDOrNull(uuid)
        return if folderpath.nil?
        if LucilleCore::askQuestionAnswerAsBoolean("remove '#{folderpath}' ? ") then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # --------------------------------------------------
    # Makers

    # Nx61s::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = LucilleCore::timeStringL22()
        unixtime = Time.new.to_f
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end
        item = {
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "domain"      => "(work)"
        }
        Nx61s::commitItemToDisk(item)
        folderpath = Nx61s::folderpathForUUIDOrNull(uuid)
        puts "opening #{folderpath}"
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
        item
    end

    # -------------------------------------
    # Operations

    # Nx61s::toString(item)
    def self.toString(item)
        "[Nx61] #{item["description"]}"
    end

    # Nx61s::accessContent(item)
    def self.accessContent(item)
        uuid = item["uuid"]
        folderpath = Nx61s::folderpathForUUIDOrNull(uuid)
        puts "opening #{folderpath}"
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
    end

    # Nx61s::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Nx61s::toString(item),
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Nx61s::accessContent(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Nx61s::toString(item)}' ? ", true) then
                        Nx61s::destroy(item)
                    end
                end
            },
            "run" => lambda {
                Nx61s::accessContent(item)
            },
            "item" => item
        }
    end

    # Nx61s::ns16s()
    def self.ns16s()
        Nx61s::items()
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| Nx61s::itemToNS16(item) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # Nx61s::nx19s()
    def self.nx19s()
        Nx61s::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Nx61s::toString(item),
                "lambda"   => lambda { Nx61s::accessContent(item) }
            }
        }
    end
end

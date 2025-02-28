
class NxNode28s

    # -----------------------------------------------------------------
    # Disk Encoding/Decoding

    # NxNode28s::nodefiles_filepaths_enumeration()
    def self.nodefiles_filepaths_enumeration()
        root = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/NxNode28s"
        Enumerator.new do |filepaths|
            Find.find(root) do |path|
                if File.basename(path)[-4, 4] == ".txt" then
                    filepaths << path
                end
            end
        end
    end

    # NxNode28s::readUUIDFromFile(filepath)
    def self.readUUIDFromFile(filepath)
        text = IO.read(filepath).strip
        lines = text.lines.map{|line| line.strip }
        ls = lines.select{|line| line.start_with?('uuid:') }
        if ls.size == 0 then
            raise "the file at '#{filepath}' doesn't seem to have a uuid 🤔"
        end
        if ls.size > 1 then
            raise "the file at '#{filepath}' seems to have more than one uuids 🤔"
        end
        line = ls.first
        line[5, line.size].strip
    end

    # NxNode28s::filepathForUUIDOrNull(uuid)
    def self.filepathForUUIDOrNull(uuid)
        filepaths = NxNode28s::nodefiles_filepaths_enumeration().select{|filepath| NxNode28s::readUUIDFromFile(filepath) == uuid }
        if filepaths.size == 0 then
            return nil
        end
        if filepaths.size > 1 then
            puts "found several files for uuid: #{uuid}"
            puts JSON.pretty_generate(filepaths)
            raise "^ 🤔"
        end
        filepaths.first
    end

    # NxNode28s::newFilePath()
    def self.newFilePath()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/NxNode28s/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{CommonUtils::timeStringL22()}.txt"
    end

    # NxNode28s::attributesToNodeFileText(node28)
    def self.attributesToNodeFileText(node28)
        [
            "uuid: #{node28["uuid"]}",
            "mikuType: NxNode28",
            "description: #{node28["description"]}",
            "datetime: #{node28["datetime"]}",
            node28["linkeduuids"].map{|uuid|
                "linkeduuid: #{uuid}"
            },
            node28["notes"].map{|note|
                "note: #{JSON.generate(note)}"
            },
            node28["tags"].map{|tag|
                "tag: #{tag}"
            },
            node28["payloads"].map{|payload|
                "payload: #{JSON.generate(payload)}"
            },
        ]
            .flatten
            .join("\n")
    end

    # -----------------------------------------------------------------
    # Disk Encoding/Decoding

    # NxNode28s::fsckNxNode28(node28)
    def self.fsckNxNode28(node28)
        if node28["uuid"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its uuid"
        end
        if node28["mikuType"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} is missing its mikuType"
        end
        if node28["mikuType"] != 'NxNode28' then
            raise "node28: #{JSON.pretty_generate(node28)} does not have the correct mikuType"
        end
        if node28["description"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a description"
        end
        if node28["datetime"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a datetime"
        end

        if node28["linkeduuids"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a linkeduuids"
        end
        if node28["linkeduuids"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s linkeduuids is not an array"
        end

        # TODO: fsck the notes
        if node28["notes"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a notes"
        end
        if node28["notes"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s notes is not an array"
        end
        node28["notes"].each{|note|
            NxNote::fsck(note)
        }

        # TODO: fsck the tags
        if node28["tags"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a tags"
        end
        if node28["tags"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s tags is not an array"
        end

        # TODO: fsck the payloads
        if node28["payloads"].nil? then
            raise "node28: #{JSON.pretty_generate(node28)} does not have a payloads"
        end
        if node28["payloads"].class.to_s != "Array" then
            raise "node28: #{JSON.pretty_generate(node28)}'s payloads is not an array"
        end
        node28["payloads"].each{|px44|
            uuid = node28["uuid"]
            Px44::fsck(uuid, px44)
        }
    end

    # NxNode28s::commitItemToDisk(node28)
    def self.commitItemToDisk(node28)
        NxNode28s::fsckNxNode28(node28)
        text = NxNode28s::attributesToNodeFileText(node28)
        filepath1 = NxNode28s::filepathForUUIDOrNull(node28["uuid"])
        filepath2 = filepath1 || NxNode28s::newFilePath()
        File.open(filepath2, "w"){|f| f.puts(text) }
    end

    # NxNode28s::fsck()
    def self.fsck()

    end
end

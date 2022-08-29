
# encoding: UTF-8

class DxFile

    # DxFile::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxFile")
    end

    # DxFile::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?
        return nil if !File.file?(location)
        filepath = location

        operator = DxF1Elizabeth.new(uuid, true, true)

        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxFile")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "dottedExtension", dottedExtension)
        DxF1::setAttribute2(uuid, "nhash", nhash)
        DxF1::setAttribute2(uuid, "parts", parts)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7221bfe9-c2f7-4948-a878-e23e161ea728) How did that happen ? 🤨"
        end
        item
    end

    # DxFile::issueNewUsingLocation(filepath)
    def self.issueNewUsingLocation(filepath)
        raise "(error: 7a83d805-8eb7-4e19-a045-27f955fa1b8e) #{filepath}" if !File.exists?(filepath)
        raise "(error: 35f553da-4465-49bd-b393-756c367db176) #{filepath}" if !File.file?(filepath)

        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = File.basename(filepath)

        operator = DxF1Elizabeth.new(uuid, true, true)

        dottedExtension, nhash, parts = PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxFile")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "dottedExtension", dottedExtension)
        DxF1::setAttribute2(uuid, "nhash", nhash)
        DxF1::setAttribute2(uuid, "parts", parts)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7221bfe9-c2f7-4948-a878-e23e161ea728) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxFile::toString(item)
    def self.toString(item)
        "(DxFile) #{item["description"] ? item["description"] : "nhash: #{item["nhash"]}"}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxFile::access(item)
    def self.access(item)
        puts "DxFile: #{item["description"]}"
        dottedExtension = item["dottedExtension"]
        nhash = item["nhash"]
        parts = item["parts"]
        operator = DxF1Elizabeth.new(item["uuid"], true, true)
        filepath = "#{ENV['HOME']}/Desktop/#{nhash}#{dottedExtension}"
        File.open(filepath, "w"){|f|
            parts.each{|nhash|
                blob = operator.getBlobOrNull(nhash)
                raise "(error: 13709695-3dca-493b-be46-62d4ef6cf18f)" if blob.nil?
                f.write(blob)
            }
        }
        system("open '#{filepath}'")
        puts "Item exported at #{filepath}"
        LucilleCore::pressEnterToContinue()
    end

    # DxFile::landing(item, isSearchAndSelect)
    def self.landing(item, isSearchAndSelect)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = TheIndex::getItemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            store = ItemStore.new()

            puts DxFile::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            linkeds  = NetworkLinks::linkedEntities(uuid)

            puts "Linked entities: #{linkeds.size} items".yellow

            if linkeds.size <= 200 then
                linkeds
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .first(200)
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "(... many items, use `navigation` ...)"
            end

            puts "commands: access | iam | <n> | description | datetime | line | text | nx112 | json | link | unlink | network-migration | navigation | upload | return (within search) | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = Landing::landing_old(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                DxFile::access(item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                DxF1::setAttribute2(item["uuid"], "description", description)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            end

            if Interpreting::match("iam", command) then
                puts "TODO"
                exit
            end

            if Interpreting::match("line", command) then
                l1 = NxLines::interactivelyIssueNewLineOrNull()
                next if l1.nil?
                puts JSON.pretty_generate(l1)
                NetworkLinks::link(item["uuid"], l1["uuid"])
                next
            end

            if Interpreting::match("text", command) then
                i2 = DxText::interactivelyIssueNew()
                puts JSON.pretty_generate(i2)
                NetworkLinks::link(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("nx112", command) then
                i2 = Dx::interactivelyCreateNewDxOrNull()
                puts JSON.pretty_generate(i2)
                NetworkLinks::link(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("navigation", command) then
                LinkedNavigation::navigate(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("network-migration", command) then
                NetworkLinks::networkMigration(item)
            end

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("return", command) then
                return item
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    DxF1::deleteObjectLogically(item["uuid"])
                    break
                end
            end
        }
    end
end

# encoding: UTF-8

class Px44

    # Px44::types()
    def self.types()
        ["text", "url", "aion-point", "beacon", "unique string"]
    end

    # Px44::interactivelySelectType()
    def self.interactivelySelectType()
        types = Px44::types()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
    end

    # Px44::interactivelyMakeNewOrNull(owner)
    def self.interactivelyMakeNewOrNull(owner)
        type = Px44::interactivelySelectType()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Px44",
                "owner"    => owner,
                "type"     => "text",
                "text"     => text
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Px44",
                "owner"    => owner,
                "type"     => "url",
                "url"      => url
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return {
                "uuid"      => SecureRandom.uuid,
                "mikuType" => "Px44",
                "owner"    => owner,
                "type"      => "aion-point",
                "nhash"     => AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            }
        end
        if type == "beacon" then

            beaconId = SecureRandom.uuid
            beacon = {
                "type" => "Bx47",
                "id" => beaconId
            }
            beaconFilepath = "#{Config::userHomeDirectory()}/Desktop/#{SecureRandom.hex(4)}.nyx29-beacon.json"
            File.open(beaconFilepath, "w"){|f| f.puts(JSON.pretty_generate(beacon)) }
            puts "I have put the beacon file on the Desktop, please move to destination"
            LucilleCore::pressEnterToContinue()

            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Px44",
                "owner"    => owner,
                "type"     => "beacon",
                "id"       => beaconId
            }
        end
        if type == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return {
                "uuid"         => SecureRandom.uuid,
                "mikuType" => "Px44",
                "owner"    => owner,
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) Px44 type: #{type}"
    end

    # Px44::interactivelyIssueNewOrNull(owner)
    def self.interactivelyIssueNewOrNull(owner)
        item = Px44::interactivelyMakeNewOrNull(owner)
        return if item.nil?
        Items::commitItem(item)
    end

    # Px44::toString(px44)
    def self.toString(px44)
        "(payload: #{px44["uuid"]}, #{px44["type"]})"
    end

    # Px44::fsck(px44)
    def self.fsck(px44)
        if px44["mikuType"].nil? then
            raise "px44: #{JSON.pretty_generate(px44)} does not have a mikuType"
        end
        if px44["uuid"].nil? then
            raise "px44: #{JSON.pretty_generate(px44)} does not have a uuid"
        end
        if px44["type"].nil? then
            raise "px44: #{JSON.pretty_generate(px44)} does not have a type"
        end
        if px44["type"] == "text" then
            if px44["text"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a text"
            end
            return
        end
        if px44["type"] == "url" then
            if px44["url"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a url"
            end
            return
        end
        if px44["type"] == "aion-point" then
            if px44["nhash"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a nhash"
            end
            nhash = px44["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
            return
        end
        if px44["type"] == "beacon" then
            if px44["id"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a id"
            end
            return
        end
        if px44["type"] == "unique-string" then
            if px44["uniquestring"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a uniquestring"
            end
            return
        end
    end

    # Px44::px44sForNode(nodeuuid)
    def self.px44sForNode(nodeuuid) # -> Arrar[Px44]
        Items::getMikuType("Px44").select{|item| item["owner"] == nodeuuid }
    end

    # Px44::access(px44)
    def self.access(px44)
        # The uuid is used to know where to find the datablobs in case of an aion-point

        return if px44.nil?
        if px44["type"] == "text" then
            puts "--------------------------------------------------------------"
            puts px44["text"]
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if px44["type"] == "url" then
            url = px44["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if px44["type"] == "aion-point" then
            nhash = px44["nhash"]
            puts "accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "#{exportId}-aion-point"
            exportFolderpath = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{exportFoldername}"
            FileUtils.mkpath(exportFolderpath)
            AionCore::exportHashAtFolder(Elizabeth.new(), nhash, exportFolderpath)
            system("open '#{exportFolderpath}'")
            LucilleCore::pressEnterToContinue()
            return
        end
        if px44["type"] == "beacon" then
            searchX = lambda{|id|
                roots = [
                    "#{Config::userHomeDirectory()}/Galaxy"
                ]
                Galaxy::locationEnumerator(roots).each{|filepath|
                    if File.basename(filepath)[-18, 18] == ".nyx29-beacon.json" then
                        if JSON.parse(IO.read(filepath))["id"] == id then
                            return filepath
                        end
                    end
                }
                nil
            }
            id = px44["id"]
            filepath = searchX.call(id)
            if filepath then
                puts "nyx fs beacon located: #{filepath}"
                folderpath = File.dirname(filepath)
                system("open '#{folderpath}'")
                LucilleCore::pressEnterToContinue()
                return
            else
                puts "I could not locate beacon id: #{id} within Galaxy"
                LucilleCore::pressEnterToContinue()
                return
            end
        end
        if px44["type"] == "unique-string" then
            uniquestring = px44["uniquestring"]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "(error: ee2b7a4b-a34a-4ea6-9f3e-c41be1d1a69c) Px44: #{px44}"
    end

    # Px44::programPx44(px44)
    def self.programPx44(px44)
        loop {
            options = ["access", "destroy"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            return if option.nil?
            if option == "access" then
                Px44::access(px44)
            end
            if option == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{Px44::toString(px44)}") then
                    Items::deleteItem(px44["uuid"])
                    return
                end
            end
        }
        nil
    end

    # Px44::programNodePx44s(node)
    def self.programNodePx44s(node)
        loop {
            puts "node: #{Nx27::toString(node).green}"
            store = ListingStore.new()
            Px44::px44sForNode(node["uuid"]).each{|px44|
                store.register(px44)
                puts "   - [#{store.prefixString()}] #{Px44::toString(px44)}"
            }
            puts "new"
            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""
            if CommonUtils::isInteger(command) then
                indx = command.to_i
                px44 = store.get(indx)
                next if px44.nil?
                Px44::programPx44(px44)
                next
            end
            if command == "new" then
                Px44::interactivelyIssueNewOrNull(node["uuid"])
            end
        }
    end

end

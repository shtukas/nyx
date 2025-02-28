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

    # Px44::interactivelyMakeNewOrNull(uuid)
    def self.interactivelyMakeNewOrNull(uuid)
        type = Px44::interactivelySelectType()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "mikuType" => "Px44",
                "type"     => "text",
                "text"     => text
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "mikuType" => "Px44",
                "type"     => "url",
                "url"      => url
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            filename = "#{SecureRandom.hex}.blade"
            filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Blades/#{filename}"
            Blades::initiate(filepath, uuid)
            return {
                "mikuType"  => "Px44",
                "type"      => "aion-point",
                "bladename" => filename,
                "nhash"     => AionCore::commitLocationReturnHash(ElizabethBlade.new(filepath), location)
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
                "mikuType" => "Px44",
                "type"     => "beacon",
                "id"       => beaconId
            }
        end
        if type == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return {
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) Px44 type: #{type}"
    end

    # Px44::toString(px44)
    def self.toString(px44)
        "(payload: #{px44["type"]})"
    end

    # Px44::access(uuid, px44)
    def self.access(uuid, px44)
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
            bladename = px44["bladename"]
            bladefilepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Blades/#{bladename}"
            puts "accessing aion point: #{nhash}"
            exportId = SecureRandom.hex(4)
            exportFoldername = "#{exportId}-aion-point"
            exportFolderpath = "#{ENV['HOME']}/x-space/xcache-v1-days/#{Time.new.to_s[0, 10]}/#{exportFoldername}"
            FileUtils.mkpath(exportFolderpath)
            AionCore::exportHashAtFolder(ElizabethBlade.new(bladefilepath), nhash, exportFolderpath)
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

    # Px44::fsck(uuid, px44)
    def self.fsck(uuid, px44)
        if px44["mikuType"].nil? then
            raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a mikuType"
        end
        if px44["mikuType"] != 'Px44' then
            raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have the correct mikuType"
        end
        if px44["type"].nil? then
            raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a type"
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
            if px44["bladename"].nil? then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} does not have a bladename"
            end
            bladename = px44["bladename"]
            bladefilepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Blades/#{bladename}"
            if !File.exist?(bladefilepath) then
                raise "uuid: #{uuid}, px44: #{JSON.pretty_generate(px44)} cannot find blade file: #{bladefilepath}"
            end
            AionFsck::structureCheckAionHashRaiseErrorIfAny(ElizabethBlade.new(bladefilepath), nhash)
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
end

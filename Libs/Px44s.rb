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

    # Px44::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = Px44::interactivelySelectType()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "type" => "text",
                "text" => text
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "type" => "url",
                "url"  => url
            }
        end
        if type == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return {
                "type" => "aion-point",
                "nhash" => AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            }
        end
        if type == "beacon" then

            beaconId = SecureRandom.uuid
            beacon = {
                "id" => beaconId
            }
            beaconFilepath = "#{Config::userHomeDirectory()}/Desktop/#{SecureRandom.hex(4)}.nyx29-beacon.json"
            File.open(beaconFilepath, "w"){|f| f.puts(JSON.pretty_generate(beacon)) }
            puts "I have put the beacon file on the Desktop, please move to destination"
            LucilleCore::pressEnterToContinue()

            return {
                "type" => "beacon",
                "id"   => beaconId
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

    # Px44::toStringSuffix(px44)
    def self.toStringSuffix(px44)
        return "" if px44.nil?
        " (#{px44["type"]})"
    end

    # Px44::access(px44)
    def self.access(px44)
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

    # Px44::fsck(px44)
    def self.fsck(px44)
        return if px44.nil?
        if px44["type"] == "text" then
            return
        end
        if px44["type"] == "url" then
            return
        end
        if px44["type"] == "aion-point" then
            nhash = px44["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
            return
        end
        if px44["type"] == "beacon" then
            return
        end
        if px44["type"] == "unique-string" then
            return
        end
        raise "(error: 4456ba26-1439-47f4-871b-f3c00e384438) Px44: #{px44}"
    end
end

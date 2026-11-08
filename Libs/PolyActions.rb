
class PolyActions

    # PolyActions::access(object)
    def self.access(object)

        if object["mikuType"] == "NxLink" then
            return
        end
        if object["mikuType"] == "NxNote" then
            puts "--------------------------------------------------------------"
            puts object["text"]
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["mikuType"] == "NxDataBeacon" then
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
            id = object["id"]
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
            return
        end
        if object["mikuType"] == "NxDataUniqueString" then
            uniquestring = object["uniquestring"]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if object["mikuType"] == "NxDataAionPoint" then
            nhash = object["nhash"]
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
        if object["mikuType"] == "NxDataUrl" then
            url = object["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["mikuType"] == "NxDataText" then
            puts "--------------------------------------------------------------"
            puts object["text"]
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["mikuType"] == "Permanode" then
            return
        end
        if object["mikuType"] == "NavigationNode" then
            return
        end
        raise "(error: 8671fba4-851d-4f0f-b46a-3d46710741ac) I do not know how to access object: #{JSON.pretty_generate(object)}"
    end

    # PolyActions::edit(object)
    def self.edit(object)
        return if object.nil?
        if object["mikuType"] == "NxDataText" then
            object["text"] = CommonUtils::editTextSynchronously(object["text"])
            NxObjectIO::commitObject(object)
            return
        end
        if object["type"] == "url" then
            object["url"] = LucilleCore::askQuestionAnswerAsString("url: ")
            NxObjectIO::commitObject(object)
            return
        end
        if object["type"] == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            object["nhash"] = AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            NxObjectIO::commitObject(object)
            return
        end
        if object["type"] == "beacon" then
            puts "There is no current facilities to edit a beacon"
            LucilleCore::pressEnterToContinue()
            return
        end
        if object["type"] == "unique-string" then
            object["uniquestring"] = LucilleCore::askQuestionAnswerAsString("unique string: ")
            NxObjectIO::commitObject(object)
            return
        end
        raise "(error: 29e9567f) editing NxData[*]: #{object}"
    end    
end

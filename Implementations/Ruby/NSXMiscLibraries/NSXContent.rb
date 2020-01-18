#!/usr/bin/ruby

# encoding: UTF-8

require "/Users/pascal/Galaxy/2020-LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

class NSX1ContentsItemUtils

    # NSX1ContentsItemUtils::contentItemToAnnounce(item)
    def self.contentItemToAnnounce(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["line"]
        end
        if item["type"] == "atlas-reference" then
            return item["announce"]
        end
        "[8f854b3a] I don't know how to announce: #{JSON.generate(item)}"
    end

    # NSX1ContentsItemUtils::contentItemToBody(item)
    def self.contentItemToBody(item)
        if item["type"] == "line" then
            return item["line"]
        end
        if item["type"] == "line-and-body" then
            return item["body"]
        end
        if item["type"] == "atlas-reference" then
            fileContent = NSXAtlasReferenceUtils::referenceToFileContentsOrNull(item["atlas-reference"])
            if fileContent.nil? then
                return "Could not determine atlas-reference: #{item["atlas-reference"]}, for '#{item["announce"]}'"
            else
                return [
                    item["announce"],
                    "atlas reference: #{item["atlas-reference"]}",
                    "file".green + ":",
                    fileContent.lines.first(10).map{|line| "        #{line}" }.join("\n")
                ].join("\n")
            end
        end
        "[09bab884] I don't know how to body: #{JSON.generate(item)}"
    end

end

class NSX2GenericContentUtils

    # NSX2GenericContentUtils::timeStringL22() # 20181122-194155-272951
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSX2GenericContentUtils::issueItemLocationMoveOriginal(location)
    def self.issueItemLocationMoveOriginal(location)
        targetLocationParentFoldername = NSX2GenericContentUtils::timeStringL22()
        targetLocationParentFolderpath = NSX2GenericContentUtils::newL22FoldernameToFolderpath(targetLocationParentFoldername)
        # Now we copy the old location inside the newly created folder.
        LucilleCore::copyFileSystemLocation(location, targetLocationParentFolderpath)
        item = {}
        item["uuid"] = SecureRandom.hex
        item["type"] = "location"
        item["parent-foldername"] = targetLocationParentFoldername
        LucilleCore::removeFileSystemLocation(location)
        item 
    end

    # NSX2GenericContentUtils::newL22FoldernameToFolderpath(foldername)
    def self.newL22FoldernameToFolderpath(foldername)
        frg1 = foldername[0,4]
        frg2 = foldername[0,6]
        frg3 = foldername[0,8]
        folder1 = "#{CATALYST_INSTANCE_FOLDERPATH}/Generic-Contents/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{foldername}"
        if !File.exists?(folder3) then
            FileUtils.mkpath(folder3)
        end
        folder3
    end

    # NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(foldername)
    def self.resolveFoldernameToFolderpathOrNull(foldername)
        folderpath = KeyValueStore::getOrNull(nil, "57c11b5f-820f-4648-8d03-ba023390ee93:#{foldername}")
        if folderpath then
            if File.exists?(folderpath) then
                return folderpath
            end
        end
        folderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
        if folderpath then
            KeyValueStore::set(nil, "57c11b5f-820f-4648-8d03-ba023390ee93:#{foldername}", folderpath)
        end
        folderpath
    end

    # NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
    def self.resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
        Find.find("#{CATALYST_INSTANCE_FOLDERPATH}/Generic-Contents") do |path|
            next if File.file?(path)
            next if File.basename(path) != foldername
            return path
        end
        nil
    end

    # NSX2GenericContentUtils::viewGenericContentItemReturnUpdatedItemOrNull(item)
    def self.viewGenericContentItemReturnUpdatedItemOrNull(item)
        if item["type"]=="url" then
            url = item["url"]
            system("open '#{url}'")
            return nil
        end
        if item["type"]=="text" then
            if item["text"].start_with?("http") then
                url = item["text"].strip
                system("open '#{url}'")
                return nil
            end
            filepath = "#{NSXMiscUtils::newBinArchivesFolderpath()}/#{NSX2GenericContentUtils::timeStringL22()}.txt"
            File.open(filepath, "w"){|f| f.puts(item["text"]) }
            puts "Opening the file and then you can edit it..."
            sleep 2
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            updatedText = IO.read(filepath)
            if item["text"] != updatedText then
                item["text"] = updatedText
                return item
            end
            return nil
        end
        if item["type"]=="location" then
            parentFoldername = item["parent-foldername"]
            folderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(parentFoldername)
            if folderpath.nil? then
                puts "[error: e0fb264] Could not locate foldername: #{item["parent-foldername"]}"
            else
                filepath = NSXMiscUtils::filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
                if filepath then
                    if filepath[-'.webloc'.size, '.webloc'.size] == '.webloc' then
                        system("open '#{filepath}'")
                    else
                        system("open '#{folderpath}'")
                    end
                else
                    system("open '#{folderpath}'")
                end
                return nil
            end

        end
    end

    # NSX2GenericContentUtils::genericContentsItemToCatalystObjectAnnounce(genericContent)
    def self.genericContentsItemToCatalystObjectAnnounce(genericContent)
        if genericContent["type"] == "text" then
            return genericContent["text"].lines.first
        end
        if genericContent["type"] == "url" then
            return genericContent["url"]
        end
        if genericContent["type"] == "location" then
            folderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(genericContent["parent-foldername"])
            if folderpath then
                filepath = NSXMiscUtils::filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
                if filepath then
                    return "location: #{File.basename(filepath)}"
                else
                    return "location: #{genericContent["parent-foldername"]}"
                end
            else
                return "location (not found): #{genericContent["parent-foldername"]}"
            end

        end
        "Error a561fefa: #{filepath}"
    end

    # NSX2GenericContentUtils::genericContentsItemToCatalystObjectBody(genericContent)
    def self.genericContentsItemToCatalystObjectBody(genericContent)
        if genericContent["type"] == "text" then
            return genericContent["text"]
        end
        if genericContent["type"] == "url" then
            return genericContent["url"]
        end
        if genericContent["type"] == "location" then
            folderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(genericContent["parent-foldername"])
            if folderpath then
                filepath = NSXMiscUtils::filepathOfTheOnlyRelevantFileInFolderOrNull(folderpath)
                if filepath then
                    return "location: #{File.basename(filepath)}"
                else
                    return "location: #{genericContent["parent-foldername"]}"
                end
            else
                return "location (not found): #{genericContent["parent-foldername"]}"
            end

        end
        "Error a561fefa: #{filepath}"
    end

    # NSX2GenericContentUtils::destroyItem(item)
    def self.destroyItem(item)
        if item["type"]=="url" then
            # nothing
        end
        if item["type"]=="text" then
            # nothing
        end
        if item["type"]=="location" then
            locationfoldername = item["parent-foldername"]
            locationfolderpath = NSX2GenericContentUtils::resolveFoldernameToFolderpathOrNull(locationfoldername)
            if locationfolderpath then
                NSXMiscUtils::moveLocationToCatalystBin(locationfolderpath)
            end
        end
    end

end

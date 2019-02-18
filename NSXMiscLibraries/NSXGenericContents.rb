
# encoding: UTF-8

require 'fileutils'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'net/imap'
require 'mail'

require 'find'

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# ----------------------------------------------------------------------

class NSXGenericContents

    # NSXGenericContents::timeStringL22() # 20181122-194155-272951
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # NSXGenericContents::newItemFilenameToFilepath(filename)
    def self.newItemFilenameToFilepath(filename)
        frg1 = filename[0,4]
        frg2 = filename[0,6]
        frg3 = filename[0,8]
        folder1 = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Generic-Contents/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        filepath = "#{folder2}/#{filename}"
        filepath
    end

    # NSXGenericContents::newL22FoldernameToFolderpath(foldername)
    def self.newL22FoldernameToFolderpath(foldername)
        frg1 = foldername[0,4]
        frg2 = foldername[0,6]
        frg3 = foldername[0,8]
        folder1 = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Generic-Contents/#{frg1}/#{frg2}/#{frg3}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{foldername}"
        if !File.exists?(folder3) then
            FileUtils.mkpath(folder3)
        end
        folder3
    end

    # NSXGenericContents::resolveFilenameToFilepathOrNullUseTheForce(filename)
    def self.resolveFilenameToFilepathOrNullUseTheForce(filename)
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Generic-Contents") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
    end

    # NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        filepath = KeyValueStore::getOrNull(nil, "2fea73a3-469d-4eae-bbbd-aa73628f42cc:#{filename}")
        if filepath then
            if File.exists?(filepath) then
                return filepath
            end
        end
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNullUseTheForce(filename)
        if filepath then
            KeyValueStore::set(nil, "2fea73a3-469d-4eae-bbbd-aa73628f42cc:#{filename}", filepath)
        end
        filepath
    end

    # NSXGenericContents::resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
    def self.resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Generic-Contents") do |path|
            next if File.file?(path)
            next if File.basename(path) != foldername
            return path
        end
        nil
    end

    # NSXGenericContents::resolveFoldernameToFolderpathOrNull(foldername)
    def self.resolveFoldernameToFolderpathOrNull(foldername)
        folderpath = KeyValueStore::getOrNull(nil, "57c11b5f-820f-4648-8d03-ba023390ee93:#{foldername}")
        if folderpath then
            if File.exists?(folderpath) then
                return folderpath
            end
        end
        folderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNullUseTheForce(foldername)
        if folderpath then
            KeyValueStore::set(nil, "57c11b5f-820f-4648-8d03-ba023390ee93:#{foldername}", folderpath)
        end
        folderpath
    end

    # NSXGenericContents::makeBaseItem()
    def self.makeBaseItem()
        filename = "#{NSXGenericContents::timeStringL22()}.CatalystGenericItem.json"
        item = {}
        item["uuid"] = SecureRandom.hex
        item["filename"] = filename
        item
    end

    # NSXGenericContents::issueItemText(text)
    def self.issueItemText(text)
        item = NSXGenericContents::makeBaseItem()
        item["type"] = "text"
        item["text"] = text
        NSXGenericContents::sendItemToDisk(item)
        item        
    end

    # NSXGenericContents::issueItemURL(url)
    def self.issueItemURL(url)
        item = NSXGenericContents::makeBaseItem()
        item["type"] = "url"
        item["url"] = url
        NSXGenericContents::sendItemToDisk(item)
        item        
    end

    # NSXGenericContents::issueItemEmail(email)
    def self.issueItemEmail(email)
        emailFilename = "#{NSXGenericContents::timeStringL22()}.eml"
        emailFilepath = NSXGenericContents::newItemFilenameToFilepath(emailFilename)
        File.open(emailFilepath, "w"){|f| f.write(email) }
        item = NSXGenericContents::makeBaseItem()
        item["type"] = "email"
        item["email-subject"] = NSXGenericContents::emailFilenameToSubjectLine(emailFilename)
        item["email-filename"] = emailFilename
        NSXGenericContents::sendItemToDisk(item)
        item        
    end

    # NSXGenericContents::issueItemLocationMoveOriginal(location)
    def self.issueItemLocationMoveOriginal(location)
        targetLocationParentFoldername = NSXGenericContents::timeStringL22()
        targetLocationParentFolderpath = NSXGenericContents::newL22FoldernameToFolderpath(targetLocationParentFoldername)
        # Now we copy the old location inside the newly created folder.
        LucilleCore::copyFileSystemLocation(location, targetLocationParentFolderpath)
        item = NSXGenericContents::makeBaseItem()
        item["type"] = "location"
        item["parent-foldername"] = targetLocationParentFoldername
        NSXGenericContents::sendItemToDisk(item)
        LucilleCore::removeFileSystemLocation(location)
        item 
    end

    # NSXGenericContents::sendItemToDisk(item)
    def self.sendItemToDisk(item)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(item["filename"])
        if filepath.nil? then
            filepath = NSXGenericContents::newItemFilenameToFilepath(item["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NSXGenericContents::emailFilenameToSubjectLine(filename)
    def self.emailFilenameToSubjectLine(filename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
        return "Error 12wasas: unknown file" if filepath.nil?
        begin
            mailObject = Mail.read(filepath)
            mailObject.subject
        rescue
            "Error: could not read subject line for: #{filepath}"
        end
    end

    # NSXGenericContents::emailFilenameToFrom(filename)
    def self.emailFilenameToFrom(filename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
        return "Error cbfcecae: unknown file" if filepath.nil?
        IO.read(filepath).lines.select{|line| line.start_with?("From:") }.each{|line| return line.strip }
        "Error 42b5f47a: #{address.class.to_s}"
    end

    # NSXGenericContents::emailFilenameToDateTime(filename)
    def self.emailFilenameToDateTime(filename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
        return "Error cf238fc1: unknown file" if filepath.nil?
        mailObject = Mail.read(filepath)
        DateTime.parse(mailObject.date.to_s).to_time.utc.iso8601
    end

    # NSXGenericContents::transformEmailContents(contents)
    def self.transformEmailContents(contents)
        contents = contents.lines.select{|line| line.strip.size>0 }.take_while{|line| !line.start_with?('This e-mail and all attachments are confidential') }.join("").strip
        return "[ empty email; condition b5b62206 ]" if contents.lines.to_a.size==0
        return "[ delete on sight; condition 58f3eb60 ]" if contents.lines.first.include?("PRbuilds results:")
        return "[ delete on sight; condition 58f3eb60 ]" if contents.lines.first.include?("Seen on [PROD]")
        contents
    end

    # NSXGenericContents::displayableEmailParts(mail)
    def self.displayableEmailParts(mail)
        if mail.multipart? then
            mail.parts.to_a.select{|part| CatalystUI::stringOrFirstString(part.content_type).start_with?("text/plain") }
        else
            [ mail.body ]
        end
    end

    # NSXGenericContents::emailToString(emailFilepath)
    def self.emailToString(emailFilepath)
        outputAsArray = []
        filepath = emailFilepath
        outputAsArray << "#{filepath}"
        mail = Mail.read(filepath)
        NSXGenericContents::displayableEmailParts(mail).each{|part|
            contents = part.decoded
            outputAsArray <<  "-- begin -----------------------------------------------"
            outputAsArray <<  NSXGenericContents::transformEmailContents(contents).lines.select{|line| line.strip.size>0 }.take_while{|line| !line.start_with?('This e-mail and all attachments are confidential') }.join("").strip
            outputAsArray <<  "--- end ------------------------------------------------"
        }
        outputAsArray.join("\n")
    end

    # NSXGenericContents::filenameToCatalystObjectAnnounce(genericContentFilename)
    def self.filenameToCatalystObjectAnnounce(genericContentFilename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(genericContentFilename)
        if filepath.nil? then
            return "Error f849ab3a: #{genericContentFilename}"
        end
        genericContentItem = JSON.parse(IO.read(filepath))
        if genericContentItem["type"]=="text" then
            return ( genericContentItem["text"].lines.first || "(empty file text)" )
        end
        if genericContentItem["type"]=="url" then
            return genericContentItem["url"]
        end
        if genericContentItem["type"]=="email" then
            emailFilename = genericContentItem["email-filename"]
            emailFilepath = NSXGenericContents::resolveFilenameToFilepathOrNull(emailFilename)
            output = []
            output << "email (#{NSXGenericContents::emailFilenameToDateTime(emailFilename)}, #{NSXGenericContents::emailFilenameToFrom(emailFilename)}): #{NSXGenericContents::emailFilenameToSubjectLine(emailFilename)}"
            output << NSXGenericContents::emailToString(emailFilepath)
            return output.map{|str| str.force_encoding("utf-8") }.join("\n")
        end
        if genericContentItem["type"]=="location" then
            return "location: #{genericContentItem["parent-foldername"]}"
        end
        "Error a561fefa: #{filepath}"
    end

    # NSXGenericContents::viewItem(filename)
    def self.viewItem(filename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
        item = JSON.parse(IO.read(filepath))

        if item["type"]=="email" then
            emailFilename = item["email-filename"]
            emailFilepath = NSXGenericContents::resolveFilenameToFilepathOrNull(emailFilename)
            system("open '#{emailFilepath}'")
            return
        end

        if item["type"]=="url" then
            url = item["url"]
            system("open '#{url}'")
            return
        end

        if item["type"]=="text" then
            filepath = "#{NSXMiscUtils::newBinArchivesFolderpath()}/#{NSXGenericContents::timeStringL22()}.txt"
            File.open(filepath, "w"){|f| f.puts(item["text"]) }
            puts "Opening the file and then you can edit it..."
            sleep 2
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            updatedText = IO.read(filepath)
            if item["text"] != updatedText then
                item["text"] = updatedText
                NSXGenericContents::sendItemToDisk(item)
            end
            return
        end

        if item["type"]=="location" then
            parentFoldername = item["parent-foldername"]
            folderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNull(parentFoldername)
            return if folderpath.nil?
            system("open '#{folderpath}'")
            return
        end

        puts "954650e9-9087: To be implemented"
        puts JSON.pretty_generate(item)
        LucilleCore::pressEnterToContinue()
    end

    # NSXGenericContents::destroyItem(filename)
    def self.destroyItem(filename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(filename)

        if filepath.nil? then
            puts "Error f818f708: unknown file (#{filename})" 
            LucilleCore::pressEnterToContinue()
        end

        item = JSON.parse(IO.read(filepath))

        if item["type"]=="url" then
            # nothing
        end

        if item["type"]=="text" then
            # nothing
        end

        if item["type"]=="email" then
            emailfilename = item["email-filename"]
            emailfilepath = NSXGenericContents::resolveFilenameToFilepathOrNull(emailfilename)
            if emailfilepath then
                NSXMiscUtils::moveLocationToCatalystBin(emailfilepath)
            end
        end

        if item["type"]=="location" then
            locationfoldername = item["parent-foldername"]
            locationfolderpath = NSXGenericContents::resolveFoldernameToFolderpathOrNull(locationfoldername)
            if locationfolderpath then
                NSXMiscUtils::moveLocationToCatalystBin(locationfolderpath)
            end
        end

        NSXMiscUtils::moveLocationToCatalystBin(filepath)
    end

end


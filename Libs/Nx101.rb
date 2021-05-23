
# encoding: UTF-8

class Nx101

    # Nx101::access(object)
    def self.access(object)

        if object["contentType"] == "Line" then
            return
        end
        if object["contentType"] == "Url" then
            puts "opening '#{object["payload"]}'"
            Utils::openUrl(object["payload"])
            return
        end
        if object["contentType"] == "Text" then
            puts "opening text '#{object["payload"]}' (edit mode)"
            nhash = object["payload"]
            text1 = BinaryBlobsService::getBlobOrNull(nhash)
            text2 = Utils::editTextSynchronously(text1)
            if (text1 != text2) and LucilleCore::askQuestionAnswerAsBoolean("commit changes ? ") then
                object["payload"] = BinaryBlobsService::putBlob(text2)
                CoreDataTx::commit(object)
            end
            return
        end
        if object["contentType"] == "ClickableType" then
            puts "opening file '#{object["payload"]}'"
            nhash, extension = object["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            blob = BinaryBlobsService::getBlobOrNull(nhash)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return
        end
        if object["contentType"] == "AionPoint" then
            puts "opening aion point '#{object["payload"]}'"
            nhash = object["payload"]
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(El1zabeth.new(), nhash, targetReconstructionFolderpath)
            puts "Export completed"
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # Nx101::postAccessCleanUp(object)
    def self.postAccessCleanUp(object)

        if object["contentType"] == "Line" then
            return
        end
        if object["contentType"] == "Url" then
            return
        end
        if object["contentType"] == "Text" then
            return
        end
        if object["contentType"] == "ClickableType" then
            puts "cleaning file '#{object["payload"]}'"
            nhash, extension = object["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if object["contentType"] == "AionPoint" then
            puts "cleaning aion point '#{object["payload"]}'"
            nhash = object["payload"]
            aionObject = AionCore::getAionObjectByHash(El1zabeth.new(), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # Nx101::edit(object)
    def self.edit(object)

        if object["contentType"] == "Line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line == ""
            object["description"] = line
            CoreDataTx::commit(object)
            return
        end
        if object["contentType"] == "Url" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                object["description"] = description
            end  
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            if url != "" then
                object["url"] = url
            end
            CoreDataTx::commit(object)
            return
        end
        if object["contentType"] == "Text" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                object["description"] = description
            end 
            nhash = object["payload"]
            text1 = BinaryBlobsService::getBlobOrNull(nhash)
            text2 = Utils::editTextSynchronously(text1)
            object["payload"] = BinaryBlobsService::putBlob(text2)
            CoreDataTx::commit(object)
            return
        end
        if object["contentType"] == "ClickableType" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                object["description"] = description
            end 
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(f1) then
                nhash = BinaryBlobsService::putBlob(IO.read(f1)) # bad choice, this file could be large
                dottedExtension = File.extname(filenameOnTheDesktop)
                object["payload"] = "#{nhash}|#{dottedExtension}"
                CoreDataTx::commit(object)
            else
                puts "Could not find file: #{f1}"
            end
            return
        end
        if object["contentType"] == "AionPoint" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                object["description"] = description
            end 
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if File.exists?(location) then
                object["payload"] = AionCore::commitLocationReturnHash(El1zabeth.new(), location)
                CoreDataTx::commit(object)
            else
                puts "Could not find file: #{filepath}"
            end
            return
        end
        raise "[error: 707CAFD7-46CF-489B-B829-5F4816C4911D]"
    end

    # Nx101::transmute(object)
    def self.transmute(object)
        puts "Nx101::transmute(marble) is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end

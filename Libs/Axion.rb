#!/usr/bin/ruby

# encoding: utf-8

#---------------------------------------------
# THE MASTER VERSION OF THIS IS IN CATALYST

=begin

Axion provides the datablob interface and some content functions (creation/access/edition) for Catalyst and Nyx (but, for the moment, doesn't hold the contentType/contentPaylaod pairs)

----------------------------------------------------------
contentType        contentPayload
Nothing            Nothing # This covers the "line" case. The understanding is that the client is managing its own description and see it as a content if Nothing
"url"              String
"text"             String
"aion-point"       String # Root Named Hash
"unique-string"    String
"clickable"        String # <nhash>|<dottedExtension>
----------------------------------------------------------

=end

# --------------------------------------------

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'json'

require 'date'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'find'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin

    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)

=end

require 'sqlite3'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        KeyValueStore::set(nil, "SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = KeyValueStore::getOrNull(nil, nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

# -------------------------------------------------------

class AxionBinaryBlobsService

    # AxionBinaryBlobsService::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/DataBlobs2"
    end

    # AxionBinaryBlobsService::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # AxionBinaryBlobsService::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        folderpath = "#{AxionBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # AxionBinaryBlobsService::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        folderpath = "#{AxionBinaryBlobsService::repositoryFolderPath()}/#{nhash[7, 2]}/#{nhash[9, 2]}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end

class AxionElizaBeth

    def commitBlob(blob)
        AxionBinaryBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        AxionBinaryBlobsService::getBlobOrNull(nhash)
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class AxionUtils
    # AxionUtils::openurlUsingSafari(url)
    def self.openurlUsingSafari(url)
        system("open -a Safari '#{url}'")
    end

    # AxionUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end
end

class Axion

    # -------------------------------------------------------------------------------------
    # Data Makers and Handlers

    # Axion::interactivelyIssueNewCoordinatesOrNull(): nil or coordinates = {contentType, contentPayload}
    def self.interactivelyIssueNewCoordinatesOrNull()

        contentType = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line (default)" ,"url", "text", "clickable", "aion-point"])

        if contentType.nil? then
            return nil
        end

        if contentType == "line (default)" then
            return nil
        end

        if contentType == "url" then
            input = LucilleCore::askQuestionAnswerAsString("url (empty for abort): ")
            if input == "" then
                return nil
            end
            contentPayload = input
        end

        if contentType == "text" then
            text = Utils::editTextSynchronously("")
            contentPayload = AxionBinaryBlobsService::putBlob(text)
        end

        if contentType == "clickable" then
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if !File.exists?(f1) or !File.file?(f1) then
                return nil
            end
            nhash = AxionBinaryBlobsService::putBlob(IO.read(f1))
            dottedExtension = File.extname(filenameOnTheDesktop)
            contentPayload = "#{nhash}|#{dottedExtension}"
        end

        if contentType == "aion-point" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if !File.exists?(location) then
                return nil
            end
            contentPayload = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
        end

        {
            "contentType"    => contentType,
            "contentPayload" => contentPayload
        }
    end

    # Axion::access(contentType, contentPayload, update: Lambda(contentType, contentPayload))
    def self.access(contentType, contentPayload, update)
        if contentType.nil? then
            return
        end
        if contentType == "" then
            return
        end
        if contentType == "line" then
            return
        end
        if contentType == "url" then
            puts "opening '#{contentPayload}'"
            AxionUtils::openurlUsingSafari(contentPayload)
            return
        end
        if contentType == "text" then
            puts "opening text '#{contentPayload}' (edit mode)"
            nhash = contentPayload
            text1 = AxionBinaryBlobsService::getBlobOrNull(nhash)
            text2 = Utils::editTextSynchronously(text1)
            if (text1 != text2) and LucilleCore::askQuestionAnswerAsBoolean("commit changes ? ") then
                contentPayload = AxionBinaryBlobsService::putBlob(text2)
                update.call(contentType, contentPayload)
            end
            return
        end
        if contentType == "clickable" then
            puts "opening file '#{contentPayload}'"
            nhash, extension = contentPayload.split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            if File.exists?(filepath) then
                puts "Cannot export [#{contentType}, #{contentPayload}] at '#{filepath}' because file is already on Desktop"
                LucilleCore::pressEnterToContinue()
                return
            end
            blob = AxionBinaryBlobsService::getBlobOrNull(nhash)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return
        end
        if contentType == "aion-point" then
            puts "opening aion point '#{contentPayload}'"
            nhash = contentPayload
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            object = AionCore::getAionObjectByHash(AxionElizaBeth.new(), nhash)
            location = "#{targetReconstructionFolderpath}/#{object["name"]}"
            if File.exists?(location) then
                puts "Cannot export [#{contentType}, #{contentPayload}] at '#{location}' because file is already on Desktop"
                LucilleCore::pressEnterToContinue()
                return
            end
            AionCore::exportHashAtFolder(AxionElizaBeth.new(), nhash, targetReconstructionFolderpath)
            puts "Export completed"
            return
        end
        raise "[error: 24885464-940e-4007-b2ed-fb9a17132445]"
    end

    # Axion::postAccessCleanUp(contentType, contentPayload)
    def self.postAccessCleanUp(contentType, contentPayload)

        if contentType.nil? then
            return
        end

        if contentType == "line" then
            return
        end
        if contentType == "url" then
            return
        end
        if contentType == "text" then
            return
        end
        if contentType == "clickable" then
            puts "cleaning file '#{contentPayload}'"
            nhash, extension = contentPayload.split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if contentType == "aion-point" then
            puts "cleaning aion point '#{contentPayload}'"
            nhash = contentPayload
            aionObject = AionCore::getAionObjectByHash(AxionElizaBeth.new(), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: 68857d28-7719-47e3-81b7-22609d52c0df]"
    end

    # Axion::edit(contentType, contentPayload, update: Lambda(contentType, contentPayload))
    def self.edit(contentType, contentPayload, update)

        if contentType == "line" then
            return
        end
        if contentType == "url" then  
            input = LucilleCore::askQuestionAnswerAsString("url (empty for not changing): ")
            if input != "" then
                contentPayload = input
                update.call(contentType, contentPayload)
            end
            return
        end
        if contentType == "text" then
            nhash = contentPayload
            text1 = AxionBinaryBlobsService::getBlobOrNull(nhash)
            text2 = AxionUtils::editTextSynchronously(text1)
            contentPayload = AxionBinaryBlobsService::putBlob(text2)
            update.call(contentType, contentPayload)
            return
        end
        if contentType == "clickable" then 
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(f1) then
                nhash = AxionBinaryBlobsService::putBlob(IO.read(f1)) # bad choice, this file could be large
                dottedExtension = File.extname(filenameOnTheDesktop)
                contentPayload = "#{nhash}|#{dottedExtension}"
                update.call(contentType, contentPayload)
            else
                puts "Could not find file: #{f1}"
                LucilleCore::pressEnterToContinue()
                return
            end
            return
        end
        if contentType == "aion-point" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop) (empty to abort): ")
            if locationNameOnTheDesktop.size > 0 then
                location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
                if File.exists?(location) then
                    contentPayload = AionCore::commitLocationReturnHash(AxionElizaBeth.new(), location)
                    update.call(contentType, contentPayload)
                else
                    puts "Could not find file: #{filepath}"
                    LucilleCore::pressEnterToContinue()
                end
            end
            return
        end
        raise "[error: 2183df5f-0850-4439-898c-f5f93f128768]"
    end

end

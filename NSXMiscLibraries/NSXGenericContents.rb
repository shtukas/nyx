
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

# ----------------------------------------------------------------------
=begin

{
    "uuid" : UUID
    "filename" : String
    "type"     : "url"
    "url"      : URL
}

{
    "uuid" : UUID
    "filename" : String
    "type"     : "text"
    "text"     : String
}

{
    "uuid" : UUID
    "filename"       : String
    "type"           : "email"
    "email-filename" : 
}

=end

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
        folderpath = "/Galaxy/DataBank/Catalyst/GenericContentRepository/#{frg1}/#{frg2}/#{frg3}"
        filepath = "#{folderpath}/#{filename}"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath
    end

    # NSXGenericContents::resolveFilenameToFilepathOrNull(filename)
    def self.resolveFilenameToFilepathOrNull(filename)
        Find.find("/Galaxy/DataBank/Catalyst/GenericContentRepository") do |path|
            next if !File.file?(path)
            next if File.basename(path) != filename
            return path
        end
        nil
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
        item["email-filename"] = emailFilename
        NSXGenericContents::sendItemToDisk(item)
        item        
    end

    # NSXGenericContents::makeItemEmailSideEffectEmailToDisk(rawemail)
    def self.makeItemEmailSideEffectEmailToDisk(rawemail)
        filename = "#{NSXGenericContents::timeStringL22()}.eml"
        filepath = NSXGenericContents::newItemFilenameToFilepath(filename)
        File.open(filepath, "w"){|f| f.write(rawemail) }
        item = NSXGenericContents::makeBaseItem()
        item["type"] = "email"
        item["email-filename"] = filename
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
        mailObject = Mail.read(filepath)
        mailObject.subject
    end

    # NSXGenericContents::filenameToCatalystObjectAnnounce(genericContentFilename)
    def self.filenameToCatalystObjectAnnounce(genericContentFilename)
        filepath = NSXGenericContents::resolveFilenameToFilepathOrNull(genericContentFilename)
        genericContentItem = JSON.parse(IO.read(filepath))
        if genericContentItem["type"]=="line" then
            return genericContentItem["line"]
        end
        if genericContentItem["type"]=="url" then
            return genericContentItem["url"]
        end
        if genericContentItem["type"]=="email" then
            emailFilename = genericContentItem["email-filename"]
            return "email: #{NSXGenericContents::emailFilenameToSubjectLine(emailFilename)}"
        end
        "NSXGenericContents::filenameToCatalystObjectAnnounce(genericContentFilename): genericContentFilename=#{genericContentFilename}"
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

        puts "NSXGenericContents::viewItem(filename): To be implemented"
        puts JSON.pretty_generate(item)
        LucilleCore::pressEnterToContinue()
    end

end


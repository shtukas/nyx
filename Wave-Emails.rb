#!/usr/bin/ruby

# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "net/http"
require "uri"

require 'json'

require 'date'

require 'colorize'

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Wave.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'net/imap'

require 'mail'

=begin
    mail = Mail.read('/path/to/message.eml')

    mail.envelope_from   #=> 'mikel@test.lindsaar.net'
    mail.from            #=> ['mikel@test.lindsaar.net', 'ada@test.lindsaar.net']
    mail.sender          #=> 'mikel@test.lindsaar.net'
    mail.to              #=> 'bob@test.lindsaar.net'
    mail.cc              #=> 'sam@test.lindsaar.net'
    mail.subject         #=> "This is the subject"
    mail.date.to_s       #=> '21 Nov 1997 09:55:06 -0600'
    mail.message_id      #=> '<4D6AA7EB.6490534@xxx.xxx>'
    mail.body.decoded    #=> 'This is the body of the email...
=end

require_relative "Commons.rb"

# -------------------------------------------------------------------------------------

EMAIL_METADATA_OBJECTS_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Wave/Emails-Metadata-Objects"

class EmailUtils

    def self.sanitizestring(uid)
        uid = uid.gsub(">",'')
        uid = uid.gsub('<','')
        uid = uid.gsub('.','-')
        uid
    end

    # EmailUtils::msgToSubject(msg)
    def self.msgToSubject(msg)
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath) 
        FileUtils.rm(filepath)
        mailObject.subject
    end

    # EmailUtils::msgToBody(msg)
    def self.msgToBody(msg)
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath) 
        FileUtils.rm(filepath)
        mailObject.body.decoded
    end

    # EmailUtils::msgToFromAddresses(msg)
    def self.msgToFromAddresses(msg)
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath) 
        mailObject.from
    end
end

class EmailMetadataManagement

    # EmailMetadataManagement::storeMetadataObject(object)
    def self.storeMetadataObject(object)
        # We expect a uuid
        objectuuid = object['uuid']
        filepath = "#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object"
        File.open(filepath, 'w') {|f| f.write(JSON.pretty_generate(object)) }
    end

    # EmailMetadataManagement::readMetadataObjectOrNull(objectuuid)
    def self.readMetadataObjectOrNull(objectuuid)
        filepath = "#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object"
        return nil if !File.exists?("#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object")
        JSON.parse(IO.read("#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object"))
    end

    # EmailMetadataManagement::objectsDestroyObject(objectuuid)
    def self.objectsDestroyObject(objectuuid)
        filepath = "#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object"
        return nil if !File.exists?("#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{objectuuid}.object")
        FileUtils.rm filepath
    end

    # EmailMetadataManagement::getObjectsOfGivenType(type)
    def self.getObjectsOfGivenType(type)
        Dir.entries("#{EMAIL_METADATA_OBJECTS_FOLDERPATH}")
            .select{|filename| filename[-7, 7] == '.object' }
            .map{|filename| JSON.parse(IO.read("#{EMAIL_METADATA_OBJECTS_FOLDERPATH}/#{filename}")) }
            .select{|object| object['type'] == type }
    end
end

class EmailStatusManagement

    # EmailStatusManagement::makeStatusObject(objectuuid, status)
    def self.makeStatusObject(objectuuid, status)
        {
            "uuid"   => objectuuid,
            "type"   => "email-imap-sync-status-af214081-ad91-4e1a-8422-682a2cffc60b",
            "status" => status
        }        
    end

    # EmailStatusManagement::destroyLocalEmailAndAssociatedMetadata(emailuid, verbose)
    def self.destroyLocalEmailAndAssociatedMetadata(emailuid, verbose)

        emailpoint = EmailMetadataManagement::readMetadataObjectOrNull(emailuid)

        if emailpoint.nil? then
            puts "email-agent api:destroy could not find an emailpoint for emailuid: #{emailuid}" if verbose
        else
            catalystuuid = emailpoint['catalyst-uuid']
            folderpath = WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(catalystuuid)
            if !folderpath.nil? and File.exists?(folderpath) then
                time = Time.new
                targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y-%m")}/#{time.strftime("%Y-%m-%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
                FileUtils.mkpath(targetFolder)
                FileUtils.mv(folderpath,targetFolder)
            end            
        end
        
        statusobjectuuid = "#{emailuid}-cb27a6ee-0b97-4223-861a-800ad51fbbb0"

        EmailMetadataManagement::objectsDestroyObject(statusobjectuuid )
        EmailMetadataManagement::objectsDestroyObject(emailuid)
    end
end

class GeneralEmailClient
    # GeneralEmailClient::syncEmailDataWithServer(parameters, verbose)
    def self.syncEmailDataWithServer(parameters, verbose)

        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        newEmailCount = 0

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername,emailPassword)
        imap.select('INBOX')

        imap.search(['ALL']).each{|id|

            msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']

            emailuid = imap.fetch(id,"ENVELOPE")[0].attr["ENVELOPE"]['message_id']
            emailuid = EmailUtils::sanitizestring(emailuid)

            if EmailUtils::msgToFromAddresses(msg).include?('notifications@github.com') then
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end

            if EmailUtils::msgToFromAddresses(msg).include?('noreply@github.com') then
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end

            statusobjectuuid = "#{emailuid}-cb27a6ee-0b97-4223-861a-800ad51fbbb0"

            statusobject = EmailMetadataManagement::readMetadataObjectOrNull(statusobjectuuid)

            if statusobject.nil? then
                newEmailCount = newEmailCount+1
                puts "[email agent] This is a new email on the server. Downloading." if verbose
                catalystuuid = SecureRandom.hex(4)
                folderpath = WaveTimelineUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath

                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }

                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }

                emailpoint = {
                    "uuid"                   => emailuid,
                    "type"                   => "email-point-fa50bfd3-24e9-4072-8610-03108990a6dd",
                    "catalyst-uuid"          => catalystuuid,
                    "emailuid"               => emailuid,
                    "registration-unixtime"  => Time.new.to_f
                }
                puts JSON.pretty_generate(emailpoint) if verbose
                EmailMetadataManagement::storeMetadataObject(emailpoint)

                schedule = WaveSchedules::makeScheduleObjectNew()
                schedule['metric'] = 0.900 - LucilleCore::nextInteger("14b3e2b4-1365-4ca4-b081-cf0ae0daad5f").to_f/1000000
                WaveTimelineUtils::writeScheduleToDisk(catalystuuid,schedule)

                File.open("#{folderpath}/wave-target-filename.txt", 'w') {|f| f.write(emailFilename) }
                File.open("#{folderpath}/catalyst-description.txt", 'w') {|f| f.write("email: #{EmailUtils::msgToSubject(msg)}") }

                statusobjectuuid = "#{emailpoint['uuid']}-cb27a6ee-0b97-4223-861a-800ad51fbbb0"
                statusobject = EmailStatusManagement::makeStatusObject(statusobjectuuid, "init")
                puts JSON.pretty_generate(statusobject) if verbose
                EmailMetadataManagement::storeMetadataObject(statusobject)

                next
            end

            if statusobject['status'] == 'init' then
                puts "email agent (imap loop): #{emailuid} (on server and init on local)" if verbose
                next
            end

            if statusobject['status'] == 'deleted' then
                puts "email agent (imap loop): #{emailuid} has been logically deleted on local. Hard delete on local and marking for deletion on the server" if verbose
                EmailStatusManagement::destroyLocalEmailAndAssociatedMetadata(emailuid,verbose)
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end

        }

        emailuidsCurrentlyOnServer = imap.search(['ALL']).map{|id|
            emailuid = imap.fetch(id,"ENVELOPE")[0].attr["ENVELOPE"]['message_id']
            emailuid = EmailUtils::sanitizestring(emailuid)
            emailuid
        }

        EmailMetadataManagement::getObjectsOfGivenType("email-point-fa50bfd3-24e9-4072-8610-03108990a6dd")
        .each{|point|
            catalystuuid = point['catalyst-uuid']
            if WaveTimelineUtils::catalystUUIDToItemFolderPathOrNull(catalystuuid).nil? then
                # Email has been deleted on local
                emailuid = point['emailuid']
                if emailuidsCurrentlyOnServer.include?(emailuid) then
                    puts "email agent: The catalyst item #{point['catalyst-uuid']} has been deleted. Email exists on server. Performing logical delete of the email" if verbose
                    statusobjectuuid = "#{emailuid}-cb27a6ee-0b97-4223-861a-800ad51fbbb0"
                    statusobject = EmailMetadataManagement::readMetadataObjectOrNull(statusobjectuuid)
                    statusobject['status'] = 'deleted'
                    EmailMetadataManagement::storeMetadataObject(statusobject)
                else
                    puts "email agent: The catalyst item #{point['catalyst-uuid']} has been deleted. Email doesn't exists on server. Performing hard delete of the email" if verbose
                    EmailStatusManagement::destroyLocalEmailAndAssociatedMetadata(emailuid,verbose)
                end
            end
        }

        emailuidsCurrentlyOnLocal = EmailMetadataManagement::getObjectsOfGivenType("email-point-fa50bfd3-24e9-4072-8610-03108990a6dd").map{|object| object["emailuid"] }.compact

        (emailuidsCurrentlyOnLocal-emailuidsCurrentlyOnServer).each{|emailuid|
            statusobjectuuid = "#{emailuid}-cb27a6ee-0b97-4223-861a-800ad51fbbb0"
            statusobject = EmailMetadataManagement::readMetadataObjectOrNull(statusobjectuuid)
            if statusobject.nil? then
                statusobject = EmailStatusManagement::makeStatusObject(statusobjectuuid, "init")
                EmailMetadataManagement::storeMetadataObject(statusobject)
                next
            end
            if statusobject['status'] == 'init' then
                # We have a local init email that is not longer on the server, needs to be removed
                puts "email agent: We have a local init email that is not longer on the server. Removing email point: emailuid: #{emailuid}" if verbose
                EmailStatusManagement::destroyLocalEmailAndAssociatedMetadata(emailuid,verbose)
                next
            end            
        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()

        newEmailCount
    end
end

class OperatorEmailDownloader
    def self.syncEmailDataWithServer(parameters,verbose)

        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername, emailPassword)
        imap.select('INBOX')

        imap.search(['ALL']).each{|id|

            msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']
            emailuid = EmailUtils::sanitizestring(imap.fetch(id, "ENVELOPE")[0].attr["ENVELOPE"]['message_id'])
            subjectline = EmailUtils::msgToSubject(msg)

            if subjectline.nil? or subjectline.strip.size==0 or EmailUtils::msgToBody(msg).to_s.size>0 then
                puts "[operator@alseyn.net] Importing email as full object" if verbose
                catalystuuid = SecureRandom.hex(4)
                folderpath = WaveTimelineUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }
                schedule = WaveSchedules::makeScheduleObjectNew()
                schedule['metric'] = 0.850 - LucilleCore::nextInteger("674ebd0f-c32e-4f07-9308-62d4e18f64cd").to_f/1000000
                WaveTimelineUtils::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/wave-target-filename.txt", 'w') {|f| f.write(emailFilename) }
                File.open("#{folderpath}/catalyst-description.txt", 'w') {|f| f.write("operator@alseyn.net: #{emailuid}") }
            else
                puts "[operator@alseyn.net] Importing email as subjectline" if verbose
                catalystuuid = SecureRandom.hex(4)
                folderpath = WaveTimelineUtils::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                schedule = WaveSchedules::makeScheduleObjectNew()
                schedule['metric'] = 0.850 - LucilleCore::nextInteger("674ebd0f-c32e-4f07-9308-62d4e18f64cd").to_f/1000000
                WaveTimelineUtils::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/catalyst-description.txt", 'w') {|f| f.write("operator@alseyn.net (subject line): #{subjectline}") }
            end

            imap.store(id, "+FLAGS", [:Deleted])

        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end
end

# -------------------------------------------------------------------------------------


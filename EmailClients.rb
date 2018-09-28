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
require "time"
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
# -------------------------------------------------------------------------------------

EMAIL_METADATA_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/Wave/Email-Metadata"

# EmailUtils::msgToSubject(msg)
# EmailUtils::msgToBody(msg)
# EmailUtils::msgToFromAddresses(msg)

class EmailUtils
    def self.sanitizestring(uid)
        uid = uid.gsub(">",'')
        uid = uid.gsub('<','')
        uid = uid.gsub('.','-')
        uid = uid.gsub('/','-')
        uid
    end

    def self.msgToSubject(msg)
        filetrace = SecureRandom.hex
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        FileUtils.rm(filepath)
        mailObject.subject
    end

    def self.msgToBody(msg)
        filetrace = SecureRandom.hex
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        FileUtils.rm(filepath)
        mailObject.body.decoded
    end

    def self.msgToFromAddresses(msg)
        filetrace = SecureRandom.hex
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        FileUtils.rm(filepath)
        mailObject.from
    end

    def self.msgToDateTime(msg)
        filetrace = SecureRandom.hex
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        begin
            DateTime.parse(mailObject.date.to_s).to_time.utc.iso8601
        rescue
            Time.now.utc.iso8601
        end
    end

    def self.msgToUnixtime(msg)
        filetrace = SecureRandom.hex
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        begin
            DateTime.parse(mailObject.date.to_s).to_time.to_i
        rescue
            Time.new.to_i
        end
    end

end

# EmailMetadataOperator::getCurrentStatusForEmailUIDOrNull(emailuid)
# EmailMetadataOperator::destroyMetadata(emailuid)
# EmailMetadataOperator::metadataFolderEmailUIDs()

class EmailMetadataOperator
    def self.getCurrentStatusForEmailUIDOrNull(emailuid)
        filepath = "#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|status"
        if File.exists?(filepath) then
            return IO.read(filepath).strip
        end
        nil
    end
    
    def self.metadataFolderEmailUIDs()
        Dir.entries(EMAIL_METADATA_FOLDERPATH).map{|filename|
            if filename[-7,7]=="|status" then
                filename.split("|").first
            else
                nil
            end
        }.compact
    end

    def self.destroyMetadata(emailuid)
        Dir.entries(EMAIL_METADATA_FOLDERPATH).each{|filename|
            next if !filename.start_with?(emailuid)
            FileUtils.rm("#{EMAIL_METADATA_FOLDERPATH}/#{filename}")
        }
    end
end

# OperatorEmailClient::download(parameters,verbose)

class OperatorEmailClient
    def self.download(parameters,verbose)

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
                folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule["unixtime"] = EmailUtils::msgToUnixtime(msg)
                schedule[':wave-email:'] = true # read by Wave agent
                schedule[':wave-email-datetime:'] = EmailUtils::msgToDateTime(msg)
                schedule[':wave-email-catalyst-registration-datetime:'] = Time.now.utc.iso8601
                AgentWave::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/description.txt", 'w') {|f| f.write("operator@alseyn.net: #{emailuid}") }
            else
                puts "[operator@alseyn.net] Importing email as subjectline" if verbose
                catalystuuid = SecureRandom.hex(4)
                folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule["unixtime"] = EmailUtils::msgToUnixtime(msg)
                schedule[':wave-email:'] = true # read by Wave agent
                schedule[':wave-email-datetime:'] = EmailUtils::msgToDateTime(msg)
                schedule[':wave-email-catalyst-registration-datetime:'] = Time.now.utc.iso8601
                AgentWave::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/description.txt", 'w') {|f| f.write("operator@alseyn.net: subject line: #{subjectline}") }
            end

            imap.store(id, "+FLAGS", [:Deleted])

        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end
end

# GeneralEmailClient::sync(parameters, verbose)

class GeneralEmailClient
    def self.sync(parameters, verbose)

        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername,emailPassword)
        imap.select('INBOX')

        imap.search(['ALL']).each{|id|

            emailuid = imap.fetch(id,"ENVELOPE")[0].attr["ENVELOPE"]['message_id']
            emailuid = EmailUtils::sanitizestring(emailuid)

            status = EmailMetadataOperator::getCurrentStatusForEmailUIDOrNull(emailuid)

            if status.nil? then
                puts "email agent: This is a new email on the server. Downloading: #{emailuid}" if verbose
                msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']
                File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|status", 'w') {|f| f.write("init") }
                forbiddenAddresses = ['notifications@github.com', 'noreply@github.com']
                if forbiddenAddresses.any?{|address| EmailUtils::msgToFromAddresses(msg).include?(address) } then
                    imap.store(id, "+FLAGS", [:Deleted])
                    File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|status", 'w') {|f| f.write("deleted") }
                    next
                end
                catalystuuid = SecureRandom.hex(4)
                File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|msg", 'w') {|f| f.write(msg) }
                File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule["unixtime"] = EmailUtils::msgToUnixtime(msg)
                schedule[':wave-email:'] = true # read by Wave agent
                schedule[':wave-email-datetime:'] = EmailUtils::msgToDateTime(msg)
                schedule[':wave-email-catalyst-registration-datetime:'] = Time.now.utc.iso8601
                AgentWave::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/description.txt", 'w') {|f| f.write("email: #{EmailUtils::msgToSubject(msg)}") }
                File.open("#{folderpath}/email-metatada-emailuid.txt", 'w') {|f| f.write(emailuid) }
                next
            end

            if status == 'init' then
                puts "email agent: on server and init on local: #{emailuid}" if verbose
                next
            end

            if status == 'deleted' then
                puts "email agent: email has been logically deleted on local. Removing Catalyst item, delete local metadata, marking for deletion on the server: #{emailuid}" if verbose
                AgentWave::archiveWaveItem(WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid))
                EmailMetadataOperator::destroyMetadata(emailuid)
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end

        }

        imap.expunge # delete all messages marked for deletion

        serverEmailUIDs = imap.search(['ALL']).map{|id|
            emailuid = imap.fetch(id,"ENVELOPE")[0].attr["ENVELOPE"]['message_id']
            EmailUtils::sanitizestring(emailuid)
        }

        metadataFolderEmailUIDs = EmailMetadataOperator::metadataFolderEmailUIDs()

        waveTimeLineEmailUIDs = WaveEmailSupport::allEmailUIDs()

        (metadataFolderEmailUIDs-waveTimeLineEmailUIDs).each{|emailuid|
            puts "email agent: catayst item has been deleted. Marking email as deleted in metadata: #{emailuid}" if verbose
            File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|status", 'w') {|f| f.write("deleted") }
        }

        (metadataFolderEmailUIDs-serverEmailUIDs).each{|emailuid|
            # We have a local init email that is not longer on the server, needs to be removed
            puts "email agent: We have a local init email that is not longer on the server. Removing metadata and Wave item: #{emailuid}" if verbose
            EmailMetadataOperator::destroyMetadata(emailuid)
            AgentWave::archiveWaveItem(WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid))
        }

        (serverEmailUIDs-metadataFolderEmailUIDs).each{|emailuid|

        }

        (waveTimeLineEmailUIDs-metadataFolderEmailUIDs).each{|emailuid|

        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end
end

# -------------------------------------------------------------------------------------

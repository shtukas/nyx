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

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "Flock.rb"
require_relative "Events.rb"
require_relative "FKVStore.rb"
require_relative "MiniFIFOQ.rb"
require_relative "Config.rb"
require_relative "AgentsManager.rb"
require_relative "RequirementsOperator.rb"
require_relative "TodayOrNotToday.rb"
require_relative "GenericTimeTracking.rb"
require_relative "CatalystDevOps.rb"
require_relative "OperatorCollections.rb"
require_relative "NotGuardian"
require_relative "FolderProbe.rb"
require_relative "CommonsUtils"
require_relative "Agent-Wave.rb"

# -------------------------------------------------------------------------------------

EMAIL_METADATA_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave/Email-Metadata"

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
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        FileUtils.rm(filepath)
        mailObject.subject
    end

    def self.msgToBody(msg)
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        FileUtils.rm(filepath)
        mailObject.body.decoded
    end

    def self.msgToFromAddresses(msg)
        filetrace = Digest::SHA1.hexdigest(msg)+'-c17ca0729774b7b982632bf19db2504c'
        filename = "#{filetrace}.eml"
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(msg) }
        mailObject = Mail.read(filepath)
        mailObject.from
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
                folderpath = Wave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule[':wave-emails:'] = true # read by Wave agent
                lucilleNextInteger = LucilleCore::nextInteger("674ebd0f-c32e-4f07-9308-62d4e18f64cd")
                schedule[':wave-emails:lucille-next-integer'] = lucilleNextInteger
                schedule[':wave-emails:creation-datetime'] = Time.new.to_s
                schedule['metric'] = 0.850 - lucilleNextInteger.to_f/1000000
                Wave::writeScheduleToDisk(catalystuuid, schedule)
                File.open("#{folderpath}/description.txt", 'w') {|f| f.write("operator@alseyn.net: #{emailuid}") }
            else
                puts "[operator@alseyn.net] Importing email as subjectline" if verbose
                catalystuuid = SecureRandom.hex(4)
                folderpath = Wave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule[':wave-emails:'] = true # read by Wave agent
                lucilleNextInteger = LucilleCore::nextInteger("674ebd0f-c32e-4f07-9308-62d4e18f64cd")
                schedule[':wave-emails:lucille-next-integer'] = lucilleNextInteger
                schedule[':wave-emails:creation-datetime'] = Time.new.to_s
                schedule['metric'] = 0.850 - lucilleNextInteger.to_f/1000000
                Wave::writeScheduleToDisk(catalystuuid, schedule)
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
                folderpath = Wave::timestring22ToFolderpath(LucilleCore::timeStringL22())
                FileUtils.mkpath folderpath
                File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(catalystuuid) }
                emailFilename = "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}.eml"
                emailFilePath = "#{folderpath}/#{emailFilename}"
                File.open(emailFilePath, 'w') {|f| f.write(msg) }
                schedule = WaveSchedules::makeScheduleObjectTypeNew()
                schedule[':wave-emails:'] = true # read by Wave agent
                lucilleNextInteger = LucilleCore::nextInteger("674ebd0f-c32e-4f07-9308-62d4e18f64cd")
                schedule[':wave-emails:lucille-next-integer'] = lucilleNextInteger
                schedule[':wave-emails:creation-datetime'] = Time.new.to_s
                schedule['metric'] = 0.850 - lucilleNextInteger.to_f/1000000
                Wave::writeScheduleToDisk(catalystuuid,schedule)
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
                Wave::archiveWaveItem(WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid))
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

        (metadataFolderEmailUIDs-serverEmailUIDs).each{|emailuid|
            # We have a local init email that is not longer on the server, needs to be removed
            puts "email agent: We have a local init email that is not longer on the server. Removing metadata and Wave item: #{emailuid}" if verbose
            EmailMetadataOperator::destroyMetadata(emailuid)
            Wave::archiveWaveItem(WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid))
        }

        (serverEmailUIDs-metadataFolderEmailUIDs).each{|emailuid|
            puts "Wave-Email error 312CB356: We should not be seeing this. By now all alive server emails should be on local ( #{emailuid} )"
            LucilleCore::pressEnterToContinue()
        }

        (waveTimeLineEmailUIDs-metadataFolderEmailUIDs).each{|emailuid|
            puts "Wave-Email error 4e7b8cef: We should not be seeing this. Everytime a file is deleted on the metadata folder the wave item should have been deleted"
            puts "emailuid: #{emailuid}"
            catalystuuid = WaveEmailSupport::emailUIDToCatalystUUIDOrNull(emailuid)
            puts "catalystuuid: #{catalystuuid}"
            puts "catalyst folder: #{Wave::catalystUUIDToItemFolderPathOrNull(catalystuuid)}"
            LucilleCore::pressEnterToContinue()
        }

        (metadataFolderEmailUIDs-waveTimeLineEmailUIDs).each{|emailuid|
            puts "email agent: catayst item has been deleted. Marking email as deleted in metadata: #{emailuid}" if verbose
            File.open("#{EMAIL_METADATA_FOLDERPATH}/#{emailuid}|status", 'w') {|f| f.write("deleted") }
        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end
end

# -------------------------------------------------------------------------------------

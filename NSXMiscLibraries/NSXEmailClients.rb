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

class GeneralEmailClient

    # GeneralEmailClient::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # GeneralEmailClient::msgToFrom(msg)
    def self.msgToFrom(msg)
        filename = GeneralEmailClient::timeStringL22()
        folderpath = "/tmp/catalyst-emails"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){ |f| f.write(msg) }
        mailObject = Mail.read(filepath)
        address = mailObject.from
        if address.class.to_s == "Mail::AddressContainer" then
            address = address.first
        end
        FileUtils.rm(filepath)
        address
    end

    # GeneralEmailClient::shouldImportEmail(msg)
    def self.shouldImportEmail(msg)
        from = GeneralEmailClient::msgToFrom(msg)
        return false if ( from == "noreply@md.getsentry.com" )
        true
    end

    # GeneralEmailClient::download(parameters, verbose)
    def self.download(parameters, verbose)
        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername,emailPassword)
        imap.select('INBOX')

        imap.search(['ALL']).each{|id|
            msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']
            if GeneralEmailClient::shouldImportEmail(msg) then
                NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem(NSXStreamsUtils::streamOldNameToStreamUUID("Right-Now"), NSXGenericContents::issueItemEmail(msg))
            end
            imap.store(id, "+FLAGS", [:Deleted])
        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end

end

# -------------------------------------------------------------------------------------

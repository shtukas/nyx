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

    # GeneralEmailClient::msgToSubject(msg)
    def self.msgToSubject(msg)
        filename = GeneralEmailClient::timeStringL22()
        folderpath = "/tmp/catalyst-emails"
        if !File.exists?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){ |f| f.write(msg) }
        mailObject = Mail.read(filepath)
        subject = mailObject.subject
        FileUtils.rm(filepath)
        subject
    end

    # GeneralEmailClient::shouldDevNullThatEmail(msg)
    def self.shouldDevNullThatEmail(msg)
        from = GeneralEmailClient::msgToFrom(msg)
        return true if from.include?("noreply@md.getsentry.com")
        false
    end

    # GeneralEmailClient::downloadWithoutSync(parameters, verbose)
    def self.downloadWithoutSync(parameters, verbose)

        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername,emailPassword)
        imap.select('INBOX')

        # ------------------------------------------------------------------------
        # Download new emails

        imap.search(['ALL']).each{|id|
            msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']
            if verbose then
                puts "#{GeneralEmailClient::msgToFrom(msg)} : #{GeneralEmailClient::msgToSubject(msg)}"
            end
            if GeneralEmailClient::shouldDevNullThatEmail(msg) then
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end
            genericContentsItem = NSXGenericContents::issueItemEmail(msg)
            streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem)
            imap.store(id, "+FLAGS", [:Deleted])
        }

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end

    # GeneralEmailClient::downloadWithSync(parameters, verbose)
    def self.downloadWithSync(parameters, verbose)

        emailImapServer = parameters['server']
        emailUsername   = parameters['username']
        emailPassword   = parameters['password']

        imap = Net::IMAP.new(emailImapServer)
        imap.login(emailUsername,emailPassword)
        imap.select('INBOX')

        emailUIDsOnTheServer = []
        emailUIDToServerIDMap = {} # The server id is what we use for the deletion

        # ------------------------------------------------------------------------
        # Download new emails

        imap.search(['ALL']).each{|id|
            emailuid = imap.fetch(id,"ENVELOPE")[0].attr["ENVELOPE"]['message_id']

            emailUIDsOnTheServer << emailuid
            emailUIDToServerIDMap[emailuid] = id

            # We skip if there is a tracking claim for this emailuid
            # Claim means we have already downloaded the email
            next if NSXEmailTrackingClaims::getClaimByEmailUIDOrNull(emailuid)

            msg  = imap.fetch(id,'RFC822')[0].attr['RFC822']
            if verbose then
                puts "#{GeneralEmailClient::msgToFrom(msg)} : #{GeneralEmailClient::msgToSubject(msg)}"
            end
            if GeneralEmailClient::shouldDevNullThatEmail(msg) then
                imap.store(id, "+FLAGS", [:Deleted])
                next
            end

            genericContentsItem = NSXGenericContents::issueItemEmail(msg)
            streamItem = NSXStreamsUtils::issueItemAtNextOrdinalUsingGenericContentsItem("03b79978bcf7a712953c5543a9df9047", genericContentsItem)
            emailTrackingClaim = NSXEmailTrackingClaims::makeclaim(emailuid, genericContentsItem["uuid"], streamItem["uuid"])
            NSXEmailTrackingClaims::commitClaimToDisk(emailTrackingClaim)
        }

        # ------------------------------------------------------------------------
        # Updating the status of the existing StreamItem based on the contents of emailUIDsOnTheServer
        # Essentially if we have a stream item that is not on the server, we mark it appropriately.

        NSXStreamsUtils::allStreamsItemsEnumerator()
        .each{|item|
            claim = item["emailTrackingClaim"]
            next if claim.nil?
            claim = NSXEmailTrackingClaims::getClaimByEmailUIDOrNull(claim["emailuid"])
            next if claim["status"] == "detached"
            next if claim["status"] == "dead"
            next if claim["status"] == "deleted-on-server"
            next if emailUIDsOnTheServer.include?(claim["emailuid"])
            # We have a element on local that is not detached and not dead and not on the server
            if claim["status"]=="init" then
                NSXStreamsUtils::destroyItem(item["filename"])
                claim["status"] = "deleted-on-server"
                NSXEmailTrackingClaims::commitClaimToDisk(claim)
            end
            if claim["status"]=="deleted-on-local" then
                claim["status"] = "dead"
                puts JSON.pretty_generate(claim)
                LucilleCore::pressEnterToContinue()
                NSXEmailTrackingClaims::commitClaimToDisk(claim)
            end
        }

        # ------------------------------------------------------------------------
        # We now delete on the server the items that are marked as deleted-on-local

        NSXStreamsUtils::allStreamsItemsEnumerator()
        .each{|item|
            claim = item["emailTrackingClaim"]
            next if claim.nil?
            next if claim["status"] == "detached"
            next if claim["status"] == "dead"
            next if claim["status"] == "deleted-on-server"
            if claim["status"]=="deleted-on-local" then
                id = emailUIDToServerIDMap[claim["emailuid"]]
                next if id.nil?
                imap.store(id, "+FLAGS", [:Deleted])
                claim["status"] = "dead"
                NSXEmailTrackingClaims::commitClaimToDisk(claim)
            end
        }        

        imap.expunge # delete all messages marked for deletion

        imap.logout()
        imap.disconnect()
    end

end

# -------------------------------------------------------------------------------------

#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'json'
require 'date'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')
require 'find'
require 'json'
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

# -------------------------------------------------------------------------------------

VIENNA_PATH_TO_DATA = "/Users/pascal/Library/Application Support/Vienna/messages.db"

# select link from messages where read_flag=0;
# update messages set read_flag=1 where link="https://www.schneier.com/blog/archives/2018/04/security_vulner_14.html"

class ViennaLinkFeeder
    def initialize()
        @links = []
    end
    def next()
        if @links.empty? then
            query = "select link from messages where read_flag=0;"
            @links = `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.map{|line| line.strip }
        end
        @links[0]
    end
    def links()
        @links
    end
    def done(link)
        query = "update messages set read_flag=1 where link=\"#{link}\""
        system("sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'")
        @links.shift
    end
    def count()
       query = "select link from messages where read_flag=0;"
       `sqlite3 '#{VIENNA_PATH_TO_DATA}' '#{query}'`.lines.count
    end
end

$viennaLinkFeeder = ViennaLinkFeeder.new()

class NSXAgentVienna

    def self.agentuid()
        "2ba71d5b-f674-4daf-8106-ce213be2fb0e"
    end

    def self.getObjects()
        return [] if !NSXMiscUtils::isLucille18()
        loop {
            link = $viennaLinkFeeder.next()
            break if link.nil?
            NSXStreamsUtils::issueNewStreamItem("38d5658ed46c4daf0ec064e58fb2b97a", NSXGenericContents::issueItemURL(link), NSXMiscUtils::getNewEndOfQueueStreamOrdinal())
            $viennaLinkFeeder.done(link)
        }
        []
    end

    def self.getAllObjects()
        []
    end

    # NSXAgentVienna::processObjectAndCommand(object, command)
    def self.processObjectAndCommand(objectuuid, command, isLocalCommand)
        if command == "open" then
            return 
        end
    end
end

begin
    NSXBob::registerAgent(
        {
            "agent-name"  => "NSXAgentVienna",
            "agentuid"    => NSXAgentVienna::agentuid(),
        }
    )
rescue
end

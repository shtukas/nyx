#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
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
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "Vienna",
        "agent-uid"       => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
        "general-upgrade" => lambda { AgentVienna::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentVienna::processObjectAndCommand(object, command) }
    }
)

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

# AgentVienna::processObjectAndCommand(object, command)

class AgentVienna

    def self.agentuuid()
        "2ba71d5b-f674-4daf-8106-ce213be2fb0e"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return if !CommonsUtils::isLucille18()
        return if !KeyValueStore::getOrNull(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "2bd883bf-291f-4d9a-8e5c-e2b4883b9b6d:#{CommonsUtils::currentDay()}").nil?
        10.times {
            link = $viennaLinkFeeder.next()
            next if link.nil?
            uuid = SecureRandom.hex(4)
            folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
            FileUtils.mkpath folderpath
            File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
            File.open("#{folderpath}/description.txt", 'w') {|f| f.write(link) }
            schedule = WaveSchedules::makeScheduleObjectTypeNew()
            AgentWave::writeScheduleToDisk(uuid, schedule)
            $viennaLinkFeeder.done(link)
        }
        KeyValueStore::set(CATALYST_COMMON_PATH_TO_KV_REPOSITORY, "2bd883bf-291f-4d9a-8e5c-e2b4883b9b6d:#{CommonsUtils::currentDay()}", "done")
    end

    def self.processObjectAndCommand(object, command)

    end
end

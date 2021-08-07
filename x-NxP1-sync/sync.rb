#!/usr/bin/ruby

# encoding: utf-8

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

# -------------------------------------------------------

=begin

Nx59 {
    "prefix"  : String | null,
    "primary" : String
    "pointId"   : String | null
}

=end

class NamingUtils

    # NamingUtils::extractNxP1IdOrNull(str)
    def self.extractNxP1IdOrNull(str)
        position = str.index("NxP1")
        return nil if position.nil?
        str[position, 13]
    end

    # NamingUtils::extractNxP1NamingOrNull(filename)
    def self.extractNxP1NamingOrNull(filename)
        id = NamingUtils::extractNxP1IdOrNull(filename)
        return nil if id.nil?
        description = filename
            .gsub("(#{id})", "")
            .gsub("[#{id}]", "")
            .gsub(id, "")
            .strip
        {
            "id" => id,
            "description" => description
        }
    end
end

class Points

    # Points::computeTimeTraceOrNull(location)
    def self.computeTimeTraceOrNull(location)
        return nil if !File.exists?(location)
        if File.file?(location) then
            return File.mtime(location).to_time.utc.iso8601
        end
        if File.directory?(location) then
            children = LucilleCore::locationsAtFolder(location)
            return nil if children.empty?
            traces = children.map{|loc| Points::computeTimeTraceOrNull(loc) }.compact
            return nil if traces.empty?
            return traces.max
        end
        raise "3c047c0d-4017-49ba-9b28-851e70a61cb8: #{location}"
    end

    # Points::upgrade(location1, location2)
    def self.upgrade(location1, location2)
        return if !File.exists?(location1)
        return if !File.exists?(location2)

        # location 1 is behind location 2

        puts "upgrade"
        puts "      source (new) ; #{Points::computeTimeTraceOrNull(location2)} : #{location2}"
        puts "      target (old) ; #{Points::computeTimeTraceOrNull(location1)} : #{location1}"

        LucilleCore::pressEnterToContinue()

        LucilleCore::removeFileSystemLocation(location1)
        FileUtils.link_entry(location2, location1)
    end

    # Points::processLocation(location)
    def self.processLocation(location)
        return if !File.exists?(location)
        naming = NamingUtils::extractNxP1NamingOrNull(File.basename(location))
        return if naming.nil?

        pointId = naming["id"]

        locations = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "286b1c73-91fe-4a73-8a3f-6e9c56b7e5f7:#{pointId}", "[]"))
        locations << location
        locations = locations.uniq.select{|l| File.exist?(l) }
        KeyValueStore::set(nil, "286b1c73-91fe-4a73-8a3f-6e9c56b7e5f7:#{pointId}", JSON.generate(locations))

        locations.permutation(2).to_a.each{|pair|
            location1 = pair[0]
            location2 = pair[1]
            next if !File.exists?(location1)
            next if !File.exists?(location2)
            timeTrace1 = Points::computeTimeTraceOrNull(location1)
            timeTrace2 = Points::computeTimeTraceOrNull(location2)
            next if timeTrace1.nil?
            next if timeTrace2.nil?
            next if timeTrace1 == timeTrace2
            if timeTrace1 < timeTrace2 then
                Points::upgrade(location1, location2) # location 1 is behind location 2
            end
            if timeTrace2 < timeTrace1 then
                Points::upgrade(location2, location1)
            end
        }
    end

    # Points::processor()
    def self.processor()
        Find.find("/Users/pascal/Galaxy") do |location|
            Find.prune if location.include?("/Users/pascal/Galaxy/Software/Nyx")
            Find.prune if location.include?("node_modules")
            Find.prune if location.include?("theguardian-github-repositories-Lucille18")
            Points::processLocation(location)
        end
    end



end

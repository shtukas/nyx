#!/Users/pascal/.rvm/rubies/ruby-2.5.1/bin/ruby

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"

# -----------------------------------------------------------------------------

class OpenCycles

    # OpenCycles::getOpenCyclesClaims()
    def self.getOpenCyclesClaims()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles")
            .select{|filename| filename[-5, 5] == '.json' }
            .map{|filename| JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{filename}")) }
            .select{|claim| !PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"]).nil? }
            .sort{|d1, d2| d1["creationTimestamp"] <=> d2["creationTimestamp"] }
    end

    # OpenCycles::saveClaim(claim)
    def self.saveClaim(claim)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
    end

    # OpenCycles::destroy(claim)
    def self.destroy(claim)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # OpenCycles::openClaimTarget(claim)
    def self.openClaimTarget(claim)
        something = PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"])
        return if something.nil?
        PrimaryNetwork::openSomething(something)
    end

    # OpenCycles::claimToString(claim)
    def self.claimToString(claim)
        something = PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"])
        "[opencycle] #{something ? PrimaryNetwork::somethingToString(something) : "data entity not found"}"
    end

    # OpenCycles::claimDive(claim)
    def self.claimDive(claim)
        loop {
            something = PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"])
            if something.nil? then
                puts "Could not determine something for claim #{claim}"
                LucilleCore::pressEnterToContinue()
                return
            end
            options = [
                "access something",
                "destroy claim"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "access something" then
                something = PrimaryNetwork::getSomethingByUuidOrNull(claim["entityuuid"])
                if something.nil? then
                    puts "I could not find a something for his: #{claim}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                PrimaryNetwork::visitSomething(something)
            end
            if option == "destroy claim" then
                OpenCycles::destroy(claim)
                return
            end
        }
    end

    # OpenCycles::management()
    def self.management()
        loop {
            system("clear")
            puts "OpenCycles 🗃️"
            claim = LucilleCore::selectEntityFromListOfEntitiesOrNull("claim", OpenCycles::getOpenCyclesClaims(), lambda {|claim| OpenCycles::claimToString(claim) })
            break if claim.nil?
            OpenCycles::claimDive(claim)
        }
    end
end



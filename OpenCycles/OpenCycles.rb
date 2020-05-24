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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPointsSearch.rb"

# -----------------------------------------------------------------------------

=begin
{
    "datapointuuid": "aedbda15-4227-4652-9e4b-b443d38da538",
    "creationTimestamp": 9
}
=end

class OpenCycles

    # OpenCycles::getOpenCyclesClaims()
    def self.getOpenCyclesClaims()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles")
            .select{|filename| filename[-5, 5] == '.json' }
            .map{|filename|
                JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{filename}")) }
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

    # OpenCycles::claimDive(claim)
    def self.claimDive(claim)
        loop {
            dataentity = DataEntities::getDataEntityByUuidOrNull(claim["entityuuid"])
            if dataentity.nil? then
                puts "Could not determine dataentity for claim #{claim}"
                LucilleCore::pressEnterToContinue()
                return
            end
            options = [
                "access dataentity",
                "destroy claim"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "access dataentity" then
                dataentity = DataEntities::getDataEntityByUuidOrNull(claim["entityuuid"])
                if dataentity.nil? then
                    puts "I could not find a dataentity for his: #{claim}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                DataEntities::dataEntityDive(dataentity)
            end
            if option == "destroy claim" then
                OpenCycles::destroy(claim)
                return
            end
        }
    end
end



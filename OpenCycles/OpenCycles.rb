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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx/Nyx.rb"

# -----------------------------------------------------------------------------

class OpenCycles

    # OpenCycles::openTarget(opencycle)
    def self.openTarget(opencycle)
        something = PrimaryNetwork::getSomethingByUuidOrNull(opencycle["entityuuid"])
        return if something.nil?
        PrimaryNetwork::openSomething(something)
    end

    # OpenCycles::opencycleToString(opencycle)
    def self.opencycleToString(opencycle)
        something = PrimaryNetwork::getSomethingByUuidOrNull(opencycle["entityuuid"])
        "[opencycle] #{something ? PrimaryNetwork::somethingToString(something) : "data entity not found"}"
    end

    # OpenCycles::opencycleDive(opencycle)
    def self.opencycleDive(opencycle)
        loop {
            something = PrimaryNetwork::getSomethingByUuidOrNull(opencycle["entityuuid"])
            if something.nil? then
                puts "Could not determine something for opencycle #{opencycle}"
                LucilleCore::pressEnterToContinue()
                return
            end
            options = [
                "access something",
                "destroy opencycle"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "access something" then
                something = PrimaryNetwork::getSomethingByUuidOrNull(opencycle["entityuuid"])
                if something.nil? then
                    puts "I could not find a something for his: #{opencycle}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                PrimaryNetwork::visitSomething(something)
            end
            if option == "destroy opencycle" then
                NyxNetwork::destroy(opencycle["uuid"])
                return
            end
        }
    end

    # OpenCycles::management()
    def self.management()
        loop {
            system("clear")
            puts "OpenCycles 🗃️"
            opencycle = LucilleCore::selectEntityFromListOfEntitiesOrNull("opencycle", NyxNetwork::getObjects("open-cycle-9fa96e3c-d140-4f82-a7f0-581c918e9e6f"), lambda {|opencycle| OpenCycles::opencycleToString(opencycle) })
            break if opencycle.nil?
            OpenCycles::opencycleDive(opencycle)
        }
    end
end



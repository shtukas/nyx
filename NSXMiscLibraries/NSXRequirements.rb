
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"

REQUIREMENTS_DATA_FILEPATH = "/Galaxy/DataBank/Catalyst/Requirements/data.json"

=begin

RequirementClaim {
    "uuid"                    : String, UUID
    "object-uuid"             : String, UUID
    "requirement-description" : String
}

=end

class NSXRequirements

    # NSXRequirements::getData()
    def self.getData() # Array[RequirementClaim]
        JSON.parse(IO.read(REQUIREMENTS_DATA_FILEPATH))
    end	

    # NSXRequirements::putDataToDisk(dataset)
    def self.putDataToDisk(dataset)
        File.open(REQUIREMENTS_DATA_FILEPATH, "w"){|f| f.puts(JSON.pretty_generate(dataset)) }
    end

    # NSXRequirements::removeClaimFromData(dataset, claim)
    def self.removeClaimFromDataOnDisk(dataset, claim)
        dataset = NSXRequirements::getData().reject{|c| c["uuid"]==claim["uuid"] }
        NSXRequirements::putDataToDisk(dataset)
    end

    # NSXRequirements::issueRequirementClaim(objectuuid, requirementDescription)
    def self.issueRequirementClaim(objectuuid, requirementDescription)
        claim = {}
        claim["uuid"] = SecureRandom.hex
        claim["object-uuid"] = objectuuid
        claim["requirement-description"] = requirementDescription
        NSXRequirements::putDataToDisk( NSXRequirements::getData() + [claim] )
    end

    # NSXRequirements::updateObjectsMetricsToZeroIfPendingClaims(claims, object)
    def self.updateObjectsMetricsToZeroIfPendingClaims(claims, object)
        if claims.map{|claim| claim["object-uuid"]}.include?(object["uuid"]) then
            object["metric"] = 0
        end
        object
    end

    # NSXRequirements::removeClaimsOnDiskIdentifiedByDescription(description)
    def self.removeClaimsOnDiskIdentifiedByDescription(description)
        dataset = NSXRequirements::getData().reject{|c| c["requirement-description"]==description }
        NSXRequirements::putDataToDisk(dataset)
    end    

end

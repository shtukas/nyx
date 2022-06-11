# encoding: UTF-8

class NyxNetworkSpecialCircumstances

    # ---------------------------------------------------------------------
    # Ops (5)

    # NyxNetworkSpecialCircumstances::transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
    def self.transmuteToNavigationNodeAndPutContentsIntoGenesisOrNothing(item)
        if item["nx111"]["type"] != "aion-point" then
            puts "I can only do that with aion-points"
            LucilleCore::pressEnterToContinue()
            return
        end
        item2 = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Genesis",
            "nx111"       => item["nx111"].clone
        }
        puts JSON.pretty_generate(item2)
        Librarian::commit(item2)
        NxArrow::issue(item["uuid"], item2["uuid"])
        item["mikuType"] = "NxNavigation"
        puts JSON.pretty_generate(item)
        Librarian::commit(item)
        puts "Operation completed"
        LucilleCore::pressEnterToContinue()
    end

    # NyxNetworkSpecialCircumstances::uploadAllLocationsOfAFolderAsAionPointChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPointChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issueNewItemAionPointFromLocation(location)
            NxArrow::issue(item["uuid"], child["uuid"])
        }
    end

    # NyxNetworkSpecialCircumstances::uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
    def self.uploadAllLocationsOfAFolderAsAionPrimitiveFilesChildren(item)
        folder = LucilleCore::askQuestionAnswerAsString("folder: ")
        return if !File.exists?(folder)
        return if !File.directory?(folder)
        LucilleCore::locationsAtFolder(folder).each{|location|
            puts "processing: #{location}"
            child = NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
            next if child.nil?
            NxArrow::issue(item["uuid"], child["uuid"])
        }
    end
end

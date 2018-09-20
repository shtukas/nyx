
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"
require "find"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"

# ----------------------------------------------------------------------

=begin

(list) {
    "list-uuid"             : String
    "description"           : String
    "catalyst-object-uuids" : Array[String]
}

=end

# For the moment, we are not doing list manipulations from Lucille19, because of the
# way the data is stored.

# CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH

class ListsOperator

    # ListsOperator::commitListToDisk(list)
    def self.commitListToDisk(list)
        listuuid = list["list-uuid"]
        File.open("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists/#{listuuid}.json", "w") {|f| f.puts(JSON.pretty_generate(list)) }
    end

    # ListsOperator::destroyList(listuuid)
    def self.destroyList(listuuid)
        FileUtils.rm("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists/#{listuuid}.json")
    end

    # ListsOperator::createList(description)
    def self.createList(description)
        listuuid = SecureRandom.hex 
        list = {
            "list-uuid" => listuuid,
            "description" => description,
            "catalyst-object-uuids" => []
        }
        ListsOperator::commitListToDisk(list)
        list
    end

    # ListsOperator::getListByUUIDOrNull(listuuid)
    def self.getListByUUIDOrNull(listuuid)
        return nil if !File.exists?("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists/#{listuuid}.json")
        JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists/#{listuuid}.json"))
    end

    # ListsOperator::getLists()
    def self.getLists()
        lists = []
        Find.find("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists") do |path|
            next if File.basename(path)[-5,5] != '.json'
            lists << JSON.parse(IO.read(path))
        end
        lists
    end

    # ListsOperator::getListsForCatalystObjectUUID(objectuuid): Array[List]
    def self.getListsForCatalystObjectUUID(objectuuid)
        ListsOperator::getLists()
            .select{|list|
                list["catalyst-object-uuids"].include?(objectuuid)
            }
    end

    # ListsOperator::addCatalystObjectUUIDToList(objectuuid, listuuid)
    def self.addCatalystObjectUUIDToList(objectuuid, listuuid)
        list = ListsOperator::getListByUUIDOrNull(listuuid)
        return if list.nil?
        list["catalyst-object-uuids"] << objectuuid
        list["catalyst-object-uuids"] = list["catalyst-object-uuids"].uniq.sort
        ListsOperator::commitListToDisk(list)
    end

    # ListsOperator::allListsCatalystItemsUUID()
    def self.allListsCatalystItemsUUID()
        ListsOperator::getLists()
            .map{|list| list["catalyst-object-uuids"] }
            .flatten
    end

    # ListsOperator::ui_interactivelySelectListOrNull()
    def self.ui_interactivelySelectListOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("list", ListsOperator::getLists(), lambda{|list| list["description"] })
    end

    # ListsOperator::listDive(list)
    def self.listDive(list)
        loop {
            puts "-> #{list["description"]}"
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", ["rename list", "show elements", "remove elements from list", "destroy list"])
            break if operation.nil?
            if operation == "rename list" then
                puts "Not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end
            if operation == "show elements" then
                listObjects = TheFlock::flockObjects().select{ |object| list["catalyst-object-uuids"].include?(object["uuid"]) }
                selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", listObjects, lambda{ |object| CommonsUtils::objectToString(object) })
                next if selectedobject.nil?
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
            end
            if operation == "remove elements from list" then
                loop {
                    listObjects = TheFlock::flockObjects().select{ |object| list["catalyst-object-uuids"].include?(object["uuid"]) }
                    selectedobject = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", listObjects, lambda{ |object| CommonsUtils::objectToString(object) })
                    break if selectedobject.nil?
                    list["catalyst-object-uuids"].delete(selectedobject["uuid"])
                    ListsOperator::commitListToDisk(list)
                }
            end
            if operation == "destroy list" then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy list '#{list["description"]}'? ") then
                    listFilepath = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/System-Data/Lists/#{list["list-uuid"]}.json"
                    FileUtils.rm(listFilepath)
                    break
                end
            end
        }
    end

    # ListsOperator::ui_listsDive()
    def self.ui_listsDive()
        list = ListsOperator::ui_interactivelySelectListOrNull()
        return if list.nil?
        ListsOperator::listDive(list)
    end

end

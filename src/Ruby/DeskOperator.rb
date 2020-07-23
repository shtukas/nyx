
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForNSDataType1(ns1)
    def self.deskFolderpathForNSDataType1(ns1)
        "#{Realms::getDeskFolderpath()}/#{ns1["uuid"]}"
    end

    # DeskOperator::deskFolderpathForNSDataType0CreateIfNotExists(ns1, ns0)
    def self.deskFolderpathForNSDataType0CreateIfNotExists(ns1, ns0)
        desk_folderpath_for_ns1 = DeskOperator::deskFolderpathForNSDataType1(ns1)
        if !File.exists?(desk_folderpath_for_ns1) then
            FileUtils.mkpath(desk_folderpath_for_ns1)
            namedhash = ns0["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_ns1)
            # If the desk_folderpath_for_ns1 folder contains just one folder named after the ns1 itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_ns1.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}", "#{desk_folderpath_for_ns1}/#{ns1["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_ns1}/#{ns1["uuid"]}-lifting", Realms::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns1)
                FileUtils.mv("#{desk_folderpath_for_ns1}-lifting", desk_folderpath_for_ns1)
            end
        end
        desk_folderpath_for_ns1
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        NSDataType1::cubes().each{|ns1|
            puts "ns1: #{ns1["uuid"]}"
            ns0 = NSDataType1::cubeToLastFramesOrNull(ns1)
            next if ns0.nil?
            next if ns0["type"] != "aion-point"
            desk_folderpath_for_ns1 = DeskOperator::deskFolderpathForNSDataType1(ns1)
            next if !File.exists?(desk_folderpath_for_ns1)
            #puts "ns0:"
            #puts JSON.pretty_generate(ns0)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_ns1)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == ns0["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns1)
                next
            end
            newns0 = NSDataType0s::issueAionPoint(namedhash)
            Arrows::issueOrException(ns1, newns0)
            puts "new ns0:"
            puts JSON.pretty_generate(newns0)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns1)
        }
    end
end

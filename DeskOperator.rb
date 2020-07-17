
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForNSDataType1(ns2)
    def self.deskFolderpathForNSDataType1(ns2)
        "#{EstateServices::getDeskFolderpath()}/#{ns2["uuid"]}"
    end

    # DeskOperator::deskFolderpathForNSDataType0CreateIfNotExists(ns2, ns0)
    def self.deskFolderpathForNSDataType0CreateIfNotExists(ns2, ns0)
        desk_folderpath_for_ns2 = DeskOperator::deskFolderpathForNSDataType1(ns2)
        if !File.exists?(desk_folderpath_for_ns2) then
            FileUtils.mkpath(desk_folderpath_for_ns2)
            namedhash = ns0["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_ns2)
            # If the desk_folderpath_for_ns2 folder contains just one folder named after the ns2 itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_ns2.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_ns2}/#{ns2["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_ns2}/#{ns2["uuid"]}", "#{desk_folderpath_for_ns2}/#{ns2["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_ns2}/#{ns2["uuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns2)
                FileUtils.mv("#{desk_folderpath_for_ns2}-lifting", desk_folderpath_for_ns2)
            end
        end
        desk_folderpath_for_ns2
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        NSDataType2s::ns2s().each{|ns2|
            ns0 = NSDataType2s::getLastNSDataType2NSDataType0OrNull(ns2)
            next if ns0.nil?
            next if ns0["type"] != "aion-point"
            desk_folderpath_for_ns2 = DeskOperator::deskFolderpathForNSDataType1(ns2)
            next if !File.exists?(desk_folderpath_for_ns2)
            #puts "ns0:"
            #puts JSON.pretty_generate(ns0)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_ns2)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == ns0["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns2)
                next
            end
            newns0 = NSDataType0s::issueAionNSDataType2(namedhash)
            Arrows::issue(ns2, newns0)
            #puts "new ns0:"
            #puts JSON.pretty_generate(newns0)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns2)
        }
    end
end

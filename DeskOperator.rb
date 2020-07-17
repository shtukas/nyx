
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFlock(ns2)
    def self.deskFolderpathForFlock(ns2)
        "#{EstateServices::getDeskFolderpath()}/#{ns2["uuid"]}"
    end

    # DeskOperator::deskFolderpathForCubeCreateIfNotExists(ns2, cube)
    def self.deskFolderpathForCubeCreateIfNotExists(ns2, cube)
        desk_folderpath_for_ns2 = DeskOperator::deskFolderpathForFlock(ns2)
        if !File.exists?(desk_folderpath_for_ns2) then
            FileUtils.mkpath(desk_folderpath_for_ns2)
            namedhash = cube["namedhash"]
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
            cube = NSDataType2s::getLastNSDataType2CubeOrNull(ns2)
            next if cube.nil?
            next if cube["type"] != "aion-point"
            desk_folderpath_for_ns2 = DeskOperator::deskFolderpathForFlock(ns2)
            next if !File.exists?(desk_folderpath_for_ns2)
            #puts "cube:"
            #puts JSON.pretty_generate(cube)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_ns2)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == cube["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns2)
                next
            end
            newcube = Cubes::issueAionNSDataType2(namedhash)
            Arrows::issue(ns2, newcube)
            #puts "new cube:"
            #puts JSON.pretty_generate(newcube)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_ns2)
        }
    end
end


# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFlock(hypercube)
    def self.deskFolderpathForFlock(hypercube)
        "#{EstateServices::getDeskFolderpath()}/#{hypercube["uuid"]}"
    end

    # DeskOperator::deskFolderpathForCubeCreateIfNotExists(hypercube, cube)
    def self.deskFolderpathForCubeCreateIfNotExists(hypercube, cube)
        desk_folderpath_for_hypercube = DeskOperator::deskFolderpathForFlock(hypercube)
        if !File.exists?(desk_folderpath_for_hypercube) then
            FileUtils.mkpath(desk_folderpath_for_hypercube)
            namedhash = cube["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_hypercube)
            # If the desk_folderpath_for_hypercube folder contains just one folder named after the hypercube itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_hypercube.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_hypercube}/#{hypercube["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_hypercube}/#{hypercube["uuid"]}", "#{desk_folderpath_for_hypercube}/#{hypercube["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_hypercube}/#{hypercube["uuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_hypercube)
                FileUtils.mv("#{desk_folderpath_for_hypercube}-lifting", desk_folderpath_for_hypercube)
            end
        end
        desk_folderpath_for_hypercube
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        NSDataType2s::hypercubes().each{|hypercube|
            cube = NSDataType2s::getLastNSDataType2CubeOrNull(hypercube)
            next if cube.nil?
            next if cube["type"] != "aion-point"
            desk_folderpath_for_hypercube = DeskOperator::deskFolderpathForFlock(hypercube)
            next if !File.exists?(desk_folderpath_for_hypercube)
            #puts "cube:"
            #puts JSON.pretty_generate(cube)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_hypercube)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == cube["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_hypercube)
                next
            end
            newcube = Cubes::issueAionNSDataType2(namedhash)
            Arrows::issue(hypercube, newcube)
            #puts "new cube:"
            #puts JSON.pretty_generate(newcube)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_hypercube)
        }
    end
end

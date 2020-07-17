
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFlock(cube)
    def self.deskFolderpathForFlock(cube)
        "#{EstateServices::getDeskFolderpath()}/#{cube["uuid"]}"
    end

    # DeskOperator::deskFolderpathForFrameCreateIfNotExists(cube, frame)
    def self.deskFolderpathForFrameCreateIfNotExists(cube, frame)
        desk_folderpath_for_cube = DeskOperator::deskFolderpathForFlock(cube)
        if !File.exists?(desk_folderpath_for_cube) then
            FileUtils.mkpath(desk_folderpath_for_cube)
            namedhash = frame["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_cube)
            # If the desk_folderpath_for_cube folder contains just one folder named after the cube itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_cube.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_cube}/#{cube["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_cube}/#{cube["uuid"]}", "#{desk_folderpath_for_cube}/#{cube["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_cube}/#{cube["uuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_cube)
                FileUtils.mv("#{desk_folderpath_for_cube}-lifting", desk_folderpath_for_cube)
            end
        end
        desk_folderpath_for_cube
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Cubes::cubes().each{|cube|
            frame = Cubes::getLastCubeFrameOrNull(cube)
            next if frame.nil?
            next if frame["type"] != "aion-point"
            desk_folderpath_for_cube = DeskOperator::deskFolderpathForFlock(cube)
            next if !File.exists?(desk_folderpath_for_cube)
            #puts "frame:"
            #puts JSON.pretty_generate(frame)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_cube)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == frame["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_cube)
                next
            end
            newframe = Frames::issueAionCube(namedhash)
            Arrows::issue(cube, newframe)
            #puts "new frame:"
            #puts JSON.pretty_generate(newframe)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_cube)
        }
    end
end

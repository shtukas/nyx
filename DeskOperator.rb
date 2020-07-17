
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFlock(hypercube)
    def self.deskFolderpathForFlock(hypercube)
        "#{EstateServices::getDeskFolderpath()}/#{hypercube["uuid"]}"
    end

    # DeskOperator::deskFolderpathForFrameCreateIfNotExists(hypercube, frame)
    def self.deskFolderpathForFrameCreateIfNotExists(hypercube, frame)
        desk_folderpath_for_hypercube = DeskOperator::deskFolderpathForFlock(hypercube)
        if !File.exists?(desk_folderpath_for_hypercube) then
            FileUtils.mkpath(desk_folderpath_for_hypercube)
            namedhash = frame["namedhash"]
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
        Hypercubes::hypercubes().each{|hypercube|
            frame = Hypercubes::getLastHypercubeFrameOrNull(hypercube)
            next if frame.nil?
            next if frame["type"] != "aion-point"
            desk_folderpath_for_hypercube = DeskOperator::deskFolderpathForFlock(hypercube)
            next if !File.exists?(desk_folderpath_for_hypercube)
            #puts "frame:"
            #puts JSON.pretty_generate(frame)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_hypercube)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == frame["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_hypercube)
                next
            end
            newframe = Frames::issueAionHypercube(namedhash)
            Arrows::issue(hypercube, newframe)
            #puts "new frame:"
            #puts JSON.pretty_generate(newframe)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_hypercube)
        }
    end
end

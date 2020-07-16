
# encoding: UTF-8

class DeskOperator

    # DeskOperator::deskFolderpathForFlock(flock)
    def self.deskFolderpathForFlock(flock)
        "#{EstateServices::getDeskFolderpath()}/#{flock["uuid"]}"
    end

    # DeskOperator::deskFolderpathForFrameCreateIfNotExists(flock, frame)
    def self.deskFolderpathForFrameCreateIfNotExists(flock, frame)
        desk_folderpath_for_flock = DeskOperator::deskFolderpathForFlock(flock)
        if !File.exists?(desk_folderpath_for_flock) then
            FileUtils.mkpath(desk_folderpath_for_flock)
            namedhash = frame["namedhash"]
            LibrarianOperator::namedHashExportAtFolder(namedhash, desk_folderpath_for_flock)
            # If the desk_folderpath_for_flock folder contains just one folder named after the flock itself
            # Then this means that we are exporting a previously imported desk_folderpath_for_flock.
            # In such a case we are going to remove the extra folder by moving thigs up...
            if File.exists?("#{desk_folderpath_for_flock}/#{flock["uuid"]}") then
                FileUtils.mv("#{desk_folderpath_for_flock}/#{flock["uuid"]}", "#{desk_folderpath_for_flock}/#{flock["uuid"]}-lifting")
                FileUtils.mv("#{desk_folderpath_for_flock}/#{flock["uuid"]}-lifting", EstateServices::getDeskFolderpath())
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_flock)
                FileUtils.mv("#{desk_folderpath_for_flock}-lifting", desk_folderpath_for_flock)
            end
        end
        desk_folderpath_for_flock
    end

    # DeskOperator::commitDeskChangesToPrimaryRepository()
    def self.commitDeskChangesToPrimaryRepository()
        Flocks::flocks().each{|flock|
            frame = Flocks::getLastFlockFrameOrNull(flock)
            next if frame.nil?
            next if frame["type"] != "aion-point"
            desk_folderpath_for_flock = DeskOperator::deskFolderpathForFlock(flock)
            next if !File.exists?(desk_folderpath_for_flock)
            #puts "frame:"
            #puts JSON.pretty_generate(frame)
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(desk_folderpath_for_flock)
            #puts "namedhash from folder: #{namedhash}"
            if namedhash == frame["namedhash"] then
                LucilleCore::removeFileSystemLocation(desk_folderpath_for_flock)
                next
            end
            newframe = Frames::issueAionCube(namedhash)
            Arrows::issue(flock, newframe)
            #puts "new frame:"
            #puts JSON.pretty_generate(newframe)
            LucilleCore::removeFileSystemLocation(desk_folderpath_for_flock)
        }
    end
end

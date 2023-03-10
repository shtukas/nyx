
# encoding: UTF-8

# -----------------------------------------------------------------------

class Fsck

    # Fsck::checkEntity(object)
    def self.checkEntity(object)
        if object["entityType"] == "Nx27" then
            if object["type"] == "unique-string" then
                # Nothing to do
                return true
            end
            if object["type"] == "url" then
                # Nothing to do
                return true
            end
            if object["type"] == "text" then
                return !BinaryBlobsService::getBlobOrNull(object["nhash"]).nil?
            end
            if object["type"] == "aion-point" then
                return AionFsck::structureCheckAionHash(Elizabeth.new(), object["nhash"])
            end
            raise "be51fe9f-f41e-4616-9dcd-3d58acf03f98: #{object}"
        end
        if object["entityType"] == "Nx10" then
            return true
        end
        if object["entityType"] == "NxDirectory3" then
            return true
        end
        raise "cd97f89c-5fad-4b21-a365-65a0ad9228a9: #{object}"
    end

    # Fsck::fsckEntities()
    def self.fsckEntities()
        NyxEntities::entities().each{|entity|
            puts "checking: uuid: #{entity["uuid"]}, #{entity["entityType"]}"
            status = Fsck::checkEntity(entity)
            if !status then
                puts JSON.pretty_generate(entity).red
                puts "Failed".red
                LucilleCore::pressEntryToContinue()
            end
        }
    end

end

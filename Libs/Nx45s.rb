
# encoding: UTF-8

class Nx45s

    # ----------------------------------------------------------------------
    # IO

    # Nx45s::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx45")
    end

    # Nx45s::getOrNull(uuid): null or Nx45
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx45s::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx45s::nx45Id()
    def self.nx45Id()
        str1 = Time.new.strftime("%Y%m%d%H%M%S%6N")
        str2 = str1[0, 6]
        str3 = str1[6, 4]
        str4 = str1[10, 4]
        str5 = str1[14, 4]
        str6 = str1[18, 2]
        str7 = SecureRandom.hex[0, 10]
        "10#{str2}-#{str3}-#{str4}-#{str5}-#{str6}#{str7}"
    end

    # Nx45s::readPrimitiveFileOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.readPrimitiveFileOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)

        dottedExtension = File.extname(filepath)

        nhash = Librarian0Utils::filepathToContentHash(filepath)

        lambdaBlobCommitReturnNhash = lambda {|blob|
            Librarian12EnergyGrid::putBlob(blob)
        }
        parts = Librarian0Utils::commitFileReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)

        return [dottedExtension, nhash, parts]
    end

    # Nx45s::createNewOrNull(filepath)
    def self.createNewOrNull(filepath)

        data = Nx45s::readPrimitiveFileOrNull(filepath)
        return nil if data.nil?

        dottedExtension, nhash, parts = data

        item = {
          "uuid"            => Nx45s::nx45Id(),
          "mikuType"        => "Nx45",
          "description"     => nil,
          "unixtime"        => Time.new.to_f,
          "datetime"        => Time.new.utc.iso8601,
          "dottedExtension" => dottedExtension,
          "nhash"           => nhash,
          "parts"           => parts
        }
        Librarian6Objects::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx45s::toString(item)
    def self.toString(item)
        body = item["uuid"]
        if item["description"] then
            body = item["description"]
        end
        "(primitive file) #{body}#{item["dottedExtension"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx45s::exportItemAtLocation(item, location) # targetFilepath
    def self.exportItemAtLocation(item, location)
        targetFilepath = "#{location}/#{item["uuid"]}#{item["dottedExtension"]}"
        File.open(targetFilepath, "w"){|f|  
            item["parts"].each{|nhash|
                blob = Librarian12EnergyGrid::getBlobOrNull(nhash)
                raise "(error: c3e18110-2d9a-42e6-9199-6f8564cf96d2)" if blob.nil?
                f.write(blob)
            }
        }
        targetFilepath
    end

    # Nx45s::landing(item)
    def self.landing(item)
        item = Nx45s::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
        return if item.nil?

        puts "Landing..."

        return if !LucilleCore::askQuestionAnswerAsBoolean("Access primitive file '#{Nx45s::toString(item)}' ? ")

        targetFilepath = Nx45s::exportItemAtLocation(item, "/Users/pascal/Desktop")

        puts "File written to Desktop. Going to remove when we continue."
        LucilleCore::pressEnterToContinue()

        if File.exists?(targetFilepath) then
            if LucilleCore::askQuestionAnswerAsBoolean("remove file ? ") then
                FileUtils.rm(targetFilepath)
            end
        end
    end
end

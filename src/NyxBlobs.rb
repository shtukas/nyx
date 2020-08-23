# encoding: UTF-8

class NyxBlobs

    # -----------------------------------------------
    # Private

    # -----------------------------------------------
    # Months Logic

    # NyxBlobs::getCurrentMonth()
    def self.getCurrentMonth()
        "#{Time.new.strftime("%Y-%m")}"
    end

    # NyxBlobs::getAllMonths()
    def self.getAllMonths()
        Dir.entries("#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Blobs-X1")
            .select{|filename| filename[4, 1] == "-" }
    end

    # NyxBlobs::getPastMonths()
    def self.getPastMonths()
        months = NyxBlobs::getAllMonths() - [ NyxBlobs::getCurrentMonth() ]
        months.sort
    end

    # NyxBlobs::getFilepathAtMonthNamedHash(month, namedhash)
    def self.getFilepathAtMonthNamedHash(month, namedhash)
        if namedhash.start_with?("SHA256-") then
            ns01 = namedhash[7, 2]
            ns02 = namedhash[9, 2]
            filepath = "#{Miscellaneous::catalystDataCenterFolderpath()}/Nyx-Blobs-X1/#{month}/#{ns01}/#{ns02}/#{namedhash}.data"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            return filepath
        end
        raise "[NyxPrimaryStoreUtils: 7ef6ca36-2a35-4190-b3f6-ee661a796f59]"
    end

    # NyxBlobs::thisMonthFilepath(namedhash)
    def self.thisMonthFilepath(namedhash)
        month = NyxBlobs::getCurrentMonth()
        NyxBlobs::getFilepathAtMonthNamedHash(month, namedhash)
    end

    # NyxBlobs::getPastMonthsFilepaths(namedhash)
    def self.getPastMonthsFilepaths(namedhash)
        NyxBlobs::getPastMonths()
            .map{|month| NyxBlobs::getFilepathAtMonthNamedHash(month, namedhash) }
    end

    # NyxBlobs::deleteFiles(filepaths)
    def self.deleteFiles(filepaths)
        filepaths.each{|filepath|
            next if !File.exists?(filepath)
            FileUtils::rm(filepath)
        }
    end

    # NyxBlobs::deleteLegacyFiles(namedhash)
    def self.deleteLegacyFiles(namedhash)
        NyxBlobs::deleteFiles( NyxBlobs::getPastMonthsFilepaths(namedhash) )
    end

    # -----------------------------------------------
    # Public

    # NyxBlobs::put(blob) # namedhash
    def self.put(blob)
        namedhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = NyxBlobs::thisMonthFilepath(namedhash)
        File.open(filepath, "w") {|f| f.write(blob) }

        NyxBlobs::deleteLegacyFiles(namedhash)

        namedhash
    end

    # NyxBlobs::getBlobOrNull(namedhash)
    def self.getBlobOrNull(namedhash)

        NyxBlobs::getPastMonthsFilepaths(namedhash).each{|filepath|
            if File.exists?(filepath) then
                blob = IO.read(filepath)
                namedhash2 = NyxBlobs::put(blob)
                if namedhash2 != namedhash then
                    puts "filepath: #{filepath}"
                    puts "namedhash: #{namedhash}"
                    raise "[serious error: 03e1614d-a21e-4f37-a108-d19c06a99950]"
                end
                NyxBlobs::deleteLegacyFiles(namedhash)
                return blob
            end
        }

        filepath = NyxBlobs::thisMonthFilepath(namedhash)
        return nil if !File.exists?(filepath)
        IO.read(filepath)
    end
end

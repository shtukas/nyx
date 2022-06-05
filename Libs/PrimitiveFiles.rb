
# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::commitFileReturnPartsHashsImproved(filepath, committer)
    def self.commitFileReturnPartsHashsImproved(filepath, committer)
        raise "[a324c706-3867-4fbb-b0de-f8c2edd2d110, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[fba5194d-cad3-4766-953e-a994923925fe, filepath: #{filepath}]" if !File.file?(filepath)
        hashes = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            hashes << committer.call(blob)
        end
        f.close()
        hashes
    end

    # -------------------------------------------------
    # Import

    # PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(objectuuid, filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(objectuuid, filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
 
        dottedExtension = File.extname(filepath)
 
        nhash = CommonUtils::filepathToContentHash(filepath)
 
        committer = lambda {|blob|
            EnergyGridElizabeth.new().commitBlob(blob)
        }
        parts = PrimitiveFiles::commitFileReturnPartsHashsImproved(filepath, committer)
 
        return [dottedExtension, nhash, parts]
    end

    # PrimitiveFiles::locationToPrimitiveFileNx111OrNull(objectuuid, nx111uuid, filepath)
    def self.locationToPrimitiveFileNx111OrNull(objectuuid, nx111uuid, filepath)
        data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(objectuuid, filepath)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "uuid"  => nx111uuid,
            "type"  => "primitive-file",
            "dottedExtension" => dottedExtension,
            "nhash" => nhash,
            "parts" => parts
        }
    end

    # -------------------------------------------------
    # Export

    # PrimitiveFiles::exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, itemuuid, dottedExtension, parts) # targetFilepath
    def self.exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, itemuuid, dottedExtension, parts)
        targetFilepath = "#{exportFolderpath}/#{itemuuid}#{dottedExtension}"
        File.open(targetFilepath, "w"){|f|  
            parts.each{|nhash|
                blob = EnergyGridElizabeth.new().getBlobOrNull(nhash)
                raise "(error: c3e18110-2d9a-42e6-9199-6f8564cf96d2)" if blob.nil?
                f.write(blob)
            }
        }
        targetFilepath
    end

    # PrimitiveFiles::writePrimitiveFileAtEditionDeskReturnFilepath(item, nx111) # Often the nx111 is the nx111 of the item
    def self.writePrimitiveFileAtEditionDeskReturnFilepath(item, nx111)
        dottedExtension = nx111["dottedExtension"]
        nhash = nx111["nhash"]
        parts = nx111["parts"]
        filepath = "#{EditionDesk::decideEditionLocation(item, nx111)}#{dottedExtension}"
        File.open(filepath, "w"){|f|  
            parts.each{|nhash|
                blob = EnergyGridElizabeth.new().getBlobOrNull(nhash)
                raise "(error: 416666c5-3d7a-491b-a08f-1994c5adfc86)" if blob.nil?
                f.write(blob)
            }
        }
        filepath
    end

    # PrimitiveFiles::writePrimitiveFileAtEditionDeskCarrierFolderReturnFilepath(item, dirname, nx111) # Often the nx111 is the nx111 of the item
    def self.writePrimitiveFileAtEditionDeskCarrierFolderReturnFilepath(item, dirname, nx111)
        dottedExtension = nx111["dottedExtension"]
        nhash = nx111["nhash"]
        parts = nx111["parts"]
        filepath = "#{EditionDesk::pathToEditionDesk()}/#{dirname}/#{item["uuid"]}#{dottedExtension}"
        File.open(filepath, "w"){|f|  
            parts.each{|nhash|
                blob = EnergyGridElizabeth.new().getBlobOrNull(nhash)
                raise "(error: 416666c5-3d7a-491b-a08f-1994c5adfc86)" if blob.nil?
                f.write(blob)
            }
        }
        filepath
    end

end

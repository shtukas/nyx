
# encoding: UTF-8

class PrimitiveFiles

    # -------------------------------------------------
    # Import

    # PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(filepath) # [dottedExtension, nhash, parts]
    def self.locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if !File.exists?(filepath)
        return nil if !File.file?(filepath)
 
        dottedExtension = File.extname(filepath)
 
        nhash = Librarian0Utils::filepathToContentHash(filepath)
 
        lambdaBlobCommitReturnNhash = lambda {|blob|
            InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::putBlob(blob)
        }
        parts = Librarian0Utils::commitFileToXCacheReturnPartsHashsImproved(filepath, lambdaBlobCommitReturnNhash)
 
        return [dottedExtension, nhash, parts]
    end

    # PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, filepath)
    def self.locationToPrimitiveFileNx111OrNull(uuid, filepath)
        data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(filepath)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        {
            "uuid"  => uuid,
            "type"  => "primitive-file",
            "dottedExtension" => dottedExtension,
            "nhash" => nhash,
            "parts" => parts
        }
    end

    # -------------------------------------------------
    # Export

    # PrimitiveFiles::exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, someuuid, dottedExtension, parts) # targetFilepath
    def self.exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, someuuid, dottedExtension, parts)
        targetFilepath = "#{exportFolderpath}/#{someuuid}#{dottedExtension}"
        File.open(targetFilepath, "w"){|f|  
            parts.each{|nhash|
                blob = InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
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
        filepath = "#{EditionDesk::exportLocation(item)}#{dottedExtension}"
        File.open(filepath, "w"){|f|  
            parts.each{|nhash|
                blob = InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
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
                blob = InfinityDatablobs_InfinityBufferOutAndXCache_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
                raise "(error: 416666c5-3d7a-491b-a08f-1994c5adfc86)" if blob.nil?
                f.write(blob)
            }
        }
        filepath
    end

end

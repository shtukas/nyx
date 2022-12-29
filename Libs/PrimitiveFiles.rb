# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::commitFileReturnDataElements(filepath) # [dottedExtension, nhash, parts]
    def self.commitFileReturnDataElements(filepath)
        raise "[4b23d843-1960-4c19-b0bb-4bf4ea9f14b4, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[43d2b5e1-06d5-4dc9-844c-c04bf353dfba, filepath: #{filepath}]" if !File.file?(filepath)

        dottedExtension = File.extname(filepath)

        nhash = CommonUtils::filepathToContentHash(filepath)

        operator = DatablobStoreElizabeth.new()

        parts = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            parts << operator.putBlob(blob)
        end
        f.close()

        [dottedExtension, nhash, parts]
    end

    # PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, verbose)
    def self.fsckPrimitiveFileDataRaiseAtFirstError(dottedExtension, nhash, parts, verbose)
        if verbose then
            puts "PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(#{dottedExtension}, #{nhash}, #{parts}, #{verbose})"
        end
        if dottedExtension[0, 1] != "." then
            puts "dottedExtension: #{dottedExtension}".red
            puts "primitive parts, dotted extension is malformed".red
            raise "(error: 02:36)"
        end
        operator = DatablobStoreElizabeth.new()
        parts.each{|nhash|
            blob = operator.getBlobOrNull(nhash)
            if blob.nil? then
                puts "primitive parts, nhash not found: #{nhash}".red
                raise "(error: 02:33)"
            end
        }
    end
end

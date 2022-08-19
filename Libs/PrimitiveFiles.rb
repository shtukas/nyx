# encoding: UTF-8

class PrimitiveFiles

    # PrimitiveFiles::commitFileReturnDataElements(filepath, operator) # [dottedExtension, nhash, parts]
    def self.commitFileReturnDataElements(filepath, operator)
        raise "[4b23d843-1960-4c19-b0bb-4bf4ea9f14b4, filepath: #{filepath}]" if !File.exists?(filepath)
        raise "[43d2b5e1-06d5-4dc9-844c-c04bf353dfba, filepath: #{filepath}]" if !File.file?(filepath)

        dottedExtension = File.extname(filepath)

        nhash = CommonUtils::filepathToContentHash(filepath)

        parts = []
        partSizeInBytes = 1024*1024 # 1 MegaBytes
        f = File.open(filepath)
        while ( blob = f.read(partSizeInBytes) ) do
            parts << operator.putBlob(blob)
        end
        f.close()

        [dottedExtension, nhash, parts]
    end

    # PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts)
    def self.fsckPrimitiveFileDataRaiseAtFirstError(operator, dottedExtension, nhash, parts)
        puts "PrimitiveFiles::fsckPrimitiveFileDataRaiseAtFirstError(operator, #{dottedExtension}, #{nhash}, #{parts})"
        if dottedExtension[0, 1] != "." then
            puts "objectuuid: #{objectuuid}".red
            puts "nx111: #{nx111}".red
            puts "primitive parts, dotted extension is malformed".red
            raise "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
        end
        parts.each{|nhash|
            blob = operator.getBlobOrNull(nhash)
            if blob.nil? then
                puts "objectuuid: #{objectuuid}".red
                puts "nx111: #{nx111}".red
                puts "nhash: #{nhash}".red
                puts "primitive parts, nhash not found: #{nhash}".red
                raise "Nx111::fsckNx111NoRepeatErrorAtFirstFailure(objectuuid: #{objectuuid}, nx111: #{nx111})"
            end
        }
    end
end

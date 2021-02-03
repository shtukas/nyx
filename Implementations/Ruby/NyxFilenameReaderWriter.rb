
# encoding: UTF-8

class NyxFilenameReaderWriter

    # NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(filename)
    def self.extractNX141MarkerFromFilenameOrNull(filename)
        # From the convention 
        # NX141-[*], where [*] is a string of unspecified length with no space and no dot.
        correction = lambda {|str|
            if str.include?(' ') then
                return correction.call(str[0, str.size-1])
            end
            if str.include?('.') then
                return correction.call(str[0, str.size-1])
            end
            str
        }
        if filename.include?('NX141-') then
            extraction = filename[filename.index('NX141-'), filename.size]
            return correction.call(extraction)
        end
        nil
    end

    # NyxFilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
    def self.extractNX141MarkerFromLocationOrNull(location)
        NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(File.basename(location))
    end

    # NyxFilenameReaderWriter::extractDescriptionFromFilename(filename)
    def self.extractDescriptionFromFilename(filename)
        nx141 = NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(filename)
        if nx141 then
            filename = filename.gsub(nx141, "")
        end
        while filename.include?('.') do
            filename = filename[0, filename.size-1]
        end
        filename.strip
    end

    # NyxFilenameReaderWriter::extractDescriptionFromLocation(location)
    def self.extractDescriptionFromLocation(location)
        NyxFilenameReaderWriter::extractDescriptionFromFilename(File.basename(location))
    end

    # NyxFilenameReaderWriter::extractFileExtensionOrNull(filename)
    def self.extractFileExtensionOrNull(filename)
        File.extname(filename)
    end

    # NyxFilenameReaderWriter::makeLocationname(description, nx141mark, extension)
    def self.makeLocationname(description, nx141mark, extension)
        "#{description} #{nx141mark}#{extension ? extension : ""}"
    end

    # NyxFilenameReaderWriter::ensureLocationname(location, description, nx141mark, extension)
    def self.ensureLocationname(location, description, nx141mark, extension)
        raise "7fa0acb3-02cc-4c36-9ff7-a85a747bad94" if !File.exists?(location)
        return if (File.basename(location) == NyxFilenameReaderWriter::makeLocationname(description, nx141mark, extension))
        location2 = "#{File.dirname(location)}/#{NyxFilenameReaderWriter::makeLocationname(description, nx141mark, extension)}"
        FileUtils.mv(location, location2)
    end

    # NyxFilenameReaderWriter::ensureDescriptionAtLocation(location, description)
    def self.ensureDescriptionAtLocation(location, description)
        nx141mark = NyxFilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
        return if nx141mark.nil?
        extension = NyxFilenameReaderWriter::extractFileExtensionOrNull(File.basename(location))
        NyxFilenameReaderWriter::ensureLocationname(location, description, nx141mark, extension)
    end

    # NyxFilenameReaderWriter::getFSChildrenWhichAreNX141(location)
    def self.getFSChildrenWhichAreNX141(location)
        return [] if File.file?(location)
        LucilleCore::locationsAtFolder(location).select{|l| NyxFilenameReaderWriter::extractNX141MarkerFromLocationOrNull(l) }
    end

    # NyxFilenameReaderWriter::selfTest()
    def self.selfTest()
        raise "[01]" if NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141 1234567.txt")    != nil
        raise "[02]" if NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141-1234567")        != "NX141-1234567"
        raise "[03]" if NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("00 NX141-1234567")     != "NX141-1234567"
        raise "[04]" if NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141-1234567 00")     != "NX141-1234567"
        raise "[05]" if NyxFilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("00 NX141-1234567.txt") != "NX141-1234567"

        raise "[06]" if NyxFilenameReaderWriter::extractDescriptionFromFilename("NX141 1234567.txt")          != "NX141 1234567"
        raise "[07]" if NyxFilenameReaderWriter::extractDescriptionFromFilename("NX141-1234567")              != ""
        raise "[08]" if NyxFilenameReaderWriter::extractDescriptionFromFilename("00 NX141-1234567")           != "00"
        raise "[09]" if NyxFilenameReaderWriter::extractDescriptionFromFilename("NX141-1234567 00")           != "00"
        raise "[10]" if NyxFilenameReaderWriter::extractDescriptionFromFilename("00 NX141-1234567 AA.txt")    != "00  AA"
    end
end

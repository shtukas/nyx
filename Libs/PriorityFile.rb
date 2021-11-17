# encoding: UTF-8

class PriorityFile

    # PriorityFile::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # PriorityFile::catalystSafe(filepath)
    def self.catalystSafe(filepath)
        targetFilePath = "/Users/pascal/x-space/catalyst-safe/#{Time.new.to_s[0, 4]}/#{Time.new.to_s[0, 7]}/#{LucilleCore::timeStringL22()}-#{File.basename(filepath)}"
        if !File.exists?(File.dirname(targetFilePath)) then
            FileUtils.mkpath(File.dirname(targetFilePath))
        end
        FileUtils.cp(filepath, targetFilePath)
    end
end

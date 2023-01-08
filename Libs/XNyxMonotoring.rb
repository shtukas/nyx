
class XNyxMonotoring

    # XNyxMonotoring::countOrNull()
    def self.countOrNull()
        folderpath = "/Users/pascal/Galaxy/X-Nyx"
        return nil if !File.exists?(folderpath)
        LucilleCore::locationsAtFolder(folderpath).count
    end
end
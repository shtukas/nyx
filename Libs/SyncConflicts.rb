class SyncConflicts

    # .sync-conflict-20

    # SyncConflicts::getConflictFileOrNull()
    def self.getConflictFileOrNull()
        Find.find(Config::pathToDataCenter()) do |path|
            if File.basename(path).include?(".sync-conflict-20") then
                return path
            end
        end
        nil
    end
end

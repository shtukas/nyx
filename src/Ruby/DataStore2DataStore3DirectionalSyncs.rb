
# encoding: UTF-8

=begin

Here we perform the synchronization between the primary docnet repository and the local github repository.

=end

class DataStore2DataStore3DirectionalSyncs

    # DataStore2DataStore3DirectionalSyncs::store2NyxObjectFilenameToStore3Filepath(filename)
    def self.store2NyxObjectFilenameToStore3Filepath(filename)
        raise "[error: 453e28db]" if !Realms::isDocnet()
        # filename
        # 000c1c5d63c2325b129768131b19be20dfe593cb4e97511545dd4e9912950b65.json
        ns01 = filename[0, 2]
        ns02 = filename[2, 2]
        filepath = "#{Realms::pathToGitHubRepositoryDataStore1()}/Nyx-001/Nyx-Objects/#{ns01}/#{ns02}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # DataStore2DataStore3DirectionalSyncs::store2NyxBlobFilenameToStore3Filepath(filename)
    def self.store2NyxBlobFilenameToStore3Filepath(filename)
        raise "[error: 78704cf1]" if !Realms::isDocnet()
        # filename
        # SHA256-00008077382c6e8e2763c416bb703bf39ef2227b85b4671d107f5d92b629c2d7.data
        ns01 = filename[7, 2]
        ns02 = filename[9, 2]
        filepath = "#{Realms::pathToGitHubRepositoryDataStore1()}/Nyx-001/Nyx-Blobs/#{ns01}/#{ns02}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # DataStore2DataStore3DirectionalSyncs::store2ToStore3Update()
    def self.store2ToStore3Update()
        # ------------------------------------------------------------------------------------
        raise "[error: 31e731d9]" if !Realms::isDocnet()
        raise "[error: 0858ca96]" if !Realms::primaryDataStoreFolderPath().include?(".docnet")
        raise "[error: a5e85d2a]" if !Realms::primaryDataStoreFolderPath().include?("002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93")
        # I confirm, we really do not want this to run against the catalyst primary data store
        # ------------------------------------------------------------------------------------
        Find.find("#{Realms::primaryDataStoreFolderPath()}/Nyx/Nyx-Objects") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".json"
            filename = File.basename(path)
            targetFilepath = DataStore2DataStore3DirectionalSyncs::store2NyxObjectFilenameToStore3Filepath(filename)
            next if File.file?(targetFilepath)
            puts "copying: #{File.basename(path)}"
            FileUtils.cp(path, targetFilepath)
        end
        Find.find("#{Realms::primaryDataStoreFolderPath()}/Nyx/Nyx-Blobs") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".data"
            filename = File.basename(path)
            targetFilepath = DataStore2DataStore3DirectionalSyncs::store2NyxBlobFilenameToStore3Filepath(filename)
            next if File.file?(targetFilepath)
            puts "copying: #{File.basename(path)}"
            FileUtils.cp(path, targetFilepath)
        end
    end

    # DataStore2DataStore3DirectionalSyncs::store3NyxObjectFilenameToStore2Filepath(filename)
    def self.store3NyxObjectFilenameToStore2Filepath(filename)
        raise "[error: d669ff61]" if !Realms::isDocnet()
        # filename
        # 000c1c5d63c2325b129768131b19be20dfe593cb4e97511545dd4e9912950b65.json
        ns01 = filename[0, 2]
        ns02 = filename[2, 2]
        filepath = "#{Realms::primaryDataStoreFolderPath()}/Nyx/Nyx-Objects/#{ns01}/#{ns02}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # DataStore2DataStore3DirectionalSyncs::store3NyxBlobFilenameStore3Filepath(filename)
    def self.store3NyxBlobFilenameStore3Filepath(filename)
        raise "[error: 2157fd04]" if !Realms::isDocnet()
        # filename
        # SHA256-00008077382c6e8e2763c416bb703bf39ef2227b85b4671d107f5d92b629c2d7.data
        ns01 = filename[7, 2]
        ns02 = filename[9, 2]
        filepath = "#{Realms::primaryDataStoreFolderPath()}/Nyx/Nyx-Blobs/#{ns01}/#{ns02}/#{filename}"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        return filepath
    end

    # DataStore2DataStore3DirectionalSyncs::store3ToStore2Update()
    def self.store3ToStore2Update()
        # ------------------------------------------------------------------------------------
        raise "[error: fea49307]" if !Realms::isDocnet()
        raise "[error: 7e089def]" if !Realms::primaryDataStoreFolderPath().include?(".docnet")
        raise "[error: 0eb0c681]" if !Realms::primaryDataStoreFolderPath().include?("002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93")
        # I confirm, we really do not want this to run against the catalyst primary data store
        # ------------------------------------------------------------------------------------
        Find.find("#{Realms::pathToGitHubRepositoryDataStore1()}/Nyx-001/Nyx-Objects") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".json"
            filename = File.basename(path)
            targetFilepath = DataStore2DataStore3DirectionalSyncs::store3NyxObjectFilenameToStore2Filepath(filename)
            next if File.file?(targetFilepath)
            puts "copying: #{File.basename(path)}"
            puts path
            puts targetFilepath
            next
            FileUtils.cp(path, targetFilepath)
        end
        return
        Find.find("#{Realms::pathToGitHubRepositoryDataStore1()}/Nyx-001/Nyx-Blobs") do |path|
            next if !File.file?(path)
            next if path[-5, 5] != ".data"
            filename = File.basename(path)
            targetFilepath = DataStore2DataStore3DirectionalSyncs::store3NyxBlobFilenameStore3Filepath(filename)
            next if File.file?(targetFilepath)
            puts "copying: #{File.basename(path)}"
            FileUtils.cp(path, targetFilepath)
        end
    end

end

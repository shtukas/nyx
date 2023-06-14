# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

class DarkMatter

    # DarkMatter::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        filepath = "#{folderpath}/#{nhash}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath)
    end

    # DarkMatter::putBlob(datablob) # nhash
    def self.putBlob(datablob) # nhash
        nhash = "SHA256-#{Digest::SHA256.hexdigest(datablob)}"
        puts "DarkMatter put blob: nhash: #{nhash}".green
        fragment1 = nhash[7, 2]
        fragment2 = nhash[9, 2]
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkMatter/2023-06/#{fragment1}/#{fragment2}"
        if !File.exist?(folderpath) then
            FileUtils.mkpath(folderpath)
        end
        filepath = "#{folderpath}/#{nhash}.data"
        File.open(filepath, "w"){|f| f.write(datablob) }
        nhash2 = "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
        if nhash2 != nhash then
            raise "DarkMatter put blob: check of the file failed (nhash: #{nhash})"
            exit
        end
        nhash
    end
end

class DarkMatterElizabeth

    def initialize()
    end

    def putBlob(datablob) # nhash
        DarkMatter::putBlob(datablob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def getBlobOrNull(nhash)
        DarkMatter::getBlobOrNull(nhash)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = getBlobOrNull(nhash)
        return blob if blob
        raise "(error: 7e168c83-2720-4299-bdba-de5c3cca9c0a, nhash: #{nhash})"
    end

    def datablobCheck(nhash)
        begin
            blob = readBlobErrorIfNotFound(nhash)
            status = ("SHA256-#{Digest::SHA256.hexdigest(blob)}" == nhash)
            if !status then
                puts "(error: c8b47339-03c3-484c-9207-c2106e88acb7) incorrect blob, exists but doesn't have the right nhash: #{nhash}"
            end
            return status
        rescue
            false
        end
    end
end

# create table energy (uuid string primary key, mikuType string, item string);

class PositiveSpace

    # PositiveSpace::databaseFilepath()
    def self.databaseFilepath()
        filepath = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/01-database")
                    .select{|location| location[-8, 8] == ".sqlite3" }
                    .first
        if filepath.nil? then
            raise "PositiveSpace could not locate database"
        end
        filepath
    end

    # PositiveSpace::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # PositiveSpace::getFirstJournalItemOrNull()
    def self.getFirstJournalItemOrNull()
        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .first
    end

    # PositiveSpace::database_destroy(uuid)
    def self.database_destroy(uuid)
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from energy where uuid=?", [uuid]
        db.close
    end

    # PositiveSpace::database_commit(item)
    def self.database_commit(item)
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from energy where uuid=?", [item["uuid"]]
        db.execute "insert into energy (uuid, mikuType, item) values (?, ?, ?)", [item["uuid"], item["mikuType"], JSON.generate(item)]
        db.close
    end

    # PositiveSpace::isLeaderInstance()
    def self.isLeaderInstance()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Stargate-Config.json"))["isLeaderInstance"]
    end

    # PositiveSpace::ageOrNull()
    def self.ageOrNull()
        filepaths = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
                        .select{|location| location[-5, 5] == ".json" }
        return nil if filepaths.empty?
        filepaths.map{|filepath| Time.new.to_f - File.mtime(filepath).to_i }.min
    end

    # PositiveSpace::maintenance()
    def self.maintenance()
        return if !PositiveSpace::isLeaderInstance()
        age = PositiveSpace::ageOrNull()
        return if age.nil?
        return if age < 60
        loop {
            filepath = PositiveSpace::getFirstJournalItemOrNull()
            break if filepath.nil?
            puts "PositiveSpace::maintenance(): journal process: #{filepath}".green
            item = JSON.parse(IO.read(filepath))
            if item["mikuType"] == "NxDeleted" then
                PositiveSpace::database_destroy(item["uuid"])
            else
                PositiveSpace::database_commit(item)
            end
            FileUtils.rm(filepath)
        }
    end
end

class DarkEnergy

    # DarkEnergy::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        # First we read the database and then we read the journal

        filepath = PositiveSpace::databaseFilepath()

        item = nil
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy where uuid=?", [uuid]) do |row|
            item = JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["uuid"] == uuid then
                    if i["mikuType"] == "NxDeleted" then
                        return nil
                    else
                        item = i
                    end
                    
                end
            }

        item
    end

    # DarkEnergy::commit(item)
    def self.commit(item)
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal"
        filename = "#{PositiveSpace::timeStringL22()}.item.json"
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # DarkEnergy::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["mikuType"] == "NxDeleted" then
                    # This item that carry the NxDeleted, we do not know what was its mikuType before it was deleted
                    # So we are always doing the reject
                    items = items.reject{|x| x["uuid"] == i["uuid"] }
                else
                    # Here we need to handle both cases, because the item may have varying mikuTypes in the journal
                    if i["mikuType"] == mikuType then
                        items = items.reject{|x| x["uuid"] == i["uuid"]} + [i]
                    else
                        items = items.reject{|x| x["uuid"] == i["uuid"]}
                    end
                end
            }

        items
    end

    # DarkEnergy::all()
    def self.all()
        items = []
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from energy", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close

        LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal")
            .select{|location| location[-5, 5] == ".json" }
            .sort
            .each{|filepath|
                i = JSON.parse(IO.read(filepath))
                if i["mikuType"] == "NxDeleted" then
                    # This item that carry the NxDeleted, we do not know what was its mikuType before it was deleted
                    # So we are always doing the reject
                    items = items.reject{|x| x["uuid"] == i["uuid"] }
                else
                    items = items.reject{|x| x["uuid"] == i["uuid"]} + [i]
                end
            }

        items
    end

    # DarkEnergy::destroy(uuid)
    def self.destroy(uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted"
        }
        folderpath = "#{ENV['HOME']}/Galaxy/DataHub/DeepSpace/DarkEnergy/02-journal"
        filename = "#{PositiveSpace::timeStringL22()}.delete.json"
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # -------------------------------------------

    # DarkEnergy::init(mikuType, uuid)
    def self.init(mikuType, uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => mikuType
        }
        DarkEnergy::commit(item)
    end

    # DarkEnergy::patch(uuid, attribute, value)
    def self.patch(uuid, attribute, value)
        item = DarkEnergy::itemOrNull(uuid)
        return if item.nil?
        item[attribute] = value
        DarkEnergy::commit(item)
    end

    # DarkEnergy::read(uuid, attribute)
    def self.read(uuid, attribute)
        item = DarkEnergy::itemOrNull(uuid)
        return nil if item.nil?
        item[attribute]
    end

    # DarkEnergy::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        count = 0
        db = SQLite3::Database.new(PositiveSpace::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select count(*) as _c_ from energy where mikuType=?", [mikuType]) do |row|
            count = row["_c_"]
        end
        db.close
        count
    end
end

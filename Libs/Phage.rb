
# encoding: UTF-8

class Phage

    # phage.sqlite3
    # create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);

    # UTILS

    # Phage::variantsToUniqueVariants(variants)
    def self.variantsToUniqueVariants(variants)
        answer = []
        phage_uuids_recorded = {}
        variants.each{|variant|
            next if phage_uuids_recorded[variant["phage_uuid"]]
            answer << variant
            phage_uuids_recorded[variant["phage_uuid"]] = true
        }
        answer
    end

    # Phage::variantsToObjects(objects)
    def self.variantsToObjects(objects)
        higestOfTwo = lambda {|o1Opt, o2|
            if o1Opt.nil? then
                return o2
            end
            o1 = o1Opt
            if o1["phage_time"] < o2["phage_time"] then
                o2
            else
                o1
            end
        }
        projection = {}
        objects.each{|object|
            projection[object["uuid"]] = higestOfTwo.call(projection[object["uuid"]], object)
        }
        projection.values.select{|object| object["phage_alive"] }
    end

    # DATABASES

    # Phage::databasesPathsForReading()
    def self.databasesPathsForReading()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # Phage::databasePathForWriting()
    def self.databasePathForWriting()
        instanceId = Config::get("instanceId")
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage/phage-#{CommonUtils::today()}-#{instanceId}.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.execute("create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);")
            db.close
        end
        filepath
    end

    # Phage::datatrace()
    def self.datatrace()
        Phage::databasesPathsForReading()
            .sort
            .map{|filepath|
                {
                    "filepath" => filepath,
                    "filetime" => File.mtime(filepath).to_s
                }
            }
            .reduce(""){|trace, packet|
                Digest::SHA1.hexdigest("#{trace}:#{packet}")
            }
    end

    # SETTERS

    # Phage::commit(object)
    def self.commit(object)
        # TODO: this is temporary the time to migrate all objects
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_PhageItem(object, SecureRandom.hex, false)
        db = SQLite3::Database.new(Phage::databasePathForWriting())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _objects_ (_phage_uuid_, _uuid_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["phage_uuid"], object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
        nil
    end

    # VARIANTS

    # Phage::variantsEnumerator()
    def self.variantsEnumerator()
        Enumerator.new do |variants|
            Phage::databasesPathsForReading().each{|filepath|
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_", []) do |row|
                    variants << JSON.parse(row["_object_"])
                end
                db.close
            }
        end
    end

    # Phage::newIshVariantsOnChannelEnumerator(channelId)
    def self.newIshVariantsOnChannelEnumerator(channelId)

        getFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::getFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}")
        }

        setFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::setFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}", true)
        }

        Enumerator.new do |variants|
            Phage::databasesPathsForReading().each{|filepath|
                mtime = File.mtime(filepath)
                next if getFileIsDoneForChannel.call(channelId, filepath, mtime)

                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_", []) do |row|
                    variants << JSON.parse(row["_object_"])
                end
                db.close

                setFileIsDoneForChannel.call(channelId, filepath, mtime)
            }
        end
    end

end

class PhageAgentMikutypes

    # PhageAgentMikutypes::mikuTypeToVariants(mikuType)
    def self.mikuTypeToVariants(mikuType)

        variants = []

        phagedatatrace = Phage::datatrace()

        data = XCache::getOrNull("2114d32b-c865-4aea-a419-ef43378b9af3:#{phagedatatrace}:#{mikuType}")
        if data then
            return JSON.parse(data)
        end

        v1s = XCache::getOrNull("19ad36f6-24fb-4ab9-b4bc-1f3aa58cf1d6:#{mikuType}")
        if v1s then
            JSON.parse(v1s).each{|variant|
                variants << variant
            }
        end
        Phage::newIshVariantsOnChannelEnumerator("f7f5e1bb-8154-4f14-a2c4-bb591095c5d1:#{mikuType}")
            .each{|variant|
                next if variant["mikuType"] != mikuType
                variants << variant
            }
        variants = Phage::variantsToUniqueVariants(variants)
        XCache::set("19ad36f6-24fb-4ab9-b4bc-1f3aa58cf1d6:#{mikuType}", JSON.generate(variants))

        XCache::set("2114d32b-c865-4aea-a419-ef43378b9af3:#{phagedatatrace}:#{mikuType}", JSON.generate(variants))

        variants
    end
end

class PhageAgentObjects

    # ALL OBJECTS

    # PhageAgentObjects::objects()
    def self.objects()
        Phage::variantsToObjects(Phage::variantsEnumerator().to_a)
    end

    # SINGLE OBJECTS

    # PhageAgentObjects::getObjectVariants(uuid)
    def self.getObjectVariants(uuid)
        phagedatatrace = Phage::datatrace()
        variants = XCache::getOrNull("e5798be0-6986-4aff-8d43-da87641c443d:#{phagedatatrace}:#{uuid}")
        if variants then
            return JSON.parse(variants)
        end

        v1s = XCache::getOrNull("2fdd2ad1-930c-429b-b74e-560baf6d3d67:#{uuid}")
        if v1s then
            JSON.parse(v1s).each{|variant|
                variants << variant
            }
        end
        Phage::newIshVariantsOnChannelEnumerator("d927148d-44d1-4d9a-a573-af5bd68d56a9:#{uuid}")
            .each{|variant|
                next if variant["uuid"] != uuid
                variants << variant
            }
        variants = Phage::variantsToUniqueVariants(variants)
        XCache::set("2fdd2ad1-930c-429b-b74e-560baf6d3d67:#{uuid}", JSON.generate(variants))

        XCache::set("e5798be0-6986-4aff-8d43-da87641c443d:#{phagedatatrace}:#{uuid}", JSON.generate(variants))
        variants
    end

    # PhageAgentObjects::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = Phage::variantsToObjects(PhageAgentObjects::getObjectVariants(uuid))
        # The number of objects should be zero or one
        if objects.size > 1 then
            raise "(error: 1de85ac2-1788-448c-929f-e9d8e4d913df) unusual number of objects found for uuid: #{uuid}, found #{objects.size}"
        end
        objects.first
    end

    # PhageAgentObjects::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        item = PhageAgentObjects::getObjectOrNull(objectuuid)
        return if item.nil?
        item[attname] = attvalue
        Phage::commit(item)
    end

    # PhageAgentObjects::destroy(uuid)
    def self.destroy(uuid)
        # We extract the latest variant, if there is any, and flip it
        object = PhageAgentObjects::getObjectOrNull(uuid)
        return if object.nil?
        object["phage_alive"] = false
        Phage::commit(object)
    end

    # MIKUTYPES

    # PhageAgentObjects::mikuTypeToObjects(mikuType)
    def self.mikuTypeToObjects(mikuType)
        phagedatatrace = Phage::datatrace()
        objects = XCache::getOrNull("62c5c064-d8b8-4cf4-8d9e-f7f1826fe529:#{phagedatatrace}:#{mikuType}")
        if objects then
            return JSON.parse(objects)
        end
        objects = Phage::variantsToObjects(PhageAgentMikutypes::mikuTypeToVariants(mikuType))
        XCache::set("62c5c064-d8b8-4cf4-8d9e-f7f1826fe529:#{phagedatatrace}:#{mikuType}", JSON.generate(objects))
        objects
    end

    # PhageAgentObjects::mikuTypeObjectCount(mikuType) # Integer
    def self.mikuTypeObjectCount(mikuType)
        phagedatatrace = Phage::datatrace()
        count = XCache::getOrNull("50800c36-e636-4867-beeb-9aab5dac0fa8:#{phagedatatrace}:#{mikuType}")
        if count then
            return count.to_i
        end
        count = PhageAgentObjects::mikuTypeToObjects(mikuType).size
        XCache::set("50800c36-e636-4867-beeb-9aab5dac0fa8:#{phagedatatrace}:#{mikuType}", count)
        count
    end
end

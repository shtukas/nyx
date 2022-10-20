
# encoding: UTF-8

class PhageInternals

    # phage.sqlite3
    # create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);

    # UTILS

    # PhageInternals::variantsToUniqueVariants(variants)
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

    # PhageInternals::variantsToObjects(variants)
    def self.variantsToObjects(variants)
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
        variants.each{|variant|
            projection[variant["uuid"]] = higestOfTwo.call(projection[variant["uuid"]], variant)
        }
        projection.values.select{|object| object["phage_alive"] }
    end

    # DATABASES

    # PhageInternals::databasesPathsForReading()
    def self.databasesPathsForReading()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Phage")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # PhageInternals::databasePathForWriting()
    def self.databasePathForWriting()
        instanceId = Config::getOrFail("instanceId")
        filepath = "#{Config::pathToDataCenter()}/Phage/phage-#{CommonUtils::today()}-#{instanceId}.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.execute("create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);")
            db.close
        end
        filepath
    end

    # PhageInternals::datatrace()
    def self.datatrace()
        PhageInternals::databasesPathsForReading()
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

    # VARIANTS

    # PhageInternals::variantsSelectionAtDatabaseFile(databasefilepath, variantSelector, requestCacheKey)
    # variantSelector: lambda: Variant -> Boolean
    def self.variantsSelectionAtDatabaseFile(databasefilepath, variantSelector, requestCacheKey)

        requestCacheKey = "f9232983-34a6-4614-9eed-f7fa8f653562:#{databasefilepath}:#{File.mtime(databasefilepath).to_s}:#{requestCacheKey}"

        data = XCache::getOrNull(requestCacheKey)
        if data then
            return JSON.parse(data)
        end

        variants = []

        db = SQLite3::Database.new(databasefilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _objects_", []) do |row|
            variant = JSON.parse(row["_object_"])
            if variantSelector.call(variant) then
                variants << variant
            end
        end
        db.close

        XCache::set(requestCacheKey, JSON.generate(variants))

        variants
    end

    # PhageInternals::variantsSelectionAtPhage(variantSelector, requestCacheKey)
    def self.variantsSelectionAtPhage(variantSelector, requestCacheKey)

        phagedatatrace = PhageInternals::datatrace()

        data = XCache::getOrNull("2114d32b-c865-4aea-a419-ef43378b9af3:#{phagedatatrace}:#{requestCacheKey}")
        if data then
            return JSON.parse(data)
        end

        variants = PhageInternals::databasesPathsForReading()
                    .map{|databasefilepath|
                        PhageInternals::variantsSelectionAtDatabaseFile(databasefilepath, variantSelector, requestCacheKey)
                    }
                    .flatten
        variants = PhageInternals::variantsToUniqueVariants(variants)

        XCache::set("2114d32b-c865-4aea-a419-ef43378b9af3:#{phagedatatrace}:#{requestCacheKey}", JSON.generate(variants))

        variants
    end

    # PhageInternals::variantsEnumerator()
    def self.variantsEnumerator()
        Enumerator.new do |variants|
            PhageInternals::databasesPathsForReading().each{|filepath|
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

    # PhageInternals::newIshVariantsOnChannelEnumerator(channelId)
    def self.newIshVariantsOnChannelEnumerator(channelId)

        getFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::getFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}")
        }

        setFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::setFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}", true)
        }

        Enumerator.new do |variants|
            PhageInternals::databasesPathsForReading().each{|filepath|
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

    # PhageInternals::reCommitVariant(variant)
    def self.reCommitVariant(variant)
        FileSystemCheck::fsck_PhageItem(variant, SecureRandom.hex, false)
        PhageInternals::databasesPathsForReading().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from _objects_ where _phage_uuid_=?", [variant["phage_uuid"]]
            db.close
        }
        db = SQLite3::Database.new(PhageInternals::databasePathForWriting())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _objects_ (_phage_uuid_, _uuid_, _mikuType_, _object_) values (?, ?, ?, ?)", [variant["phage_uuid"], variant["uuid"], variant["mikuType"], JSON.generate(variant)]
        db.close
        nil
    end

    # PhageInternals::deleteVariant(variant)
    def self.deleteVariant(variant)
        FileSystemCheck::fsck_PhageItem(variant, SecureRandom.hex, false)
        PhageInternals::databasesPathsForReading().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "delete from _objects_ where _phage_uuid_=?", [variant["phage_uuid"]]
            db.close
        }
        nil
    end

    # PhageInternals::vacuum()
    def self.vacuum()
        PhageInternals::databasesPathsForReading().each{|filepath|
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute "vacuum", []
            db.close
        }
        nil
    end

end

class PhagePublic

    # SETTERS

    # PhagePublic::commit(object)
    def self.commit(object)
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f

        #puts "PhagePublic::commit(#{JSON.pretty_generate(object)})"
        FileSystemCheck::fsck_PhageItem(object, SecureRandom.hex, false)

        db = SQLite3::Database.new(PhageInternals::databasePathForWriting())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _objects_ (_phage_uuid_, _uuid_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["phage_uuid"], object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close

        nil
    end

    # PhagePublic::destroy(uuid)
    def self.destroy(uuid)
        # We extract the latest variant, if there is any, and flip it
        object = PhagePublic::getObjectOrNull(uuid)
        return if object.nil?
        object["phage_alive"] = false
        PhagePublic::commit(object)
    end

    # GETTERS

    # PhagePublic::mikuTypeToVariants(mikuType)
    def self.mikuTypeToVariants(mikuType)
        PhageInternals::variantsSelectionAtPhage(lambda {|variant|
            variant["mikuType"] == mikuType
        }, "19ad36f6-24fb-4ab9-b4bc-1f3aa58cf1d6:#{mikuType}")
    end

    # PhagePublic::getObjectVariants(uuid)
    def self.getObjectVariants(uuid)
        PhageInternals::variantsSelectionAtPhage(lambda {|variant|
            variant["uuid"] == uuid
        }, "d6bb2092-d355-447f-94ca-0cb43f7014d1:#{uuid}")
    end

    # PhagePublic::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = PhageInternals::variantsToObjects(PhagePublic::getObjectVariants(uuid))
        # The number of objects should be zero or one
        if objects.size > 1 then
            raise "(error: 1de85ac2-1788-448c-929f-e9d8e4d913df) unusual number of objects found for uuid: #{uuid}, found #{objects.size}"
        end
        objects.first
    end

    # PhagePublic::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        item = PhagePublic::getObjectOrNull(objectuuid)
        return if item.nil?
        item[attname] = attvalue
        PhagePublic::commit(item)
    end

    # PhagePublic::mikuTypeToObjects(mikuType)
    def self.mikuTypeToObjects(mikuType)
        PhageInternals::variantsToObjects(PhagePublic::mikuTypeToVariants(mikuType))
    end

    # PhagePublic::mikuTypeObjectCount(mikuType) # Integer
    def self.mikuTypeObjectCount(mikuType)
        PhageInternals::variantsToObjects(PhagePublic::mikuTypeToVariants(mikuType)).count
    end
end

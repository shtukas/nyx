
# encoding: UTF-8

class Nx51s

    # ----------------------------------------------------------------------
    # IO

    # Nx51s::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("Nx51")
    end

    # Nx51s::getOrNull(uuid): null or Nx51
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # Nx51s::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Nx51s::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "Nx51",
          "description" => description,
          "unixtime"    => unixtime
        }
        Librarian6Objects::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Nx51s::toString(item)
    def self.toString(item)
        "(carrier) #{item["description"]}"
    end

    # Nx51s::contents(owneruuid)
    def self.contents(owneruuid)
        Librarian6Objects::getObjectsByMikuType("Nx60")
            .select{|claim| claim["owneruuid"] == owneruuid }
            .map{|claim| claim["targetuuid"] }
            .map{|uuid| Librarian6Objects::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # ----------------------------------------------------------------------
    # Operations

    # Nx51s::landing(item)
    def self.landing(item)
        loop {
            item = Nx51s::getOrNull(item["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if item.nil?
            system("clear")

            uuid = item["uuid"]

            store = ItemStore.new()

            puts Nx51s::toString(item).green
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            Links::parents(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [parent] #{LxFunction::function("toString", entity)}" 
                }

            Links::related(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [related] #{LxFunction::function("toString", entity)}" 
                }

            Links::children(item["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] [child] #{LxFunction::function("toString", entity)}" 
                }

            Nx51s::contents(uuid)
                .each{|entity| 
                    indx = store.register(entity, false)
                    puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}" 
                }

            puts "access | upload (primitive files) | description | attachment | link | unlink | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
            end

            if Interpreting::match("access", command) then
                exportFolderpath = "/Users/pascal/Desktop/#{item["description"]} (#{item["uuid"][-8, 8]})"
                FileUtils.mkdir(exportFolderpath)
                Nx51s::contents(uuid)
                    .each{|nx45| Nx45s::exportItemAtLocation(nx45, exportFolderpath)}
            end

            if Interpreting::match("upload", command) then
                uploadFolderpath = LucilleCore::askQuestionAnswerAsString("upload folder: ")
                LucilleCore::locationsAtFolder(uploadFolderpath).each{|location|
                    if !File.file?(location) then
                        raise "(error: 0c333466-8402-4a2a-a446-2297d3ae0ef3) #{location}"
                    end
                    filepath = location
                    nx45 = Nx45s::createNewOrNull(filepath)
                    puts "Primitive file:"
                    puts JSON.pretty_generate(nx45)
                    puts "Link: (owner: #{uuid}, file: #{nx45["uuid"]})"
                    Nx60s::issueClaim(uuid, nx45["uuid"])
                }
                puts "Upload completed"
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("description", command) then
                description = Utils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian6Objects::commit(item)
                next
            end

            if Interpreting::match("attachment", command) then
                TxAttachments::interactivelyCreateNewOrNullForOwner(item["uuid"])
                next
            end

            if Interpreting::match("link", command) then
                NyxNetwork::connectToOtherArchitectured(item)
            end

            if Interpreting::match("unlink", command) then
                NyxNetwork::disconnectFromLinkedInteractively(item)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy entry ? : ") then
                    Nx51s::destroy(item["uuid"])
                    break
                end
            end
        }
    end

    # ------------------------------------------------
    # Nx20s

    # Nx51s::nx20s()
    def self.nx20s()
        Nx51s::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{Nx51s::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end

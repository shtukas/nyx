# encoding: UTF-8

class Today

    # Today::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:998deeb2-7746-4578-b5ff-844f83fac6bd"
    end

    # Today::issueNewFromDescription(description)
    def self.issueNewFromDescription(description)
        CoreData2::issueDescriptionOnlyAtom(SecureRandom.uuid, description, [Today::coreData2SetUUID()])
    end

    # Today::issueNewFromDescriptionAndLocation(description, location)
    def self.issueNewFromDescriptionAndLocation(description, location)
        CoreData2::issueAionPointAtomUsingLocation(uuid, description, location, [Today::coreData2SetUUID()])
    end

    # Today::items()
    def self.items()
        CoreData2::getSet(Today::coreData2SetUUID())
    end

    # Today::itemToString(atom)
    def self.itemToString(atom)
        "[today] #{atom["description"]} (#{atom["type"]})"
    end

    # Today::ns16s()
    def self.ns16s()
        Today::items().map{|atom|
            Domain::interactivelySelectOrGetCachedDomain(Today::itemToString(atom)) # Domain identification
            {
                "uuid"     => atom["uuid"],
                "unixtime" => atom["unixtime"],
                "announce" => Today::itemToString(atom).gsub("[today]", "[tday]"),
                "commands" => ["..", "done"],
                "interpreter" => lambda{|command|
                    if command == "done" then
                        CoreData2::destroyAtom(atom["uuid"])
                    end
                },
                "run"      => lambda {
                    t1 = Time.new.to_i
                    puts Today::itemToString(atom).green
                    CoreData2::accessWithOptionToEdit(atom)
                    if LucilleCore::askQuestionAnswerAsBoolean("> destroy ? ") then
                        CoreData2::destroyAtom(atom["uuid"])
                    end
                    t2 = Time.new.to_i
                    puts "> Select domain for accounting"
                    domain = Domain::interactivelySelectOrGetCachedDomain(Today::itemToString(atom))
                    bankAccount = Domain::getDomainBankAccount(domain)
                    Bank::put(bankAccount, t2-t1)
                }
            }
        }
    end

    # Today::nx19s()
    def self.nx19s()
        []
    end
end

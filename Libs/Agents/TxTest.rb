
class TxTest

    # TxTest::mikus()
    def self.mikus()
        Librarian2::classifierToMikus("TxTest")
    end

    # TxTest::ns16s()
    def self.ns16s()
        TxTest::mikus().map{|miku|
            {
                "uuid"        => miku["uuid"],
                "NS198"       => "NS16:TxTest",
                "announce"    => miku["description"],
                "commands"    => nil
            }
        }
    end
end

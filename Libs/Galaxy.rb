
# encoding: UTF-8

class Galaxy

    # Galaxy::locationEnumerator(roots)
    def self.locationEnumerator(roots)
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exist?(root) then
                    begin
                        Find.find(root) do |path|
                            next if File.basename(path)[0, 1] == "."
                            next if path.include?("target")
                            next if path.include?("project")
                            next if path.include?("node_modules")
                            next if path.include?("static")
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end
end

require 'fileutils'

module FireWatir

    class Profile

        def self.create(name=@name)
            raise "Won't create profile named default" if name == 'default'
            return true if path(name)

            manager(:add, name)

        end

        def self.delete(name=@name)
            raise "Won't delete profile named default" if name == 'default'
            return true unless path(name)

            manager(:delete, name)
        end


        # Returns the names of the profiles that currently exists on the system
        # Does not include a random salt.
        def self.list
            profiles = Dir.glob(folder_path+"/*").map do |profile|
                profile.gsub(/.*\/.*[\.|\/]/, '')
            end

            profiles.reject!{|s| s=="ini"} #The profiles.ini file is not a profile
            profiles
        end

        private

        def self.manager(action, name)
            raise "Invalid action" unless [:delete, :add].include? action

            File.open(ini_path, 'r+') do |f|                 
                ini_text = f.read
                profile_array = ini_reader(ini_text)

                if action == :delete
                    file_path = path(name)
                    FileUtils.rm_rf(file_path)
                    raise(IOError, "Could not delete profile.") if path(name)

                    profile_array.reject!{|profile| profile['Name'] == name}
                elsif action == :add
                    dir = FileUtils.mkdir(folder_path+"/#{name}").first
                    Watir::Waiter.wait_until{File.exist? dir}
                    FileUtils.touch(dir +'/prefs.js') # This file must exists for firefox to think there is a profile here

                    profile_array << {'Name' => name, 'IsRelative' => '1', 'Path' => name }
                    @profile_created = true
                end           

                new_ini_text = ini_writer(profile_array)

                f.pos = 0            # back to start
                f.print new_ini_text # write out modified text
                f.truncate(f.pos)    # truncate to new length
            end
            true
        end
        
        def self.path(name)
            Dir.glob(folder_path+"/*#{name}").first
        end

        def self.ini_reader(ini_text)
            ini_array = ini_text.split(/\[Profile.*\]/)
            ini_array.shift # Get rid of the [General] entry

            ini_array.map do |profile|
                hash = {}

                profile_array = profile.split(/\n/)
                profile_array.reject!(&:empty?)

                profile_array.each do |entry|
                    key, value = entry.split('=')
                    hash[key] = value
                end
                hash
            end
        end

        def self.ini_writer(ini_array)

            profile_string = "[General]\nStartWithLastProfile=1\n\n"

            ini_array.each_with_index do |hash, i|
                entries = hash.to_a.map{|entry| entry.join('=')}.join("\n")
                entries_string = "[Profile#{i}]\n#{entries}\n\n"
                profile_string << entries_string
            end

            profile_string
        end

        def self.ini_path
            path = case current_os()
            when :windows
                File.expand_path('~\\Mozilla\\Firefox\\Profiles\\')
            when :macosx
                File.expand_path(folder_path+'/../profiles.ini')
            when :linux
                File.expand_path(folder_path+'/profiles.ini')
            end     
            raise "unable to locate profiles.ini" if path.nil? || path.empty?
            path
        end

        def self.folder_path
            path = case current_os()
            when :windows
                File.expand_path('~\\Mozilla\\Firefox\\Profiles\\')
            when :macosx
                File.expand_path('~/Library/Application Support/Firefox/Profiles/')
            when :linux
                File.expand_path('~/.mozilla/firefox/')
            end     
            raise "unable to locate profiles folder" if path.nil? || path.empty?
            path
        end

        def self.current_os
            return @current_os if defined?(@current_os)

            platform = RUBY_PLATFORM =~ /java/ ? java.lang.System.getProperty("os.name") : RUBY_PLATFORM

            @current_os = case platform
            when /mswin|windows/i
                :windows
            when /darwin|mac os/i
                :macosx
            when /linux/i
                :linux
            end
        end
    
    
    end
end

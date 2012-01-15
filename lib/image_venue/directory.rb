module ImageVenue
  class Directory
    class << self
      attr_accessor :debug

      def debug?
        (ImageVenue.debug? or self.debug) ? true : false
      end

      def puts_debug(*args)
        if self.debug?
          puts(*args)
          return true
        else
          return false
        end
      end

      def list_uri
        @list_uri ||= URI.parse(ImageVenue.base_url + '/view_dir.php')
      end

      def select_uri
        @select_uri ||= URI.parse(ImageVenue.base_url + '/process_change_dir.php')
      end

      def select_directory_key
        @select_directory_key ||= 'dir'
      end

      def create_uri
        @create_uri ||= URI.parse(ImageVenue.base_url + '/create_dir.php')
      end

      def create_directory_key
        @create_directory_key ||= 'new_dir'
      end

      def delete_uri
        @delete_uri ||= URI.parse(ImageVenue.base_url + '/process_del_dir.php')
      end

      def delete_directory_key
        @delete_directory_key ||= 'delete_dir[]'
      end

      def create_params(directory_name)
        {
          self.create_directory_key => directory_name
        }
      end

      def delete_params(directory_name)
        {
          self.delete_directory_key => directory_name
        }
      end

      def select_params(directory_name)
        {
          self.select_directory_key => directory_name
        }
      end

      def list(connection=nil)
        self.puts_debug "Trying to fetch directories ..."
        request = Net::HTTP::Get.new(self.list_uri.path)
        request.header['cookie'] = [connection.cookie_as_string]
        response = Net::HTTP.start(self.list_uri.host, self.list_uri.port) do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPSuccess)
          directories = []
          hpricot = Hpricot(response.body)
          form = hpricot.search('form:first').first || Hpricot::Elem.new('')
          form.search('input[@type="radio"]').each do |input|
            directories << self.new(connection, input['value'], false)
          end
          self.puts_debug "Directories successfully fetched!"
          return directories
        else
          self.puts_debug "Directories fetch failed!"
          return false
        end
      end
    end

    attr_accessor :connection
    attr_accessor :debug
    attr_accessor :name

    def initialize(connection, name, is_new=true)
      self.connection = connection
      self.name = name
      @is_new = is_new
      return nil
    end

    def debug?
      (self.class.debug? or self.debug) ? true : false
    end

    def puts_debug(*args)
      if self.debug?
        puts(*args)
        return true
      else
        return false
      end
    end

    def is_new?
      @is_new
    end

    def save(force=false, reload=false)
      if force or self.connection.directories(reload).find {|dir| dir.name == self.name }.nil?
        self.puts_debug "Trying to create directory: '#{self.name}'"
        request = Net::HTTP::Post.new(self.class.create_uri.path)
        request.form_data = self.class.create_params(self.name)
        request.header['cookie'] = [self.connection.cookie_as_string]
        response = Net::HTTP.start(self.class.create_uri.host, self.class.create_uri.port) do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPSuccess) and not (response.header['Set-Cookie'].nil? or response.header['Set-Cookie'].empty?)
          self.connection.selected_directory = self.name
          self.puts_debug "Directory successfully created and selected!"
          @is_new = false
          return true
        else
          self.puts_debug "Directory create failed!"
          return false
        end
      else
        self.puts_debug "Directory already exists: '#{self.name}'"
        return nil
      end
    end

    def destroy(force=false, reload=false)
      if force or not self.connection.directories(reload).find {|dir| dir.name == self.name }.nil?
        self.puts_debug "Trying to delete directory: '#{self.name}'"
        request = Net::HTTP::Post.new(self.class.delete_uri.path)
        request.form_data = self.class.delete_params(self.name)
        request.header['cookie'] = [self.connection.cookie_as_string]
        response = Net::HTTP.start(self.class.delete_uri.host, self.class.delete_uri.port) do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPSuccess)
          if self.connection.selected_directory == self.name
            self.connection.selected_directory = nil
          end
          self.puts_debug "Directory successfully deleted!"
          @is_new = true
          return true
        else
          self.puts_debug "Directory delete failed!"
          return false
        end
      else
        self.puts_debug "Directory does not exist: '#{self.name}'"
        return nil
      end
    end

    def select(reselect=false)
      if self.connection.selected_directory != self.name or reselect
        self.puts_debug "Trying to select directory: '#{self.name}'"
        request = Net::HTTP::Post.new(self.class.select_uri.path)
        request.form_data = self.class.select_params(self.name)
        request.header['cookie'] = [self.connection.cookie_as_string]
        response = Net::HTTP.start(self.class.select_uri.host, self.class.select_uri.port) do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPFound) and not (response.header['Set-Cookie'].nil? or response.header['Set-Cookie'].empty?)
          self.connection.selected_directory = self.name
          self.puts_debug "Directory successfully selected!"
          return true
        else
          self.puts_debug "Directory select failed!"
          return false
        end
      else
        self.puts_debug "Directory already selected."
        return nil
      end
    end

    def files(reload=false)
      if reload or @files.nil?
        @files = ImageVenue::File.list(self)
      else
        self.puts_debug "Files from cache for directory: '#{self.name}'"
      end
      return @files
    end

    def clear_cache
      @files = nil
      self.puts_debug "Directory's cache cleared."
    end
  end
end

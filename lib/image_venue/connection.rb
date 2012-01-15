module ImageVenue
  class Connection
    class << self
      def login_uri
        @login_uri ||= URI.parse(ImageVenue.base_url + '/process_logon.php')
      end

      def login_username_key
        @login_username_key ||= 'user'
      end

      def login_password_key
        @login_password_key ||= 'password'
      end

      def login_action_key
        @login_action_key ||= 'action'
      end

      def logout_uri
        @logout_uri ||= URI.parse(ImageVenue.base_url + '/logout.php')
      end

      def cookie_user_key
        @cookie_user_key ||= 'user'
      end

      def cookie_root_key
        @cookie_root_key ||= 'root'
      end

      def cookie_timestamp_key
        @cookie_timestamp_key ||= 'tsctr'
      end

      def cookie_directory_key
        @cookie_directory_key ||= 'cur_upload_dir'
      end

      def cookie_view_directory
        @cookie_view_directory ||= 'view_dir'
      end

      def login_params(connection)
        {
          self.login_action_key => connection.action,
          self.login_username_key => connection.username,
          self.login_password_key => connection.password
        }
      end
    end

    attr_accessor :action
    attr_accessor :cookie
    attr_accessor :debug
    attr_accessor :password
    attr_accessor :username

    def initialize(username, password, cookie=nil)
      self.action = '1'
      self.username = username
      self.password = password
      self.cookie = cookie
      return nil
    end

    def debug?
      (ImageVenue.debug or self.debug)
    end

    def puts_debug(*args)
      if self.debug?
        puts(*args)
        return true
      else
        return false
      end
    end

    def login
      self.puts_debug "Trying to login ..."
      response = Net::HTTP.post_form(self.class.login_uri, self.class.login_params(self))
      unless response.header['Set-Cookie'].nil? or response.header['Set-Cookie'].empty?
        self.cookie = {}
        self.cookie[self.class.cookie_user_key] = $1 if response.header['Set-Cookie'] =~ /#{Regexp.escape(self.class.cookie_user_key)}=(.+?)[,;]/
        self.cookie[self.class.cookie_root_key] = $1 if response.header['Set-Cookie'] =~ /#{Regexp.escape(self.class.cookie_root_key)}=(\d+)/
        response_timestamp = Net::HTTP.get_response(ImageVenue.base_uri)
        unless response_timestamp.header['Set-Cookie'].nil? or response_timestamp.header['Set-Cookie'].empty?
          self.cookie[self.class.cookie_timestamp_key] = $1 if response_timestamp.header['Set-Cookie'] =~ /#{Regexp.escape(self.class.cookie_timestamp_key)}=(.+?)[,;]/
          self.puts_debug "Login successfull!"
          return true
        else
          self.puts_debug "Login failed!"
          return false
        end
      else
        self.cookie = nil
        return false
      end
    end

    def logged_in?
      unless self.cookie.nil?
        return true
      else
        return false
      end
    end

    def logout
      self.puts_debug "Trying to logout ..."
      response = Net::HTTP.get_response(self.class.logout_uri)
      if response.is_a?(Net::HTTPSuccess) or response.is_a?(Net::HTTPFound)
        self.cookie = nil
        self.puts_debug "Logout successfull! Resetting cookie."
        return true
      else
        self.cookie = nil
        self.puts_debug "Logout failed! But resetting cookie anyway."
        return false
      end
    end

    def selected_directory
      if self.cookie.is_a?(Hash)
        return self.cookie[self.class.cookie_directory_key]
      else
        return nil
      end
    end

    def selected_directory=(directory)
      if self.cookie.is_a?(Hash)
        if directory.nil?
          return self.cookie.delete(self.class.cookie_directory_key)
        else
          return self.cookie[self.class.cookie_directory_key] = directory
        end
      else
        return nil
      end
    end

    def view_directory
      if self.cookie.is_a?(Hash)
        return self.cookie[self.class.cookie_view_directory]
      else
        return nil
      end
    end

    def view_directory(directory)
      if self.cookie.is_a?(Hash)
        if directory.nil?
          return self.cookie.delete(self.class.cookie_view_directory)
        else
          return self.cookie[self.class.cookie_view_directory] = directory
        end
      else
        return nil
      end
    end

    def cookie_as_string
      unless self.cookie.nil?
        cookie_str = self.cookie.map {|key, value| [key, value].join('=')}.join('; ')
        return cookie_str
      else
        return nil
      end
    end

    def directories(reload=false)
      if reload or @directories.nil?
        @directories = ImageVenue::Directory.list(self)
      else
        self.puts_debug "Directories from cache!"
      end
      return @directories
    end

    def clear_cache
      @directories = nil
      self.puts_debug "Connection's cache cleared."
    end
  end
end

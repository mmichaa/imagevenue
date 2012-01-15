module ImageVenue
  class File
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

      def parse_forum_codes(directory, response_body)
        files = []
        self.puts_debug "Parsing Forum-Codes ..."
        hpricot = Hpricot(response_body)
        urls = hpricot.search('p:last').last.inner_text.scan(/\[URL=(.+?)\]/i).flatten
        urls.each do |url|
          self.puts_debug "Found URL: `#{url}`"
          files << self.new(directory, nil, nil, url, false)
        end
        return files
      end

      def list_uri
        @list_uri ||= URI.parse(ImageVenue.base_url + '/process_get_dir_codes.php')
      end

      def list_format_key
        @list_format_key ||= 'poster'
      end

      def list_format_forum
        @list_format_forum ||= 'forum'
      end

      def list_format_website
        @list_format_website ||= 'webpage'
      end

      def list_directory_key
        @list_directory_key ||= 'dir'
      end

      def upload_uri
        @upload_uri ||= URI.parse(ImageVenue.base_url + '/upload.php')
      end

      def upload_action_key
        @upload_action_key ||= 'action'
      end

      def upload_user_key
        @upload_user_key ||= 'user_id'
      end

      def upload_file_key
        @upload_file_key ||= 'userfile[]'
      end

      def upload_directory_key
        @upload_directory_key ||= 'upload_dir'
      end

      def upload_content_key
        @upload_content_key ||= 'imgcontent'
      end

      def upload_content_safe
        @upload_content_safe ||= 'safe'
      end
      alias :upload_content_family :upload_content_safe

      def upload_content_notsafe
        @upload_content_notsafe ||= 'notsafe'
      end
      alias :upload_content_adult :upload_content_notsafe

      def upload_interlink_key
        @upload_interlink_key ||= 'interlinkimage'
      end

      def upload_interlink_yes
        @upload__interlink_yes ||= 'interlinkyes'
      end

      def upload_interlink_no
        @upload__interlink_no ||= 'interlinkno'
      end

      def upload_resize_key
        @upload_resize_key ||= 'img_resize'
      end

      def upload_maximum_files
        @upload_maximum_files ||= 10
      end

      def upload_maximum_size
        @upload_maximum_size ||= 3 * 1024 * 1024 # 3 MByte
      end

      def upload_image_types
        @upload_image_types ||= ['jpeg', 'jpg']
      end

      def delete_uri
        @delete_uri ||= URI.parse(ImageVenue.base_url + '/manage_files.php')
      end

      def delete_file_key
        @delete_file_key ||= 'delete_files[]'
      end

      def delete_submit_key
        @delete_submit_key ||= 'submit'
      end

      def delete_submit_value
        @delete_submit_value ||= 'Delete'
      end

      def upload_file_params(file)
        {
          self.upload_file_key => file
        }
      end

      def upload_form_params(directory, content_safe=false, interlink=false, resize=nil)
        return {
          self.upload_action_key => '1',
          self.upload_directory_key => directory.name,
          self.upload_user_key => directory.connection.cookie[directory.connection.class.cookie_user_key],
          self.upload_content_key => (content_safe) ? self.upload_content_safe : self.upload_content_notsafe,
          self.upload_interlink_key => (interlink) ? self.upload_interlink_yes : self.upload_interlink_no,
          self.upload_resize_key => resize || ''
        }
      end

      def delete_params(file_name)
        {
          self.delete_submit_key => self.delete_submit_value,
          self.delete_file_key => file_name
        }
      end

      def list(directory)
        self.puts_debug "Trying to fetch files from directory: '#{directory.name}' ..."
        request = Net::HTTP::Post.new(self.list_uri.path)
        request.form_data = self.find_params(directory.name)
        request.header['cookie'] = [directory.connection.cookie_as_string]
        response = Net::HTTP.start(self.list_uri.host, self.list_uri.port) do |http|
          http.request(request)
        end
        if response.is_a?(Net::HTTPSuccess)
          files = self.parse_forum_codes(directory, response.body)
          self.puts_debug "Files successfully fetched!"
          return files
        else
          self.puts_debug "Files fetch failed!"
          return false
        end
      end

      def find_params(directory_name)
        {
          self.list_format_key => self.list_format_forum,
          self.list_directory_key => directory_name
        }
      end
    end

    attr_accessor :content_type
    attr_accessor :debug
    attr_accessor :directory
    attr_accessor :io
    attr_accessor :name
    attr_accessor :url

    def initialize(directory, name=nil, io=nil, url=nil, is_new=true)
      self.content_type = 'image/jpeg'
      self.directory = directory
      self.name = name
      self.io = io
      self.url = url
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

    def save(reselect=false, content_safe=false, interlink=false, resize=nil)
      self.directory.select(reselect)
      self.puts_debug "Trying to upload file `#{self.name}` to directory `#{self.directory.name}` ..."
      request = Net::HTTP::Post.new(self.class.upload_uri.path)
      request.set_multipart_data(self.class.upload_file_params(self), self.class.upload_form_params(self.directory, content_safe, interlink, resize))
      request.header['cookie'] = [self.directory.connection.cookie_as_string]
      response = Net::HTTP.start(self.class.upload_uri.host, self.class.upload_uri.port) do |http|
        http.request(request)
      end
      if response.is_a?(Net::HTTPSuccess)
        self.url = Hpricot(response.body).search('textarea').first.inner_text.strip
        self.puts_debug "File successfully uploaded!"
        @is_new = false
        return true
      else
        self.puts_debug "File upload failed!"
        return false
      end
    end

    def destroy()
      self.puts_debug "Trying to delete file `#{self.name}` from directory `#{self.directory.name}` ..."
      request = Net::HTTP::Post.new(self.class.delete_uri.path)
      request.form_data = self.class.delete_params(self.name)
      self.directory.connection.view_directory = self.directory.name
      request.header['cookie'] = [self.directory.connection.cookie_as_string]
      response = Net::HTTP.start(self.class.delete_uri.host, self.class.delete_uri.port) do |http|
        http.request(request)
      end
      self.directory.connection.view_directory = nil
      if response.is_a?(Net::HTTPSuccess)
        self.puts_debug "File `#{self.name}` successfully deleted!"
        @is_new = true
        return true
      else
        self.puts_debug "File `#{self.name}` delete failed!"
        return false
      end
    end

    def name
      @name ||= $1 if self.url =~ /image=(.+)$/
      @name
    end

    def base_name
      @base_name ||= Kernel::File.basename(self.name)
    end

    def real_name
      @real_name ||= $1+$2 if self.name =~ /^\d+_(.*)_\d+_\d+\w{2}(\.\w{2,3})$/
    end

    def large_io(reload=false)
      if @large_io.nil? or reload
        self.puts_debug "Trying to fetch large image data from `#{self.url}` ..."
        self.large_url(false)
        @large_io = open(@large_url)
        self.puts_debug "Image data successfully fetched!"
      else
        @large_io.rewind
        self.puts_debug "Image data from cache!"
      end
      return @large_io
    end

    def large_url(reload=false)
      if reload or @large_url.nil?
        self.puts_debug "Trying to fetch large image URL from `#{self.url}` ..."
        html = open(self.url)
        img = Hpricot(html).search('img[@id="thepic"]:first').first
        uri = URI.parse(self.url)
        uri.path = '/' + img.attributes.find {|key, value| key =~ /^src$/i}.last
        @large_url = uri.to_s
        self.puts_debug "Large image URL successfully fetched!"
      else
        self.puts_debug "Large image URL from cache!"
      end
      return @large_url
    end

    def thumbnail_io
      if @thumbnail_io.nil?
        self.puts_debug "Trying to fetch thumbnail data ..."
        @thumbnail_io = open(self.thumbnail_url)
        self.puts_debug "Thumbnail data successfully fetched!"
      else
        self.puts_debug "Thumbnail data from cache!"
      end
      return @thumbnail_io
    end

    def thumbnail_url
      if @thumbnail_url.nil? and self.url =~ /_(\d+)lo/
        @thumbnail_url = self.url.gsub('img.php?image=', "loc#{$1}/th_")
      end
      return @thumbnail_url
    end

    def thumbnail_for_board_upper
      @thumbnail_for_board_upper ||= "[URL=#{self.url}][IMG]#{self.thumbnail_url}[/IMG][/URL]"
    end

    def thumbnail_for_board_lower
      @thumbnail_for_board_lower ||= "[url=#{self.url}][img]#{self.thumbnail_url}[/img][/url]"
    end

    def thumbnail_for_website
      @thumbnail_for_website ||= "<a href=\"#{self.url}\" target=_blank><img src=\"#{self.thumbnail_url}\" border=\"0\"></a>"
    end

    def clear_cache
      @large_io = nil
      @large_url = nil
      @thumbnail_io = nil
      @thumbnail_url = nil
      @thumbnail_for_board_upper = nil
      @thumbnail_for_board_lower = nil
      @thumbnail_for_website = nil
      self.puts_debug "File's cache cleared."
    end
  end
end

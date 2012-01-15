# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.author = 'Michael Nowak'
  spec.email = 'thexsystem@gmail.com'
  spec.name = 'imagevenue'
  spec.version = '0.0.3'
  spec.description = <<-EOF
  Accessing your ImageVenue account via a Ruby-Library. With support for listing, creating, deleting directories and listing, uploading and deleting files. Generates BB-Code or HTML-Code four you, too.
  EOF
  spec.summary = 'Accessing your ImageVenue account via a Ruby-Library'
  spec.homepage = 'http://github.com/THExSYSTEM/imagevenue'
  spec.has_rdoc = false
  spec.executables = Dir['bin/*'].map {|bin| File.basename(bin) }
  spec.default_executable = 'image_venue'
  spec.add_dependency 'hpricot', '>= 0.6'
  spec.files = Dir['lib/**/*.rb']
  spec.require_path = 'lib'
end

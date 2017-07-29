lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'version'

@__release_mode = ENV['rel_mode']
@__release_mode = 'minor' if @__release_mode == nil
@__gem_version = read_version

Gem::Specification.new do |spec|
  spec.platform       = Gem::Platform::RUBY
  spec.name           = "cutedriver-sut-qt-plugin"
  spec.version        = @__gem_version
  spec.author         = "TDriver team & cuTeDriver team"
  spec.email          = "antti.korventausta@nomovok.com"
  spec.homepage       = "https://github.com/nomovok-opensource/cutedriver-sut_qt"
  spec.summary        = "cuTeDriver Interface SUT Qt plugin"
  spec.license        = "LGPL-2.1"
  spec.require_path   = "lib/testability-driver-plugins/"
  spec.files          = Dir[ 'env.rb', 'lib/**/*', 'xml/**/*' ]
  spec.has_rdoc       = false

  spec.extensions << 'installer/extconf.rb'
end

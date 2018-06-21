# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Sebastian Röbke"]
  gem.email         = ["sebastian.roebke@xing.com"]
  gem.description   = %q{Allow Paperclip attachments to be stored on FTP servers}
  gem.summary       = %q{Allow Paperclip attachments to be stored on FTP servers}
  gem.homepage      = "https://github.com/xing/paperclip-storage-ftp"
  gem.license       = "MIT"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "paperclip-storage-ftp"
  gem.require_paths = ["lib"]
  gem.version       = "1.2.8"

  gem.add_dependency("paperclip", ">= 4.0.0")

  gem.add_development_dependency("rspec")
  gem.add_development_dependency("rake")
  gem.add_development_dependency("daemon_controller", ">= 1.1.0")
  gem.add_development_dependency("activerecord")
  gem.add_development_dependency("sqlite3")
  gem.add_development_dependency("coveralls")
end

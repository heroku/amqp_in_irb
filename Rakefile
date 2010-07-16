
$gemspec_file = nil
$gemspec = nil

task :gemspec_file do
  $gemspec_file = Dir['*.gemspec'].first unless $gemspec_file
end

task :gemspec do
  load $gemspec_file
  $gemspec = spec
end
task :gemspec => :gemspec_file

desc 'Create a gem for this project.'
task :gem do
  system "gem build #{$gemspec_file}"
end
task :gem => :gemspec_file

desc 'Install the gem for this project.'
task :install => :gem do
  system "gem install #{$gemspec.name}-#{$gemspec.version}.gem"
end
task :install => [ :gem, :gemspec ]

desc 'Remove the gem installed by this project.'
task :uninstall do
  system "gem uninstall #{$gemspec.name} --version #{$gemspec.version}"
end
task :uninstall => :gemspec

desc 'Delete gems and docs.'
task :clean do
  system 'rm -f *.gem'
  system 'rm -rf doc'
end


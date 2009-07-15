desc "Run the specs for wesabot"
task :spec do
  exec "spec #{ENV['SPEC_ARGS']} #{Dir.glob('spec/**/*_spec.rb').join(' ')}"
end

task :cruise => :spec

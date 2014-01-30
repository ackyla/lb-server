begin
  require 'rspec/core/rake_task'

  spec_tasks = Dir['spec/*/'].map { |d| File.basename(d) }

  spec_tasks.each do |folder|
    RSpec::Core::RakeTask.new("spec:#{folder}") do |t|
      t.pattern = "./spec/#{folder}/**/*_spec.rb"
      t.rspec_opts = %w(-fs --color)
    end

    Dir["spec/#{folder}/**/*_spec.rb"].map {|d| File.basename(d) }.each do |file|
      task_name = file.gsub(/(_controller_spec.rb|_spec.rb)$/, '')
      RSpec::Core::RakeTask.new("spec:#{folder}:#{task_name}") do |t|
        t.pattern = "./spec/#{folder}/**/#{file}"
        t.rspec_opts = %w(-fs --color)
      end
    end
  end

  desc "Run complete application spec suite"
  task 'spec' => spec_tasks.map { |f| "spec:#{f}" }
rescue LoadError
  puts "RSpec is not part of this bundle, skip specs."
end

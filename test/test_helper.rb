$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
paths_to_rails_root = [ '../../../../', '../../../kongregate/trunk' ]
found = paths_to_rails_root.find do |p|
  environment = File.expand_path(File.join(File.dirname(__FILE__), p, 'config/environment.rb'))
  if File.exist?(environment)
    require environment
    true
  else
    # puts "No environment found at #{environment}"
    false
  end
end

if !found
  puts "Could not load environment"
  exit
end

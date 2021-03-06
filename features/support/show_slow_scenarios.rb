# Show slow scenarios
# Enable like this: `cucumber SHOW_SHOW_SCENARIOS=y`
#
# Use the built-in `cucumber --format usage` for steps finding slow steps.
if ENV["SHOW_SHOW_SCENARIOS"]
  scenarios = {}

  Around do |scenario, block|
    start = Time.now
    block.call
    scenarios[scenario.location.to_s] = {
      duration: (Time.now - start),
      name: scenario.name
    }
  end

  at_exit do
    puts "Slowest scenarios:".blue
    sorted = scenarios.sort { |a, b| b[1][:duration] <=> a[1][:duration] }
    sorted.each do |key, value|
      puts "#{value[:duration].round(2)} #{key.green} #{value[:name]}"
    end
  end
end

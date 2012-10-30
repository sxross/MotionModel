#!/usr/bin/env ruby

Dir["spec/*"].each do |fn|
  break unless system("rake spec files=#{fn}")
end

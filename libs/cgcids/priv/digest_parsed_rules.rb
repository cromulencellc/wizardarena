#!/usr/bin/env ruby

require 'fileutils'

dirname = File.dirname(__FILE__)

pass_dir = FileUtils.mkdir_p(File.expand_path("../test/passes", dirname))
fail_dir = FileUtils.mkdir_p(File.expand_path("../test/failures", dirname))

File.open(File.expand_path("../tmp/parsed.txt", dirname)) do |f|
  f.each_line.each_with_index do |line, idx|
    out_dir = pass_dir
    out_dir = fail_dir if 'FAIL' ==  line[0..3]

    File.open(File.join(out_dir, "test_#{idx}.rules"), 'w') do |o|
      o.write line[5..-1]
    end
  end
end

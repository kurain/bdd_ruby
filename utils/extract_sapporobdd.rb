# -*- coding: utf-8 -*-
require 'zip'

bdd_zip      = ARGV[0]
exteranl_dir = File.dirname(__FILE__) + "/../ext"

Zip::File.open(bdd_zip) do |zip|
  zip.glob('*/src/BDD[c+]/*').each do |entry|
    if entry.to_s =~ /\/(BDD\.cc|ZBDD\.cc|bddc\.c)$/
      zip.extract(entry, exteranl_dir + '/' + File.basename(entry.to_s)) { true }
    end

  end

  zip.glob('*/include/*').each do |entry|
    if entry.to_s =~ /\/(BDD\.h|ZBDD\.h|bddc\.h)$/
      zip.extract(entry, exteranl_dir + '/' + File.basename(entry.to_s)) { true }
    end
  end
end

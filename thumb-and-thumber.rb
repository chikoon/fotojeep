#!/usr/bin/ruby

help = """
Creates a shell script that makes 800x600 thumbnails
of the jpgs in the current directory.

Sample use from \".\"
~/scripts/ruby/thumb-and-thumber.rb  > thumbit.sh
"""

# ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=

dimensions = '800x600'
quality = '60'
from_dir = './'
to_dir = './%s/' % dimensions
convert_path = '/usr/bin/convert'
bash_path = '#!/bin/bash'
force = false
verbose = false

# ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=

if not File.exists?(to_dir)
	print "\n%s does not exist" % to_dir
	print "\n%s" % help
	exit()
end

# ~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=

print "%s\n" % bash_path
for i in Dir.entries(from_dir)
	if /(\.jpg)$/i.match(i)
		to_path = "%s%s" % [to_dir,i]
		cmd = "%s %s%s -size %s -resize %s -compress JPEG -quality %s %s" \
			% [convert_path, from_dir, i, dimensions, dimensions, quality, to_path]
		if File.exists?(to_path) and not force
			if verbose
				print "\necho \"# skipping %s\"" % cmd
			end
		else
			print "\necho \"%s\"" % cmd
			print "\n%s" % cmd
		end
	end
end

print "\n\n# tar -cvf 800x600.tar %s*" % to_dir
print "\n\n# zip 800x600.zip %s*" % to_dir

# done!




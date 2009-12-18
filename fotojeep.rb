#!/usr/bin/ruby

$LOAD_PATH.unshift(".")

require 'net/http'
require 'parsedate'
require 'ftools'

a = ARGV;

defaults = {
	'from_dir' 	=> '/Volumes/NO NAME/DCIM/100OLYMP/',
	'to_dir' 	=> '/Users/chikoon/Pictures/incoming/_to-adjust/',
	#'re_token' 	=> '102_'
	#'re_token' 	=> 'P9'
        #'re_token'      => nil
        're_token'      => /(\d{3}\.[^\.]+)$/
}

params = {
	'from_dir' 	=> (a[1]) ? a[1]:defaults['from_dir'],
	'to_dir' 	=> (a[2]) ? a[2]:defaults['to_dir'],
	're_token'	=> defaults['re_token'],
	'expunge' 	=> ((a && a[0] && /(\-.*x)/.match(a[0]))?1:nil),
	'force' 	=> ((a && a[0] && /(\-.*f)/.match(a[0]))?1:nil),
	'test' 		=> ((a && a[0] && /(\-.*t)/.match(a[0]))?1:nil),
	'help' 		=> ((a && (a[0] && /(\-.*h)/.match(a[0])))?1: nil)
}

class FotoJeep
	def initialize( params={} )
		@from_dir 	= (params['from_dir']) 	? params['from_dir']	: '.'
		@to_dir 	= (params['to_dir']) 	? params['to_dir']		: './fotojeep/'
		@re_token	= (params['re_token'])	? params['re_token']	: 'chicken'
		@expunge 	= (params['expunge']) 	? params['expunge']		: nil
		@test 		= (params['test']) 		? params['test']		: nil
		@force 		= (params['force']) 	? params['force']		: nil
	end
	def trace(str, eol="\n")
            puts("%s%s" % [str,eol])
	end
	def transfer(from_dir, to_dir, re_token=nil, expunge=nil)
		if !from_dir[/\/$/]
			from_dir = from_dir + "/"
		end
		r = []
		if not File.exists?(from_dir)
			return(r)
		end
		for i in Dir.entries(from_dir)
			if i[0] == '.'
				next
			elsif re_token and !i[re_token]
				next
                        elsif  !/\.(jpe?g|gif|png|avi)$/i.match(i)
                               next
			else
				old_path = "%s%s" % [from_dir,i]
				new_prefix = "%s_" % File.mtime(old_path).strftime("%Y%m%d");
                                suffix = (re_token) ? i.match(re_token) : i;
				new_name = "%s%s" % [new_prefix,suffix];
				new_path = "%s%s" % [to_dir,new_name]
				exists = File.exists?(new_path);
				if @test
					trace("testing")
					ok = ".."
				elsif exists and not @force
					trace("skipping")
					ok = "file exists %s" % new_path;
				elsif expunge
					if @force
						trace("force moving")
					else
						trace("moving")
					end
					ok = File.mv(old_path, new_path);
				else
					if @force
						trace("force copying")
					else
						trace("copying")
					end
					ok = File.syscopy(old_path, new_path);
				end
				trace("from: %s" % old_path);
				trace("to: %s" % new_path);
				trace("ok!? => %s" % ok);
			end
			r.push(from_dir + i)
		end
		return(r)
	end
end

# a couple of globals
from_dir = params['from_dir'];
to_dir = params['to_dir'];
re_token = params['re_token'];
expunge = params['expunge'];

# instantiate class
fj = FotoJeep.new(params);

# stdout
if params['help']
	help = """
	[FOTOJEEP]

	<syntax>
	./fotojeep -dftx [from_dir] [to_dir]

	<arguments>
	-d 		[to_dir]	path to destination or target directory.
	-f		force		overwrite existing files in $to_dir.
	-h		help		show this help menu.
	-t		test		perform no operation. only traces.
	-x		expunge		perform an mv operation (default-> syscopy).

	<examples>
	# see default info without transferring
	./fotojeep -t
	# copy files to default_to_dir
	./fotojeep
	# copy files to a specific target directory
	./fotojeep -d ./temp
	# move files to default_to_dir
	./fotojeep -x
	# move files to a specific target directory, overwriting existing files
	./fotojeep -dfx ./temp"""




	fj.trace(help);
	exit
else
	fj.trace("test: %s" % [((params['test'])?'yes':'no')])
	fj.trace("force: %s" % [((params['force'])?'yes':'no')])
	fj.trace("expunge: %s" % [((params['expunge'])?'yes':'no')])
	fj.trace("re_token: %s" % params['re_token'])
	fj.trace("from_dir: %s" % params['from_dir'])
	fj.trace("to_dir: %s" % params['to_dir'])
	if params['test']
		fj.trace("exiting")
		exit;
	else
		fj.trace("---\nSearching images in %s" % from_dir)
	end

end

# run transfer
files = fj.transfer(from_dir, to_dir, re_token, expunge);

# done
fj.trace("%d files found" % [files.length]);





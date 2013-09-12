#!/usr/bin/env ruby

fname = ARGV[0]

File.open(fname) {|f|
	fsize = f.size
	pos = 0
	while pos <= fsize - 8
		bsize = f.read(4).unpack('L>')[0]
		type = f.read(4)
		pos += 8
		if bsize == 0
			puts "Size in quad"
			bsize = f.read(8).unpack('Q>') - 16
			pos += 8
		elsif bsize == 1
			puts "To EOF"
			bsize = fsize - pos
		else
			bsize -= 8
		end
		puts "Got box size=#{bsize}, type=#{type.inspect}"
		pos += bsize
		f.seek(pos)
	end
	puts "Ended at pos=#{pos}, fsize=#{fsize}, diff=#{fsize-pos}"
}

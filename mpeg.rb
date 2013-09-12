#!/usr/bin/env ruby

fname = ARGV[0]
boxes = Hash.new{|h,k| h[k] = [] }

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
		boxes[type] << [pos, bsize]
		pos += bsize
		f.seek(pos)
	end
	puts "Ended at pos=#{pos}, fsize=#{fsize}, diff=#{fsize-pos}"

	get_box = lambda {|array|
		f.seek(array[0])
		f.read(array[1])
	}

	if boxes.has_key? 'ftyp'
		ftyp = get_box.call(boxes['ftyp'][0])
		major_brand = ftyp[0...4]
		minor_version = ftyp[4...8].unpack('L>')[0]
		compat_brands = ftyp[8..-1].scan(/.{4}/m)
		puts "Brand is #{major_brand.inspect} version #{minor_version}"
		puts "Compatible brands are #{compat_brands.inspect}"
	else
		puts "File does not have an 'ftyp' box"
	end
}

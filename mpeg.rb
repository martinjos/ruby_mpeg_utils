#!/usr/bin/env ruby

fname = ARGV[0]

def get_box_info(f, start=0, size=f.size)
	boxes = Hash.new{|h,k| h[k] = [] }

	pos = start
	end_pos = start + size

	while pos <= end_pos - 8
		f.seek(pos)
		bsize = f.read(4).unpack('L>')[0]
		type = f.read(4)
		pos += 8
		if bsize == 0
			puts "Size in quad"
			bsize = f.read(8).unpack('Q>')[0] - 16
			pos += 8
		elsif bsize == 1
			puts "To end_pos"
			bsize = end_pos - pos
		else
			bsize -= 8
		end
		puts "Got box pos=#{pos} size=#{bsize}, type=#{type.inspect}"
		boxes[type] << [pos, bsize]
		pos += bsize
	end
	puts "Ended at pos=#{pos}, end_pos=#{end_pos}, diff=#{end_pos-pos}"
	boxes
end

File.open(fname) {|f|
	boxes = get_box_info(f)

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

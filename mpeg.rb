#!/usr/bin/env ruby

require 'matrix'

fname = ARGV[0]

def get_box_info(f, info=[0, f.size])
	(start, size) = info

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

def get_box(f, array)
	f.seek(array[0])
	f.read(array[1])
end

def read_bytes(f, pos, size)
	f.seek(pos)
	f.read(size)
end

def write_bytes(f, pos, bytes)
	f.seek(pos)
	f.write(bytes)
end

def rot_mat(f, pos, do_rot)
	bytes = read_bytes(f, pos, 9*4)
	matrix = Matrix.rows bytes.unpack('l>9').each_slice(3).to_a
	p matrix
	if do_rot
		rot = Matrix.rows [[0, -1, 0], [1, 0, 0], [0, 0, 1]]
		newmat = rot * matrix
		p rot
		p newmat
		write_bytes(f, pos, newmat.to_a.flatten.pack('l>9'))
	end
end

File.open(fname, "r+") {|f|
	boxes = get_box_info(f)

	if boxes.has_key? 'ftyp'
		ftyp = get_box(f, boxes['ftyp'][0])
		major_brand = ftyp[0...4]
		minor_version = ftyp[4...8].unpack('L>')[0]
		compat_brands = ftyp[8..-1].scan(/.{4}/m)
		puts "Brand is #{major_brand.inspect} version #{minor_version}"
		puts "Compatible brands are #{compat_brands.inspect}"
	else
		puts "File does not have an 'ftyp' box"
	end

	if boxes.has_key? 'moov'
		mboxes = get_box_info(f, boxes['moov'][0])

		if mboxes.has_key? 'mvhd'
			mvhd = get_box(f, mboxes['mvhd'][0])
			version = mvhd[0].ord
			flags = mvhd[0...4].unpack('L>')[0] | 0xffffff
			puts "Got 'mvhd' version #{version}"
			rot_mat(f, mboxes['mvhd'][0][0] + 36, false)
		else
			puts "File does not have a moov:mvhd box"
		end

		mboxes['trak'].each{|trak_info|
			tboxes = get_box_info(f, trak_info)
			
			if tboxes.has_key? 'tkhd'
				tkhd = get_box(f, tboxes['tkhd'][0])
				version = tkhd[0].ord
				flags = tkhd[0...4].unpack('L>')[0] | 0xffffff
				puts "Got 'tkhd' version #{version}"
				rot_mat(f, tboxes['tkhd'][0][0] + 40, false)
			else
				puts "Track does not have a moov:trak:tkhd box"
			end
		}

	else
		puts "File does not have a 'moov' box"
	end
}

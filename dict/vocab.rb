# Use /( .+?){3}\n/ to match 3-syll word

puts filename = ARGV[0]
words = File.open(filename).read.split("\n").uniq

selected = [] 
words.each{ |w| 
	w = w.strip.gsub(/\s+\d+/, "");
	next if w =~ /[^\sa-z\|]/

	a = w.split(" ")
	n = a.size
	next if n > 9
	next if w.count("|") != n

	selected << [n, a.join(" ").gsub("|","`")]
}

File.open(filename, "wt") { |f|
	f.puts selected.sort { |a, b| 
		r = a[0] <=> b[0]
		r == 0 ? a[1] <=> b[1] : r
	}.map{ |x| x[1].gsub("`","|") }.uniq
}
 
# words_sylls = words.map{ |w| w.split(" ") }
# words_sylls.sort_by! { |x| x.size }
# puts words_sylls.map{ |x| x.join(" ") }
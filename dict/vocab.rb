# Use /( .+?){3}\n/ to match 3-syll word

puts filename = ARGV[0]
words = File.open(filename).read.split("\n").uniq

selected = [] 
words.each{ |w| 
	w.gsub!(/\s+\d+\s*/, "");
	a = w.split(" ")
	n = a.size
	next if w =~ /[^\sa-z\|]/
	next if n < 2 or n > 4
	next if w.count("|") != n
	selected << a.join(" ").gsub("|","`") 
}

File.open(filename, "wt") { |f|
	f.puts selected.sort.map{ |x| x.gsub("`","|") }.uniq
}
 
# words_sylls = words.map{ |w| w.split(" ") }
# words_sylls.sort_by! { |x| x.size }
# puts words_sylls.map{ |x| x.join(" ") }
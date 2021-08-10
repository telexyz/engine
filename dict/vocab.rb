# Use /( .+?){3}\n/ to match 3-syll word
words = File.open("wordlist.xyz").read.split("\n").uniq

selected = [] 
words.each{ |w| 
	a = w.split(" ")
	n = a.size
	next if w =~ /[^\sa-z\|]/
	next if n < 2 or n > 4
	next if w.count("|") != n
	selected << a.join(" ").gsub("|","`") 
}
puts selected.sort.map{ |x| x.gsub("`","|") }.uniq
 
# words_sylls = words.map{ |w| w.split(" ") }
# words_sylls.sort_by! { |x| x.size }
# puts words_sylls.map{ |x| x.join(" ") }
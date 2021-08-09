# Use /( .+?){3}\n/ to match 3-syll word

words = File.open("wordlist.xyz").read.split("\n").uniq

selected = [] 
words.each{ |w| 
	a = w.split(" ") 
	selected << a.join(" ").gsub("|","_") if a.size >= 2 and a.size <= 4
}

selected.sort!
puts selected.map{ |x| x.gsub("_","|") }

# words_sylls = words.map{ |w| w.split(" ") }
# words_sylls.sort_by! { |x| x.size }
# puts words_sylls.map{ |x| x.join(" ") }
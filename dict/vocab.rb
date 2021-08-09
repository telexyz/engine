# Use /( .+?){3}\n/ to match 3-syll word

words = File.open("wordlist.txt").read.split("\n").uniq
 
words_sylls = words.map{ |w| w.split(" ") }

words_sylls.sort_by! { |x|
	x.size
}

puts words_sylls.map{ |x| x.join(" ") }
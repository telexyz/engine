words = File.open("VnVocab.txt").read.split("\n").uniq
 
words_sylls = words.map{ |w| w.split(" ") }

words_sylls.sort_by! { |x|
	x.size
}

puts words_sylls.map{ |x| x.join(" ") }
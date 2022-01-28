#!/bin/sh

# brew install miniconda
# conda config --env --add channels conda-forge
# conda install numpy scipy

mkdir -p data

python ngram2vec/corpus2vocab.py --corpus_file Phaps.xyz --vocab_file data/vocab --memory_size 4 --feature ngram --order 2

python ngram2vec/corpus2pairs.py --corpus_file Phaps.xyz --pairs_file data/pairs --vocab_file data/vocab --processes_num 2 --cooccur ngram_ngram --input_order 1 --output_order 2

# Concatenate pair files. 
if [ -f "data/pairs" ]; then
	rm data/pairs
fi
for i in $(seq 0 1)
do
	cat data/pairs_${i} >> data/pairs
	rm data/pairs_${i}
done

# Generate input vocabulary and output vocabulary, which are used as vocabulary files for all models
python ngram2vec/pairs2vocab.py --pairs_file data/pairs --input_vocab_file data/vocab.input --output_vocab_file data/vocab.output

# SGNS, learn representation upon pairs.
# We add a python interface upon C code.
./word2vec --pairs_file data/pairs --input_vocab_file data/vocab.input --output_vocab_file data/vocab.output --input_vector_file data/sgns.input --output_vector_file data/sgns.output --threads_num 2 --size 300
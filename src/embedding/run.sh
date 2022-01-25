#!/bin/sh

# brew install miniconda
# conda config --env --add channels conda-forge
# conda install numpy scipy

# Edited from https://raw.githubusercontent.com/zhezhaoa/ngram2vec/master/ngram_example.sh
memory_size=4
cpus_num=1
corpus=/Users/t/repos/telexyz/phaps/data/all.txt
output_path=data

mkdir -p ${output_path}

python ngram2vec/corpus2vocab.py --corpus_file ${corpus} --vocab_file ${output_path}/vocab --memory_size ${memory_size} --feature ngram --order 2
python ngram2vec/corpus2pairs.py --corpus_file ${corpus} --pairs_file ${output_path}/pairs --vocab_file ${output_path}/vocab --processes_num ${cpus_num} --cooccur ngram_ngram --input_order 1 --output_order 2

# Concatenate pair files. 
if [ -f "${output_path}/pairs" ]; then
	rm ${output_path}/pairs
fi
for i in $(seq 0 $((${cpus_num}-1)))
do
	cat ${output_path}/pairs_${i} >> ${output_path}/pairs
	rm ${output_path}/pairs_${i}
done

# Generate input vocabulary and output vocabulary, which are used as vocabulary files for all models
python ngram2vec/pairs2vocab.py --pairs_file ${output_path}/pairs --input_vocab_file ${output_path}/vocab.input --output_vocab_file ${output_path}/vocab.output

# SGNS, learn representation upon pairs.
# We add a python interface upon C code.
python ngram2vec/pairs2sgns.py --pairs_file ${output_path}/pairs --input_vocab_file ${output_path}/vocab.input --output_vocab_file ${output_path}/vocab.output --input_vector_file ${output_path}/sgns.input --output_vector_file ${output_path}/sgns.output --threads_num ${cpus_num} --size 300
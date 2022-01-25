#!/bin/sh
# Edited from https://raw.githubusercontent.com/zhezhaoa/ngram2vec/master/ngram_example.sh

memory_size=4
cpus_num=1
# corpus=/Users/t/repos/telexyz/phaps/data/sachs
# corpus=/Users/t/repos/telexyz/phaps/data/all.txt
output_path=output

# SGNS evaluation.
python ngram2vec/similarity_eval.py --input_vector_file ${output_path}/sgns/sgns.input  --test_file testsets/similarity/ws353_similarity.txt --normalize
python ngram2vec/analogy_eval.py --input_vector_file ${output_path}/sgns/sgns.input --test_file testsets/analogy/semantic.txt --normalize
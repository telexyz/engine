#!/bin/sh
output_path=data

# SGNS evaluation.
python ngram2vec/similarity_eval.py --input_vector_file ${output_path}/sgns.input  --test_file testsets/similarity/ws353_similarity.txt --normalize
python ngram2vec/analogy_eval.py --input_vector_file ${output_path}/sgns.input --test_file testsets/analogy/semantic.txt --normalize
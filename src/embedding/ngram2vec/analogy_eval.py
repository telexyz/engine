# -*- coding: utf-8 -*-

from __future__ import print_function, unicode_literals
import argparse
import codecs
import numpy as np
from scipy.stats.stats import spearmanr
import sys
from utils.misc import normalize
from utils.matrix import load_dense, load_sparse
from eval.testset import load_analogy, get_ana_vocab
from eval.similarity import prepare_similarities
from eval.recast import retain_words, align_matrix


def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--input_vector_file", type=str, required=True,
                        help="")
    parser.add_argument("--output_vector_file", type=str,
                        help="")
    parser.add_argument("--test_file", type=str, required=True,
                        help="")
    parser.add_argument('--sparse', action='store_true',
                        help="Load sparse representation.")
    parser.add_argument('--normalize', action='store_true',
                        help="If set, vector is normalized.")
    parser.add_argument("--ensemble", type=str, default="input",
                        choices=["input", "output", "add", "concat"],
                        help="""Strategies for using input/output vectors.
                        One can use only input, only output, the addition of input and output,
                        or their concatenation. Options are
                        [input|output|add|concat].""")

    args = parser.parse_args()
    
    testset = load_analogy(args.test_file)
    ana_vocab, vocab = {}, {}
    ana_vocab["i2w"], ana_vocab["w2i"] = get_ana_vocab(testset)
    if args.sparse:
        matrix, vocab, _ = load_sparse(args.input_vector_file)
    else:
        matrix, vocab, _ = load_dense(args.input_vector_file)

    if not args.sparse:
        if args.ensemble == "add":
            output_matrix, output_vocab, _ = load_dense(args.output_vector_file)
            output_matrix = align_matrix(matrix, output_matrix, vocab, output_vocab)
            matrix = matrix + output_matrix
        elif args.ensemble == "concat":
            output_matrix, output_vocab, _ = load_dense(args.output_vector_file)
            output_matrix = align_matrix(matrix, output_matrix, vocab, output_vocab)
            matrix = np.concatenate([matrix, output_matrix], axis=1)
        elif args.ensemble == "output":
            matrix, vocab, _ = load_dense(args.output_vector_file)
        else: # args.ensemble == "input"
            pass

    if args.normalize:
        matrix = normalize(matrix, args.sparse)

    matrix, vocab["i2w"], vocab["w2i"] = retain_words(matrix, vocab["i2w"], vocab["w2i"])
    sim_matrix = prepare_similarities(matrix, ana_vocab, vocab, sparse=args.sparse)

    seen, correct_add, correct_mul = 0, 0, 0
    for a, a_, b, b_ in testset:
        if a not in vocab["i2w"] or a_ not in vocab["i2w"] or b not in vocab["i2w"]:
            continue
        seen += 1
        guess_add, guess_mul = guess(sim_matrix, ana_vocab, vocab, a, a_, b)
        if guess_add == b_:
            correct_add += 1
        if guess_mul == b_:
            correct_mul += 1
    accuracy_add = float(correct_add) / seen
    accuracy_mul = float(correct_mul) / seen
    print("seen/total: {}/{}".format(seen, len(testset)))
    print("{}: {:.3f} {:.3f}".format(args.test_file, accuracy_add, accuracy_mul))


def guess(sim_matrix, ana_vocab, vocab, a, a_, b):
    sa = sim_matrix[ana_vocab["w2i"][a]]
    sa_ = sim_matrix[ana_vocab["w2i"][a_]]
    sb = sim_matrix[ana_vocab["w2i"][b]]
    
    sim_add = sa_ + sb - sa
    sim_add[vocab["w2i"][a]] = 0
    sim_add[vocab["w2i"][a_]] = 0
    sim_add[vocab["w2i"][b]] = 0
    guess_add = vocab["i2w"][np.nanargmax(sim_add)]
    
    sim_mul = sa_ * sb * np.reciprocal(sa+0.01)
    sim_mul[vocab["w2i"][a]] = 0
    sim_mul[vocab["w2i"][a_]] = 0
    sim_mul[vocab["w2i"][b]] = 0
    guess_mul = vocab["i2w"][np.nanargmax(sim_mul)]
    
    return guess_add, guess_mul


if __name__ == '__main__':
    main()

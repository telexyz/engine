// Sources:
// * https://raw.githubusercontent.com/zhezhaoa/ngram2vec/master/word2vec/word2vec.c
// * https://github.com/chrisjmccormick/word2vec_commented/blob/master/word2vec.c
// 
/////////////////////////////////////////////////////////////////
// Modifed by tiendung, 2022
// TODO: Sử dụng token_id, đơn giản hóa quản lý vocab
// * Add comments
// 
/////////////////////////////////////////////////////////////////
// Modifed by ZheZhao, Renmin University of China, 2018
// fix some bugs such as training info printing 
// delete irrelevant code
//
/////////////////////////////////////////////////////////////////
// Modifed by Yoav Goldberg, Jan-Feb 2014
// Removed:
//    hierarchical-softmax training
//    cbow
// Added:
//   - support for different vocabularies for words and contexts
//   - different input syntax
//
/////////////////////////////////////////////////////////////////
//  Copyright 2013 Google Inc. All Rights Reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>


#define MAX_STRING 100
#define EXP_TABLE_SIZE 1000
#define MAX_EXP 6

/*
 * The size of the hash table for the vocabulary.
 * The vocabulary won't be allowed to grow beyond 70% of this number.
 * For instance, if the hash table has 70M entries, then the maximum
 * vocab size is 49M. This is to minimize the occurrence (and performance
 * impact) of hash collisions.
 */
const long long vocab_hash_size = 70000000; // Maximum 70 * 0.7 = 49M words

typedef float real; // Precision of float numbers

struct vocab_word {
  long long cn; // The word frequency (number of times it appears).
  char *word;   // The actual string word.
};

struct vocabulary {
   struct vocab_word *vocab;
   long long *vocab_hash;
   long long vocab_max_size; //1000
   long long vocab_size;
   long long pairs_num;
};

char pairs_file[MAX_STRING];
char input_vocab_file[MAX_STRING], output_vocab_file[MAX_STRING];
char input_vector_file[MAX_STRING], output_vector_file[MAX_STRING];
int debug_mode = 2, num_threads = 1;
long long vec_size = 100;
long long pairs_num = 0, pairs_count_actual = 0, file_size = 0, classes = 0;

/*
 * ======== alpha ========
 * This is a learning rate parameter.
 *
 * ======== sample ========
 * This parameter controls the subsampling of frequent words.
 * Smaller values of 'sample' mean words are less likely to be kept.
 * Set 'sample' to 0 to disable subsampling.
 * See the comments in the subsampling section for more details.
 */
real alpha = 0.025, starting_alpha, sample = 0;

/*
 * IMPORTANT - Note that the weight matrices are stored as 1D arrays, not
 * 2D matrices, so to access row 'i' of syn0, the index is (i * layer1_size).
 * 
 * ======== syn0 ========
 * This is the hidden layer weights (which is also the word vectors!)
 *
 * ======== syn1neg ========
 * This is the output layer weights using negative sampling
 *
 * ======== expTable ========
 * Stores precalcultaed activations for the output layer.
 */
real *syn0, *syn1neg, *expTable;
clock_t start;
int numiters = 1;

struct vocabulary *input_vocab;
struct vocabulary *output_vocab;

int negative = 15;
const long long table_size = 1e8;
long long *samplingtable;


/**
 * ======== InitSamplingTable ========
 * This table is used to implement negative sampling.
 * Each word is given a weight equal to it's frequency (word count) raised to
 * the 3/4 power. The probability for a selecting a word is just its weight 
 * divided by the sum of weights for all words. 
 *
 * Note that the vocabulary has been sorted by word count, descending, such 
 * that we will go through the vocabulary from most frequent to least.
 */
void InitSamplingTable(struct vocabulary *v) {
  long long a, i;
  long long normalizer = 0;
  real d1, power = 0.75; // 3/4

  // Allocate the table. It's bigger than the vocabulary, because words will
  // appear in it multiple times based on their frequency.
  // Every vocab word appears at least once in the table.
  // The size of the table relative to the size of the vocab dictates the 
  // resolution of the sampling. A larger table means the negative 
  // samples will be selected with a probability that more closely matches the
  // probability calculated by the equation.
  samplingtable = (long long *)malloc(table_size * sizeof(long long));

  // Calculate the denominator, which is the sum of weights for all words.
  for (a = 0; a < v->vocab_size; a++) normalizer += pow(v->vocab[a].cn, power);
 
  // 'i' is the vocabulary index of the current word, whereas 'a' will be
  // the index into the table.
  i = 0;

  // Calculate the probability that we choose word 'i'. This is a fraction
  // between 0 and 1.
  d1 = pow(v->vocab[i].cn, power) / (real)normalizer;

  // Loop over all positions in the table.
  for (a = 0; a < table_size; a++) {

    // Store word 'i' in this position. Word 'i' will appear multiple times
    // in the table, based on its frequency in the training data.    
    samplingtable[a] = i;

    // If the fraction of the table we have filled is greater than the
    // probability of choosing this word, then move to the next word.
    if (a / (real)table_size > d1) {
      // Move to the next word.
      i++;

      // Calculate the probability for the new word, and accumulate it with 
      // the probabilities of all previous words, so that we can compare d1 to
      // the percentage of the table that we have filled.
      d1 += pow(v->vocab[i].cn, power) / (real)normalizer;
    }

    // Don't go past the end of the vocab. 
    // The total weights for all words should sum up to 1, so there shouldn't
    // be any extra space at the end of the table. Maybe it's possible to be
    // off by 1, though? Or maybe this is just precautionary.
    if (i >= v->vocab_size) i = v->vocab_size - 1;
  }
}


/**
 * ======== ReadWord ========
 * Reads a single word from a file, assuming space + tab + EOL to be word 
 * boundaries.
 *
 * Parameters:
 *   word - A char array allocated to hold the maximum length string.
 *   fin  - The training file.
 */
void ReadWord(char *word, FILE *fin) {

  // 'a' will be the index into 'word'.
  int a = 0, ch;

  // Read until the end of the word or the end of the file.
  while (!feof(fin)) {

    // Get the next character.
    ch = fgetc(fin);

    // ASCII Character 13 is a carriage return 'CR' whereas character 10 is 
    // newline or line feed 'LF'.
    if (ch == 13) continue;

    // Check for word boundaries...
    if ((ch == ' ') || (ch == '\t') || (ch == '\n')) {

      // If the word has at least one character, we're done.
      if (a > 0) break;
      // If the word is empty and the character is tab or space, just continue
      // on to the next character.     
      else continue; 
    }

    // If the character wasn't space, tab, CR, or newline, add it to the word.
    word[a] = ch;
    a++;

    // If the word's too long, truncate, but keep going till we find the end.
    if (a >= MAX_STRING - 1) a--;
  }

  // Terminate the string with null.
  word[a] = 0;
}


/**
 * ======== GetWordHash ========
 * Returns hash value of a word. The hash is an integer between 0 and 
 * vocab_hash_size (default is 30E6).
 * long long = u64
 *
 * For example, the word 'hat':
 * hash = ((((h * 257) + a) * 257) + t) % 30E6
 */
unsigned long long GetWordHash(char *word) {
  unsigned long long a, hash = 0;
  for (a = 0; a < strlen(word); a++) hash = hash * 257 + word[a];
  hash = hash % vocab_hash_size;
  return hash;
}


/**
 * ======== SearchVocab ========
 * Lookup the index in the 'vocab' table of the given 'word'.
 * Returns -1 if the word is not found.
 * This function uses a hash table for fast lookup.
 */
long long SearchVocab(struct vocabulary *v, char *word) {

  // Compute the hash value for 'word'.
  unsigned long long hash = GetWordHash(word);

  // Lookup the index in the hash table, handling collisions as needed.
  // See 'AddWordToVocab' to see how collisions are handled.
  while (1) {
    if ((v->vocab_hash)[hash] == -1) return -1;
    if (!strcmp(word, v->vocab[v->vocab_hash[hash]].word)) return v->vocab_hash[hash];
    hash = (hash + 1) % vocab_hash_size;
  }
  return -1;
}

/**
 * ======== AddWordToVocab ========
 * Adds a new word to the vocabulary (one that hasn't been seen yet).
 */
long long AddWordToVocab(struct vocabulary *v, char *word) {
  unsigned long long hash;

  // Measure word length.
  int length = strlen(word) + 1;

  // Limit string length (default limit is 100 characters).
  if (length > MAX_STRING) length = MAX_STRING;

  // Allocate and store the word string.
  v->vocab[v->vocab_size].word = (char *)calloc(length, sizeof(char));
  strcpy(v->vocab[v->vocab_size].word, word);
  
  // Initialize the word frequency to 0.
  v->vocab[v->vocab_size].cn = 0;

  // Increment the vocabulary size.
  v->vocab_size++;

  // Reallocate memory if needed
  if (v->vocab_size + 2 >= v->vocab_max_size) {
    v->vocab_max_size += 1000;
    v->vocab = (struct vocab_word *)realloc(v->vocab, v->vocab_max_size * sizeof(struct vocab_word));
  }


  // Add the word to the 'vocab_hash' table so that we can map quickly from the
  // string to its vocab_word structure. 
  
  // Hash the word to an integer between 0 and 30E6.
  hash = GetWordHash(word);

  // If the spot is already taken in the hash table, find the next empty spot.
  while (v->vocab_hash[hash] != -1) hash = (hash + 1) % vocab_hash_size;

  // Map the hash code to the index of the word in the 'vocab' array.  
  v->vocab_hash[hash] = v->vocab_size - 1;

  // Return the index of the word in the 'vocab' array.
  return v->vocab_size - 1;
}


struct vocabulary *CreateVocabulary() {
   struct vocabulary *v = malloc(sizeof(struct vocabulary));
   long long a;
   v->vocab_max_size = 1000;
   v->vocab_size = 0;
   v->vocab = (struct vocab_word *)calloc(v->vocab_max_size, sizeof(struct vocab_word));
   v->vocab_hash = (long long *)calloc(vocab_hash_size, sizeof(long long));
   for (a = 0; a < vocab_hash_size; a++) v->vocab_hash[a] = -1;
   return v;
}

void SaveVocab(struct vocabulary *v, char *save_vocab_file) {
  long long i;
  FILE *fo = fopen(save_vocab_file, "wb");
  for (i = 0; i < v->vocab_size; i++) fprintf(fo, "%s %lld\n", v->vocab[i].word, v->vocab[i].cn);
  fclose(fo);
}


/**
 * ======== ReadWordIndex ========
 * Reads the next word from the training file, and returns its index into the
 * 'vocab' table.
 */
long long ReadWordIndex(struct vocabulary *v, FILE *fin) {
  char word[MAX_STRING];
  ReadWord(word, fin);
  if (feof(fin)) return -1;
  return SearchVocab(v, word);
}


struct vocabulary *ReadVocab(char *vocabfile) {
  long long a, i = 0;
  char c;
  char word[MAX_STRING];
  FILE *fin = fopen(vocabfile, "rb");
  if (fin == NULL) {
    printf("Vocabulary file not found\n");
    exit(1);
  }
  struct vocabulary *v = CreateVocabulary();
  v->pairs_num = 0;
  while (1) {
    ReadWord(word, fin);
    if (feof(fin)) break;
    a = AddWordToVocab(v, word);
    fscanf(fin, "%lld%c", &v->vocab[a].cn, &c);
    v->pairs_num += v->vocab[a].cn;
    i++;
  }
  printf("Vocab size: %lld\n", v->vocab_size);
  printf("Number of pairs: %lld\n", v->pairs_num);
  return v;
}

long long GetFileSize(char *fname) {
  long long fsize;
  FILE *fin = fopen(fname, "rb");
  if (fin == NULL) {
    printf("ERROR: file not found! %s\n", fname);
    exit(1);
  }
  fseek(fin, 0, SEEK_END);
  fsize = ftell(fin);
  fclose(fin);
  return fsize;
}


/**
 * ======== InitNet ========
 *
 */
void InitNet(struct vocabulary *input_vocab, struct vocabulary *output_vocab) {
   long long a, b;

  // Allocate the hidden layer of the network, which is what becomes the word vectors.
  // The variable for this layer is 'syn0'.
   a = posix_memalign((void **)&syn0, 128, (long long)input_vocab->vocab_size * vec_size * sizeof(real));

   if (syn0 == NULL) {printf("Memory allocation failed\n"); exit(1);}

  // Randomly initialize the weights for the hidden layer (word vector layer).
  // TODO - What's the equation here?
    for (b = 0; b < vec_size; b++) 
      for (a = 0; a < input_vocab->vocab_size; a++)
         syn0[a * vec_size + b] = (rand() / (real)RAND_MAX - 0.5) / vec_size;

  // Allocate the output layer of the network. 
  // The variable for this layer is 'syn1neg'.
  // This layer has the same size as the hidden layer, but is the transpose.
  a = posix_memalign((void **)&syn1neg, 128, (long long)output_vocab->vocab_size * vec_size * sizeof(real));

  if (syn1neg == NULL) {printf("Memory allocation failed\n"); exit(1);}

  // Set all of the weights in the output layer to 0.
  for (b = 0; b < vec_size; b++)
    for (a = 0; a < output_vocab->vocab_size; a++)
      syn1neg[a * vec_size + b] = 0;
}


/**
 * ======== TrainModelThread ========
 * This function performs the training of the model.
 */
void *TrainModelThread(void *id) {
  long long input = -1, output = -1;
  long long d;
  long long pairs_count = 0, last_pairs_count = 0;
  long long l1, l2, c, target, label;
  unsigned long long next_random = (unsigned long long)id;
  real f, g;
  clock_t now;

  real *neu1 = (real *)calloc(vec_size, sizeof(real));
  real *neu1e = (real *)calloc(vec_size, sizeof(real));
  FILE *fi = fopen(pairs_file, "rb");

  long long start_offset = file_size / (long long)num_threads * (long long)id;
  long long end_offset = file_size / (long long)num_threads * (long long)(id+1);

  /*
   * ======== Variables ========
   *        iter - This is the number of training epochs to run; default is 5.
   * pairs_count - The number of input words processed.
   */
  int iter;
  for (iter=0; iter < numiters; ++iter) {
     fseek(fi, start_offset, SEEK_SET);
     while (fgetc(fi) != '\n') { };
     long long pairs_num = input_vocab->pairs_num;
     while (1) {
        if (pairs_count - last_pairs_count > 10000) {
           pairs_count_actual += pairs_count - last_pairs_count;
           last_pairs_count = pairs_count;

           alpha = starting_alpha * (1 - pairs_count_actual / (real)(numiters*pairs_num + 1));
           if (alpha < starting_alpha * 0.0001) alpha = starting_alpha * 0.0001;

           /* DEBUG INFO */
           // if ((debug_mode > 1)) {
           //    now=clock();
           //    printf("%cAlpha: %f  Progress: %.2f%%  Pairs/thread/sec: %.2fk  ", 13, alpha,
           //          pairs_count_actual / (real)(numiters*pairs_num + 1) * 100,
           //          pairs_count_actual / ((real)(now - start + 1) / (real)CLOCKS_PER_SEC * 1000));
           //    fflush(stdout);
           // }
        }
        if (feof(fi) || ftell(fi) > end_offset) break;

        for (c = 0; c < vec_size; c++) neu1[c] = 0;
        for (c = 0; c < vec_size; c++) neu1e[c] = 0;

        input = ReadWordIndex(input_vocab, fi);
        output = ReadWordIndex(output_vocab, fi);

        // Track the total number of training words processed.
        pairs_count++;

        if (input < 0 || output < 0) continue;

        /*
         * ==== Negative sampling =====
         *
         * Rather than performing backpropagation for every word in our 
         * vocabulary, we only perform it for a few words (the number of words 
         * is given by 'negative').
         */

        // Calculate the index of the start of the weights for 'input'.
        l1 = input * vec_size;

        for (d = 0; d < negative + 1; d++) {

          // On the first iteration, we're going to train the positive sample.
           if (d == 0) {
              target = output;
              label = 1;

          // On the other iterations, we'll train the negative samples.
           } else {
              // Pick a random word to use as a 'negative sample';

              // Get a random integer.
              next_random = next_random * (unsigned long long)25214903917 + 11;
  
              // 'target' becomes the index of the word in the vocab to use as
              // the negative sample.
              target = samplingtable[(next_random >> 16) % table_size];

              // If the target is the special end of sentence token, then just
              // pick a random word from the vocabulary instead.
              if (target == 0) target = next_random % (output_vocab->vocab_size - 1) + 1;

              // Don't use the positive sample as a negative sample!
              if (target == output) continue;

              // Mark this as a negative example.
              label = 0;
           }

          // Get the index of the target word in the output layer.
           l2 = target * vec_size;

          // At this point, our two words are represented by their index into
          // the layer weights.
          // l1 - The index of our input word within the hidden layer weights.
          // l2 - The index of our output word within the output layer weights.
          // label - Whether this is a positive (1) or negative (0) example.
          
          // Calculate the dot-product between the input words weights (in 
          // syn0) and the output word's weights (in syn1neg).
          // Note that this calculates the dot-product manually using a for
          // loop over the vector elements!
           f = 0;
           for (c = 0; c < vec_size; c++) f += syn0[c + l1] * syn1neg[c + l2];

          // This block does two things:
          //   1. Calculates the output of the network for this training
          //      pair, using the expTable to evaluate the output layer
          //      activation function.
          //   2. Calculate the error at the output, stored in 'g', by
          //      subtracting the network output from the desired output, 
          //      and finally multiply this by the learning rate.
           if (f > MAX_EXP) g = (label - 1) * alpha;
           else if (f < -MAX_EXP) g = (label - 0) * alpha;
           else g = (label - expTable[(int)((f + MAX_EXP) * (EXP_TABLE_SIZE / MAX_EXP / 2))]) * alpha;

          // Multiply the error by the output layer weights.
          // Accumulate these gradients over the negative samples and the one
          // positive sample.
           for (c = 0; c < vec_size; c++) neu1e[c] += g * syn1neg[c + l2];

          // Update the output layer weights by multiplying the output error
          // by the hidden layer weights.
           for (c = 0; c < vec_size; c++) syn1neg[c + l2] += g * syn0[c + l1];
        }
        // Once the hidden layer gradients for the negative samples plus the 
        // one positive sample have been accumulated, update the hidden layer
        // weights. 
        // Note that we do not average the gradient before applying it.
        for (c = 0; c < vec_size; c++) syn0[c + l1] += neu1e[c];
     }
  }
  fclose(fi);
  free(neu1);
  free(neu1e);
  pthread_exit(NULL);
}

/**
 * ======== TrainModel ========
 * Main entry point to the training process.
 */
void TrainModel() {
  long a, b;

  FILE *fo1;
  FILE *fo2;
  file_size = GetFileSize(pairs_file);

  pthread_t *pt = (pthread_t *)malloc(num_threads * sizeof(pthread_t));
  printf("Starting training using file %s\n", pairs_file);

  starting_alpha = alpha;
  input_vocab = ReadVocab(input_vocab_file);
  output_vocab = ReadVocab(output_vocab_file);

  InitNet(input_vocab, output_vocab);
  InitSamplingTable(output_vocab);

  // Record the start time of training.
  start = clock();

  // Run training, which occurs in the 'TrainModelThread' function.
  for (a = 0; a < num_threads; a++) pthread_create(&pt[a], NULL, TrainModelThread, (void *)a);
  for (a = 0; a < num_threads; a++) pthread_join(pt[a], NULL);


  // Save the word vectors
  fo1 = fopen(input_vector_file, "wb");
  fprintf(fo1, "%lld %lld\n", input_vocab->vocab_size, vec_size);
  for (a = 0; a < input_vocab->vocab_size; a++) {
    fprintf(fo1, "%s ", input_vocab->vocab[a].word);
    for (b = 0; b < vec_size; b++) fprintf(fo1, "%lf ", syn0[a * vec_size + b]);
    fprintf(fo1, "\n");
  }
  fclose(fo1);

  fo2 = fopen(output_vector_file, "wb");
  fprintf(fo2, "%lld %lld\n", output_vocab->vocab_size, vec_size);
  for (a = 0; a < output_vocab->vocab_size; a++) {
      fprintf(fo2, "%s ", output_vocab->vocab[a].word);
      for (b = 0; b < vec_size; b++) fprintf(fo2, "%lf ", syn1neg[a * vec_size + b]);
      fprintf(fo2, "\n");
  }
  fclose(fo2);  
}

int ArgPos(char *str, int argc, char **argv) {
  int a;
  for (a = 1; a < argc; a++) if (!strcmp(str, argv[a])) {
    if (a == argc - 1) {
      printf("Argument missing for %s\n", str);
      exit(1);
    }
    return a;
  }
  return -1;
}

int main(int argc, char **argv) {
  int i;
  if (argc == 1) {
    printf("WORD VECTOR estimation toolkit\n\n");
    printf("Options:\n");
    printf("Hyper-parameters for training:\n");
    printf("\t-train <file>\n");
    printf("\t\tUse pairs data from <file> to train the model\n");
    printf("\t-input_vocab <file>\n");
    printf("\t\tinput vocabulary file\n");
    printf("\t-output_vocab <file>\n");
    printf("\t\toutput vocabulary file\n");
    printf("\t-input_vector <file>\n");
    printf("\t\tUse <file> to save the resulting input vectors\n");
    printf("\t-output_vector <file>\n");
    printf("\t\tUse <file> to save the resulting output vectors\n");

    printf("\t-size <int>\n");
    printf("\t\tSet size of word vectors; default is 100\n");
    printf("\t-negative <int>\n");
    printf("\t\tNumber of negative examples; default is 15, common values are 5 - 10 (0 = not used)\n");
    printf("\t-threads <int>\n");
    printf("\t\tUse <int> threads (default 1)\n");
    printf("\t-alpha <float>\n");
    printf("\t\tSet the starting learning rate; default is 0.025\n");
    printf("\t-iters <int>\n");
    printf("\t\tPerform i iterations over the data; default is 1\n");
    return 0;
  }
  pairs_file[0] = 0;
  input_vocab_file[0] = 0;
  output_vocab_file[0] = 0;
  input_vector_file[0] = 0;
  output_vector_file[0] = 0;

  if ((i = ArgPos((char *)"--pairs_file", argc, argv)) > 0) strcpy(pairs_file, argv[i + 1]);
  if ((i = ArgPos((char *)"--input_vocab_file", argc, argv)) > 0) strcpy(input_vocab_file, argv[i + 1]);
  if ((i = ArgPos((char *)"--output_vocab_file", argc, argv)) > 0) strcpy(output_vocab_file, argv[i + 1]);
  if ((i = ArgPos((char *)"--input_vector_file", argc, argv)) > 0) strcpy(input_vector_file, argv[i + 1]);
  if ((i = ArgPos((char *)"--output_vector_file", argc, argv)) > 0) strcpy(output_vector_file, argv[i + 1]);
  if ((i = ArgPos((char *)"--size", argc, argv)) > 0) vec_size = atoi(argv[i + 1]);
  if ((i = ArgPos((char *)"--debug", argc, argv)) > 0) debug_mode = atoi(argv[i + 1]);
  if ((i = ArgPos((char *)"--alpha", argc, argv)) > 0) alpha = atof(argv[i + 1]);
  if ((i = ArgPos((char *)"--negative", argc, argv)) > 0) negative = atoi(argv[i + 1]);
  if ((i = ArgPos((char *)"--threads_num", argc, argv)) > 0) num_threads = atoi(argv[i + 1]);
  if ((i = ArgPos((char *)"--iter", argc, argv)) > 0) numiters = atoi(argv[i+1]);

  if (pairs_file[0] == 0) { printf("must supply -train.\n\n"); return 0; }
  if (input_vocab_file[0] == 0) { printf("must supply -input_vocab.\n\n"); return 0; }
  if (output_vocab_file[0] == 0) { printf("must supply -output_vocab.\n\n"); return 0; }
  if (input_vector_file[0] == 0) { printf("must supply -input_vector.\n\n"); return 0; }
  if (output_vector_file[0] == 0) { printf("must supply -output_vector.\n\n"); return 0; }

  /*
   * ======== Precomputed Exp Table ========
   * To calculate the softmax output, they use a table of values which are
   * pre-computed here.
   *
   * From the top of this file:
   *   #define EXP_TABLE_SIZE 1000
   *   #define MAX_EXP 6
   *
   * First, let's look at this inner term:
   *     i / (real)EXP_TABLE_SIZE * 2 - 1
   * This is just a straight line that goes from -1 to +1.
   *    (0, -1.0), (1, -0.998), (2, -0.996), ... (999, 0.998), (1000, 1.0).
   *
   * Next, multiplying this by MAX_EXP = 6, it causes the output to range
   * from -6 to +6 instead of -1 to +1.
   *    (0, -6.0), (1, -5.988), (2, -5.976), ... (999, 5.988), (1000, 6.0).
   *
   * So the total input range of the table is 
   *    Range = MAX_EXP * 2 = 12
   * And the increment on the inputs is
   *    Increment = Range / EXP_TABLE_SIZE = 0.012
   *
   * Let's say we want to compute the output for the value x = 0.25. How do
   * we calculate the position in the table?
   *    index = (x - -MAX_EXP) / increment
   * Which we can re-write as:
   *    index = (x + MAX_EXP) / (range / EXP_TABLE_SIZE)
   *          = (x + MAX_EXP) / ((2 * MAX_EXP) / EXP_TABLE_SIZE)
   *          = (x + MAX_EXP) * (EXP_TABLE_SIZE / MAX_EXP / 2)
   *
   * The last form is what we find in the code elsewhere for using the table:
   *    expTable[(int)((f + MAX_EXP) * (EXP_TABLE_SIZE / MAX_EXP / 2))]
   * 
   */

  // Allocate the table, 1000 floats.
  expTable = (real *)malloc((EXP_TABLE_SIZE + 1) * sizeof(real));

  // For each position in the table...
  for (i = 0; i < EXP_TABLE_SIZE; i++) {
    // Calculate the output of e^x for values in the range -6.0 to +6.0.
    expTable[i] = exp((i / (real)EXP_TABLE_SIZE * 2 - 1) * MAX_EXP);
    // Precompute the exp() table

    // Currently the table contains the function exp(x).
    // We are going to replace this with exp(x) / (exp(x) + 1), which is
    // just the sigmoid activation function! 
    // Note that 
    //    exp(x) / (exp(x) + 1) 
    // is equivalent to 
    //    1 / (1 + exp(-x))
    expTable[i] = expTable[i] / (expTable[i] + 1);
    // Precompute f(x) = x / (x + 1)
  }

  TrainModel();
  return 0;
}

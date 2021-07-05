#!/bin/sh

mkdir zpaq715 && cd zpaq715
wget http://mattmahoney.net/dc/zpaq715.zip
unzip zpaq715.zip
make install
cd ..
wget https://archive.org/download/titles-fb-best_vi.text/titles-fb-best_vi.text.zpaq
zpaq x titles-fb-best_vi.text.zpaq
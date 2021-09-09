## Bolt: Accelerated Data Mining with Fast Vector Compression
https://github.com/dblalock/bolt/tree/master/assets

If you have a large collection of mostly-dense vectors and can tolerate lossy compression, Bolt can probably save you 10-200x space and compute time.


## Multiplying Matrices Without Multiplying
https://arxiv.org/pdf/2106.10860.pdf

Realistically, it'll be most useful for speeding up neural net inference on CPUs, but it'll take another couple papers to get it there; we need to generalize it to convolution and write the CUDA kernels to allow GPU training.

```sh
brew install swig  # for wrapping C++; use apt-get, yum, etc, if not OS X
pip3 install numpy  # bolt installation needs numpy already present
git clone https://github.com/dblalock/bolt.git
cd bolt && python3 setup.py install
pytest tests/  # optionally, run the tests
```

#include <stdio.h>
#include <emmintrin.h>

int main(void) {
	double A[4] __attribute__ ((aligned (16)));
	double B[4] __attribute__ ((aligned (16)));
	double C[4] __attribute__ ((aligned (16)));
	int lda = 2;
	int i = 0;

	__m128d c1,c2,a,b1,b2;

	A[0] = 1.0; A[1] = 0.0; A[2] = 0.0; A[3] = 1.0;
	B[0] = 1.0; B[1] = 2.0; B[2] = 3.0; B[3] = 4.0;
	C[0] = 0.0; C[1] = 0.0; C[2] = 0.0; C[3] = 0.0;

	c1 = _mm_load_pd(C+0*lda);
	c2 = _mm_load_pd(C+1*lda);

	for (i = 0; i < 2; i++) {
		a = _mm_load_pd(A+i*lda);
		b1 = _mm_load1_pd(B+i+0*lda);
		b2 = _mm_load1_pd(B+i+1*lda);
		c1 = _mm_add_pd(c1,_mm_mul_pd(a,b1));
		c2 = _mm_add_pd(c2,_mm_mul_pd(a,b2)); 
		_mm_store_pd(C+0*lda,c1);
		_mm_store_pd(C+1*lda,c2);
	}

	printf("%g,%g\n%g,%g\n",C[0],C[2],C[1],C[3]);
	return 0;
}
#include <stdio.h>

#define N 32

// 32x32 * 32x32 matrix multiply

void mult32x32x32 (bool A[N][N], bool B[N][N], bool C[N][N]) {
	int i, j, l;
	bool cij;
	for (i=0; i<N; i++)
		for (j=0; j<N; j++) {
			cij = false;
			for (l=0; l<N; l++) 
				cij ^= A[i][l] & B[l][j];
			C[i][j] = cij;
		}
}

// 32x32 * 32x1 matrix multiply

void mult32x32x1 (bool A[N][N], bool B[N][1], bool C[N][1]) {
        int i, l;
        bool    cij;
        for (i=0; i<N; i++) {
                cij = false;
                for (l=0; l<N; l++) cij ^= A[i][l] & B[l][0];
                C[i][0] = cij;
        }
}

// convert x to vector, multply matrix by vector, return resulting integer

unsigned long long int apply_matrix (bool A[N][N], unsigned long long int x) {
        int i;
	bool B[N][1], C[N][1];
        for (i=0; i<N; i++) B[i][0] = !!(x & (1ull<<i));
        mult32x32x1 (A, B, C);
        unsigned long long int y = 0;
        for (i=0; i<N; i++) if (C[i][0]) y |= (1ull<<i);
        return y;
}

// read a matrix from a file

bool read_matrix (char *fname, bool A[N][N]) {
	int i, j;
	char	s[1000];

	FILE *f = fopen (fname, "r");
	if (!f) return false;
	for (i=0; i<N; i++) {
		// read a line, ignoring comments
		do {
			fgets (s, 1000, f);
			if (feof (f)) return false;
		} while (s[0] == '#');
		for (j=0; j<N; j++) A[i][j] = s[j] == '1';
	}
	fclose (f);
	return true;
}

#include "mex.h"
#include "matrix.h"
#include <algorithm>
#include <vector>
#include <cstring>
#include <bitset>
#include <cassert>
#define BITSIZE 64
using namespace std;

struct score{
  /**
   * @name score - Default Constructor
   * @return struct score
   */
  score(){ }

  /**
   * @name score - Constructor with parameters
   * @param index - Number of index 
   * @param scoreValue - Value of score Value 
   * @param offset - Number of offset 
   * @param pitchshift - Number of pitchshift 
   * @return struct score
   */
  score(int index, double scoreValue, int offset, int pitchshift):index(index),scoreValue(scoreValue),offset(offset),pitchshift(pitchshift){}

  int index;                    /**< Number of index  */
  int offset;                   /**< Number of offset  */
  int pitchshift;               /**< Number of pitchshift  */
  double scoreValue;            /**< Value of score Value  */

  /**
   * @name < - Definition of comparison
   * @param other -  other 
   * @return bool
   */
  bool operator < (struct score other) const {
    return scoreValue > other.scoreValue;
  }
};


/**
 * @name countBits64 - Count the number of 1 in the input.
 * @param x - Number of x
 * @return int
 */
int countBits64(long long x){
  x -= (x >> 1) & 0x5555555555555555;
  x = (x & 0x3333333333333333) + ((x >> 2) & 0x3333333333333333);
  x = (x + (x >> 4)) & 0x0f0f0f0f0f0f0f0f;
  return (x * 0x0101010101010101) >> 56;

}


/**
 * @name mexFunction - Connect to the MATLAB's API.
 * @param nlhs - Number of outputs
 * @param plhs -  Pointers to outputs
 * @param nrhs - Number of inputs
 * @param prhs -  Pointers to inputs
 * @return void
 */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]){
  /** Variable Declaration and Initialization
   *
   * 
   */
  size_t n_dimQ_array, n_dimR_array, numFrameShifts;
  mwSize nbits, N, M, numPitchShifts;
  const mwSize *dimQ_array, *dimRmult_array;
  mxArray *currentEntry;
  mxLogical *queryPointer, *databasePointer, *currentEntryPointer;
  double *outputPointer;

  std::vector<long long> Qblock_values[20000];
  std::vector<long long> Rblock_values[20000][10];
  int costMatrix[20000][10];
  int minScores[10], minIndexes[10];
  int curScoreEachPitch[10];
  mwSize nDBRows;
  std::vector <struct score> R;
  long long bestCost;
  int optshiftIndex;

  // Obtain the number of reference files in the database. 
  nDBRows = mxGetDimensions(prhs[1])[1];

  /** Main computation
   *
   * 
   */
  for(int i=0;i < nDBRows; i++){
    // Create a pointer to the current reference file in the database.
    currentEntry = mxGetCell(prhs[1],i);

    // Create a pointer to the tensor of reference file
    // The dimension is in the following format:
    //   [Number of bits] x [length] x [Number of pitch shifts]
    currentEntryPointer = mxGetLogicals(currentEntry);

    // Q array corresponds to the query file.
    // R array corresponds to the reference file.
    n_dimQ_array = mxGetNumberOfDimensions(prhs[0]);
    dimQ_array = mxGetDimensions(prhs[0]);
    n_dimR_array = mxGetNumberOfDimensions(currentEntry);
    dimRmult_array = mxGetDimensions(currentEntry);

    // Create a pointer to the query file.
    // The format of the query matrix is as follows:
    //   [Number of bits] x [length]
    queryPointer = mxGetLogicals(prhs[0]);

    // Obtain relevant informations:
    //   nbits = Number of bits as described above
    //   N = length of query
    //   M = length of reference file
    //   numPitchShift = number of possible pitch shifts 
    nbits = dimQ_array[0];
    N = dimQ_array[1];
    M = dimRmult_array[1];
    numPitchShifts = dimRmult_array[2];
    // Convert values in Qblock into 64-bit integers
    for(size_t j=0;j < N;j++){
      Qblock_values[j].clear();
      for(int block_bits=0;block_bits<(nbits+63)/64;block_bits++){
        long long tmpBitset = 0LL;
        for(size_t k=64*block_bits;k < 64*(block_bits+1);k++){
          tmpBitset <<= 1;
          tmpBitset |= queryPointer[j * nbits + k];
        }
        Qblock_values[j].push_back(tmpBitset);
      }
    }
    
    // Convert values in Rblock into 64-bit integers
    for(size_t j=0;j < M;j++){
      for(size_t k=0;k < numPitchShifts; k++){
        Rblock_values[j][k].clear();
        for(int block_bits=0;block_bits<(nbits+63)/64;block_bits++){
          long long tmpBitset = 0LL;
          for(size_t m=64*block_bits;m < 64*(block_bits+1);m++){
            tmpBitset <<= 1;
            tmpBitset |= currentEntryPointer[ (k * M + j) * nbits + m];
          }
          Rblock_values[j][k].push_back(tmpBitset);
        }
      }
    }
    // Calculate the number of possible frame shifts.
    numFrameShifts = M - N + 1;

    /** Calculation of score
     *
     * In this section, we iterate over all the possible frame shifts
     * and pitch shifts. For each pitchShift, we find the score in
     * every frame shifts and keep the index that gives the best
     * score.
     */
    for(int frameShift=0; frameShift < numFrameShifts; frameShift++){
      // Initialize the score for each pitch.
      memset(curScoreEachPitch, 0, sizeof curScoreEachPitch);

      // Calculate the score using XOR optimization.
      for(int block=0; block < N; block++){
        for(int pitchShift=0; pitchShift < numPitchShifts; pitchShift++){
          for(int block_bits=0;block_bits<(nbits+63)/64;block_bits++){
            long long resultedXOR = Qblock_values[block][block_bits] ^ Rblock_values[frameShift + block][pitchShift][block_bits];
            curScoreEachPitch[pitchShift] += countBits64(resultedXOR);
          }
        }
      }

      // Populate the cost matrix.
      for(int pitchShift=0; pitchShift < numPitchShifts; pitchShift++){
        costMatrix[frameShift][pitchShift] = curScoreEachPitch[pitchShift];
      }
    }

    // Calculate the optimal score for each pitch shift.
    for(int j=0;j < numPitchShifts;j++){
      minScores[j] = costMatrix[0][j];
      minIndexes[j] = 0;
      for(int k=1;k < numFrameShifts; k++){
        if( costMatrix[k][j] < minScores[j] ){
          minScores[j] = costMatrix[k][j];
          minIndexes[j] = k;
        }
      }
      if(j==0) bestCost = minScores[0], optshiftIndex = 0;
      else if(minScores[j] < bestCost) bestCost = minScores[j], optshiftIndex = j;
    }

    // Output the shifts in the correct format.
    int offset = minIndexes[optshiftIndex];
    int optshift;
    if( optshiftIndex + 1 <= (numPitchShifts + 1) / 2) optshift = optshiftIndex;
    else optshift = -(optshiftIndex+1) + (numPitchShifts+1)/2;

    // Previously, the cost is based on the difference between two matrices.
    // Now, we recalculate the score to express the similarities instead.
    // That is, the higher score indicates a high similarity.
    double scoreValue = 1.0 - (double)(bestCost)/(double)(nbits * N);

    // Append to the list keeping the score.
    R.push_back(score(i, scoreValue, offset, optshift));
  }

  // Sort the list based on the score in a decreasing order.
  std::sort(R.begin(), R.end());

  /** Output to Matlab
   *
   * NOTE: In MATLAB, the index of matrix follows the column-major ordering.
   */

  // Generate the output matrix
  plhs[0] = mxCreateDoubleMatrix((mwSize)nDBRows, (mwSize)4, mxREAL);

  outputPointer = mxGetPr(plhs[0]);
  for(size_t i=0;i < R.size();i++){
    outputPointer[i] = R[i].index+1;
    outputPointer[(int)R.size() + i] = R[i].scoreValue;
    outputPointer[2*(int)R.size() + i] = R[i].offset;
    outputPointer[3*(int)R.size() + i] = R[i].pitchshift;
  }
}

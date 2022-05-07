pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/mux1.circom";


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var s = 2**n/2; //initial size of hashed value array
    var lvl = 0; //start from level 0 and work up to n
    component hash[n][s]; //creates component for Poseidon 2 hashing with lvl and size of output
    for (var i=0; i<n; i++){
        for(var j=0; j<s; j++)
            hash[i][j] = Poseidon(2);
    }

    while(lvl<n) {  //Loop to hash first level and then contunue until lvl reaches one less than n.
        if(lvl==0){
            var k=0;
            for (var j=0; j<s; j++){
                hash[lvl][k].inputs[0] <== leaves[2*j];
                hash[lvl][k].inputs[1] <== leaves[2*j+1];
            }
        } else {
            var k=0;
            for (var j=0; j<s; j++){
                hash[lvl][k].inputs[0] <== hash[lvl-1][2*j].out;
                hash[lvl][k].inputs[1] <== hash[lvl-1][2*j+1].out;
                k++;
            }
            lvl++;
            s = s/2;
        }
        root <== hash[n-1][0].out;        //output the hash at the highest level to be the root
    }

}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component hash[n]; 
    component mux[n];

    signal out[n + 1]; //call for a output signal to be rehashed
    out[0] <== leaf; //the leaf will be the first data in out

    for (var i = 0; i < n; i++) {

        hash[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== out[i]; //set out and path elements as constants for both cases
        mux[i].c[0][1] <== path_elements[i];

        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== out[i];

        mux[i].s <== path_index[i]; //set path index as selector

        hash[i].inputs[0] <== mux[i].out[0]; //sets hashing inputs based on selector
        hash[i].inputs[1] <== mux[i].out[1];

        out[i + 1] <== hash[i].out;
    }

    root <== out[n];
}